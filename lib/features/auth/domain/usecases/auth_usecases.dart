import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class Credentials extends Equatable {
  const Credentials(this.email, this.password);
  final String email;
  final String password;
  @override
  List<Object?> get props => [email, password];
}

class RegisterParams extends Equatable {
  const RegisterParams({required this.name, required this.email, required this.password});
  final String name;
  final String email;
  final String password;
  @override
  List<Object?> get props => [name, email, password];
}

class SignIn implements UseCase<UserEntity, Credentials> {
  const SignIn(this._repo);
  final AuthRepository _repo;
  @override
  Future<Either<Failure, UserEntity>> call(Credentials p) =>
      _repo.signIn(email: p.email.trim(), password: p.password);
}

class RegisterUser implements UseCase<UserEntity, RegisterParams> {
  const RegisterUser(this._repo);
  final AuthRepository _repo;
  @override
  Future<Either<Failure, UserEntity>> call(RegisterParams p) =>
      _repo.register(name: p.name.trim(), email: p.email.trim(), password: p.password);
}

class SendPasswordReset implements UseCase<Unit, String> {
  const SendPasswordReset(this._repo);
  final AuthRepository _repo;
  @override
  Future<Either<Failure, Unit>> call(String email) => _repo.sendPasswordReset(email.trim());
}

class SignOut implements UseCase<Unit, NoParams> {
  const SignOut(this._repo);
  final AuthRepository _repo;
  @override
  Future<Either<Failure, Unit>> call(NoParams _) => _repo.signOut();
}

class WatchAuthUser {
  const WatchAuthUser(this._repo);
  final AuthRepository _repo;
  Stream<UserEntity?> call() => _repo.watchUser();
}
