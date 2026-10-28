import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../profiles/domain/entities/person_profile.dart';
import '../../domain/entities/medication.dart';
import '../models/medication_model.dart';

class MedicationsRemoteDataSource {
  MedicationsRemoteDataSource(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(PersonProfile p) => _db
      .collection(FirestorePaths.users)
      .doc(p.ownerUid)
      .collection(FirestorePaths.profiles)
      .doc(p.profileId)
      .collection(FirestorePaths.medications);

  Stream<List<MedicationModel>> watch(PersonProfile p) => _col(p).snapshots().map((snap) {
        final list = snap.docs.map((d) => MedicationModel.fromMap(d.id, d.data())).toList();
        list.sort((a, b) => a.name.compareTo(b.name));
        return list;
      });

  Future<MedicationModel> getById(PersonProfile p, String id) async {
    final doc = await _col(p).doc(id).get();
    final data = doc.data();
    if (!doc.exists || data == null) throw const NotFoundException();
    return MedicationModel.fromMap(doc.id, data);
  }

  Future<MedicationModel> save(PersonProfile p, Medication m) async {
    final model = MedicationModel.fromEntity(m);
    final ref = m.isNew ? _col(p).doc() : _col(p).doc(m.id);
    // Don't await server ack when offline: Firestore queues the write locally.
    await ref.set(model.toMap(), SetOptions(merge: true)).timeout(
          const Duration(seconds: 8),
          onTimeout: () {},
        );
    return MedicationModel.fromEntity(m.copyWith(id: ref.id));
  }

  Future<void> delete(PersonProfile p, String id) =>
      _col(p).doc(id).delete().timeout(const Duration(seconds: 8), onTimeout: () {});
}
