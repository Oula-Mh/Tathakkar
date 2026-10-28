import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/stream_utils.dart';
import '../domain/entities/inbox_item.dart';
import '../domain/repositories/inbox_repository.dart';

class InboxRepositoryImpl implements InboxRepository {
  InboxRepositoryImpl(this._db);
  final FirebaseFirestore _db;

  DateTime? _ms(dynamic v) => v is num ? DateTime.fromMillisecondsSinceEpoch(v.toInt()) : null;

  @override
  Stream<Either<Failure, List<InboxItem>>> watch(String uid) => eitherStream(_db
      .collection(FirestorePaths.users)
      .doc(uid)
      .collection(FirestorePaths.notifications)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs.map((d) {
            final m = d.data();
            return InboxItem(
              id: d.id,
              type: switch (m['type']) {
                'missed_dose' => InboxType.missedDose,
                'out_of_stock' => InboxType.outOfStock,
                _ => InboxType.lowStock,
              },
              personName: m['personName'] as String? ?? '',
              medicationName: m['medicationName'] as String? ?? '',
              createdAt: _ms(m['createdAt']) ?? DateTime.now(),
              scheduledAt: _ms(m['scheduledAt']),
              remaining: (m['remaining'] as num?)?.toInt(),
              threshold: (m['threshold'] as num?)?.toInt(),
              amount: (m['amount'] as num?)?.toInt(),
            );
          }).toList()));
}
