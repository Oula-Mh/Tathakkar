import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

abstract interface class AuthRepository {
  /// Emits the current user, or null when signed out.
  Stream<UserEntity?> watchUser();

  Future<Either<Failure, UserEntity>> signIn({required String email, required String password});

  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String email,
    required String password,
  });

  Future<Either<Failure, Unit>> sendPasswordReset(String email);
  Future<Either<Failure, Unit>> signOut();
}
