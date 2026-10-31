import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/person_profile.dart';

abstract interface class ProfilesRepository {
  /// Self + local profiles + linked elders, with live care-link status.
  Stream<Either<Failure, List<PersonProfile>>> watchProfiles({
    required String uid,
    required String userName,
  });

  Future<Either<Failure, Unit>> ensureSelfProfile({
    required String uid,
    required String name,
    required String email,
  });

  Future<Either<Failure, PersonProfile>> addLocalProfile({
    required String uid,
    required String name,
    required String relation,
  });
}
