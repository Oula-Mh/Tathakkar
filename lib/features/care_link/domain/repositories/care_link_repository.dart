import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/care_link.dart';

abstract interface class CareLinkRepository {
  /// The caregiver linked to [uid] (as elder), or null.
  Stream<Either<Failure, CareLink?>> watchMyCaregiver(String uid);

  Future<Either<Failure, LinkToken>> createToken({required String uid, required String name});

  /// Caregiver side: consume a scanned token (single use, time limited).
  Future<Either<Failure, CareLink>> redeem({
    required String token,
    required String caregiverUid,
    required String caregiverName,
  });

  Future<Either<Failure, Unit>> unlink(String elderUid);
}
