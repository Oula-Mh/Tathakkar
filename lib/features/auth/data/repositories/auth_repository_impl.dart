import 'package:dartz/dartz.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote);
  final AuthRemoteDataSource _remote;

  @override
  Stream<UserEntity?> watchUser() => _remote.watchUser();

  @override
  Future<Either<Failure, UserEntity>> signIn({required String email, required String password}) =>
      guard(() => _remote.signIn(email, password));

  @override
  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String email,
    required String password,
  }) =>
      guard(() => _remote.register(name, email, password));

  @override
  Future<Either<Failure, Unit>> sendPasswordReset(String email) =>
      guard(() async {
        await _remote.sendPasswordReset(email);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> signOut() => guard(() async {
        await _remote.signOut();
        return unit;
      });
}
