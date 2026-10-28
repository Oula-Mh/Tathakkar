import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../medications/domain/entities/medication.dart';
import '../../../profiles/domain/entities/person_profile.dart';
import '../../domain/entities/dose_log.dart';

class DosesRemoteDataSource {
  DosesRemoteDataSource(this._db);
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _profileRef(PersonProfile p) => _db
      .collection(FirestorePaths.users)
      .doc(p.ownerUid)
      .collection(FirestorePaths.profiles)
      .doc(p.profileId);

  CollectionReference<Map<String, dynamic>> _logs(PersonProfile p) =>
      _profileRef(p).collection(FirestorePaths.doseLogs);

  Stream<List<DoseLog>> watchRange(PersonProfile p, DateTime from, DateTime to) => _logs(p)
      .where('scheduledAt', isGreaterThanOrEqualTo: from.millisecondsSinceEpoch)
      .where('scheduledAt', isLessThan: to.millisecondsSinceEpoch)
      .snapshots()
      .map((s) => s.docs.map((d) => _fromDoc(d.id, d.data())).toList());

  DoseLog _fromDoc(String id, Map<String, dynamic> m) => DoseLog(
        id: id,
        medicationId: m['medicationId'] as String? ?? '',
        medicationName: m['medicationName'] as String? ?? '',
        scheduledAt: DateTime.fromMillisecondsSinceEpoch((m['scheduledAt'] as num).toInt()),
        status: DoseStatus.values.firstWhere(
          (e) => e.name == m['status'],
          orElse: () => DoseStatus.pending,
        ),
        actedAt: m['actedAt'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch((m['actedAt'] as num).toInt()),
        amount: (m['amount'] as num?)?.toInt() ?? 1,
      );

  /// Online: transaction (log=taken + stock deducted once, idempotent).
  /// Offline/slow: queued batch write so seniors can confirm without internet.
  Future<void> confirm(PersonProfile p, Medication med, DateTime scheduledAt) async {
    try {
      await _confirmTransaction(p, med, scheduledAt).timeout(const Duration(seconds: 6));
    } on TimeoutException {
      await _confirmQueued(p, med, scheduledAt);
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
        await _confirmQueued(p, med, scheduledAt);
      } else {
        rethrow;
      }
    }
  }

  Future<void> _confirmTransaction(PersonProfile p, Medication med, DateTime scheduledAt) {
    final logRef = _logs(p).doc(doseLogId(med.id, scheduledAt));
    final medRef = _profileRef(p).collection(FirestorePaths.medications).doc(med.id);

    return _db.runTransaction((tx) async {
      final logSnap = await tx.get(logRef);
      if (logSnap.data()?['status'] == DoseStatus.taken.name) return; // idempotent

      final medSnap = await tx.get(medRef);
      final remaining = (medSnap.data()?['remaining'] as num?)?.toInt() ?? med.remaining;
      final next = (remaining - med.dosePerTake).clamp(0, 1 << 30);

      tx.set(logRef, _takenData(med, scheduledAt), SetOptions(merge: true));
      if (medSnap.exists) tx.update(medRef, {'remaining': next});
    });
  }

  Future<void> _confirmQueued(PersonProfile p, Medication med, DateTime scheduledAt) async {
    final logRef = _logs(p).doc(doseLogId(med.id, scheduledAt));
    final medRef = _profileRef(p).collection(FirestorePaths.medications).doc(med.id);
    try {
      final cached = await logRef.get(const GetOptions(source: Source.cache));
      if (cached.data()?['status'] == DoseStatus.taken.name) return;
    } catch (_) {} // not cached yet: continue

    final batch = _db.batch()
      ..set(logRef, _takenData(med, scheduledAt), SetOptions(merge: true))
      ..update(medRef, {'remaining': FieldValue.increment(-med.dosePerTake)});
    // Offline the commit only completes on reconnect; the write is queued locally.
    await batch.commit().timeout(const Duration(seconds: 2), onTimeout: () {});
  }

  Map<String, dynamic> _takenData(Medication med, DateTime scheduledAt) => {
        'medicationId': med.id,
        'medicationName': med.name,
        'scheduledAt': scheduledAt.millisecondsSinceEpoch,
        'status': DoseStatus.taken.name,
        'actedAt': DateTime.now().millisecondsSinceEpoch,
        'amount': med.dosePerTake,
        'notifiedMissed': true,
      };

  Future<void> ensurePending(PersonProfile p, Medication med, List<DateTime> slots) async {
    final batch = _db.batch();
    for (final at in slots) {
      final ref = _logs(p).doc(doseLogId(med.id, at));
      final snap = await ref.get();
      if (snap.exists) continue;
      batch.set(ref, {
        'medicationId': med.id,
        'medicationName': med.name,
        'scheduledAt': at.millisecondsSinceEpoch,
        'status': DoseStatus.pending.name,
        'amount': med.dosePerTake,
        'notifiedMissed': false,
      });
    }
    await batch.commit();
  }
}
