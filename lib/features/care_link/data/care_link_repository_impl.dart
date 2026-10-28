import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/stream_utils.dart';
import '../domain/entities/care_link.dart';
import '../domain/repositories/care_link_repository.dart';

class CareLinkRepositoryImpl implements CareLinkRepository {
  CareLinkRepositoryImpl(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _links => _db.collection(FirestorePaths.careLinks);
  CollectionReference<Map<String, dynamic>> get _tokens => _db.collection(FirestorePaths.linkTokens);

  static String _randomToken() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';
    final r = Random.secure();
    return List.generate(32, (_) => chars[r.nextInt(chars.length)]).join();
  }

  CareLink _fromMap(String id, Map<String, dynamic> m) => CareLink(
        elderUid: m['elderUid'] as String? ?? id,
        elderName: m['elderName'] as String? ?? '',
        caregiverUid: m['caregiverUid'] as String? ?? '',
        caregiverName: m['caregiverName'] as String? ?? '',
      );

  @override
  Stream<Either<Failure, CareLink?>> watchMyCaregiver(String uid) => eitherStream(
        _links.doc(uid).snapshots().map((d) => d.exists ? _fromMap(d.id, d.data()!) : null),
      );

  @override
  Future<Either<Failure, LinkToken>> createToken({required String uid, required String name}) =>
      guard(() async {
        final token = _randomToken();
        final expires =
            DateTime.now().add(const Duration(minutes: BusinessRules.linkTokenValidMinutes));
        await _tokens.doc(token).set({
          'ownerUid': uid,
          'ownerName': name,
          'expiresAt': expires.millisecondsSinceEpoch,
          'used': false,
        });
        return LinkToken(token: token, expiresAt: expires);
      });

  @override
  Future<Either<Failure, CareLink>> redeem({
    required String token,
    required String caregiverUid,
    required String caregiverName,
  }) =>
      guard(() => _db.runTransaction<CareLink>((tx) async {
            final tokenRef = _tokens.doc(token);
            final snap = await tx.get(tokenRef);
            final data = snap.data();
            if (!snap.exists || data == null || data['used'] == true) {
              throw const LinkException('err_link_invalid');
            }
            if (DateTime.now().millisecondsSinceEpoch > (data['expiresAt'] as num).toInt()) {
              throw const LinkException('err_link_expired');
            }
            final elderUid = data['ownerUid'] as String;
            if (elderUid == caregiverUid) throw const LinkException('err_link_self');

            final linkRef = _links.doc(elderUid);
            if ((await tx.get(linkRef)).exists) {
              throw const LinkException('err_link_already_managed');
            }
            final link = CareLink(
              elderUid: elderUid,
              elderName: data['ownerName'] as String? ?? '',
              caregiverUid: caregiverUid,
              caregiverName: caregiverName,
            );
            tx.update(tokenRef, {'used': true, 'usedBy': caregiverUid});
            tx.set(linkRef, {
              'elderUid': link.elderUid,
              'elderName': link.elderName,
              'caregiverUid': caregiverUid,
              'caregiverName': caregiverName,
              'token': token,
              'createdAt': FieldValue.serverTimestamp(),
            });
            return link;
          }));

  @override
  Future<Either<Failure, Unit>> unlink(String elderUid) => guard(() async {
        // Data (medications, doses) stays on the elder's account untouched.
        await _links.doc(elderUid).delete();
        return unit;
      });
}
