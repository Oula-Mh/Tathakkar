import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/person_profile.dart';
import '../repositories/profiles_repository.dart';

class WatchProfiles {
  const WatchProfiles(this._repo);
  final ProfilesRepository _repo;
  Stream<Either<Failure, List<PersonProfile>>> call(String uid, String userName) =>
      _repo.watchProfiles(uid: uid, userName: userName);
}

class AddLocalProfileParams extends Equatable {
  const AddLocalProfileParams({required this.uid, required this.name, required this.relation});
  final String uid;
  final String name;
  final String relation;
  @override
  List<Object?> get props => [uid, name, relation];
}

class AddLocalProfile implements UseCase<PersonProfile, AddLocalProfileParams> {
  const AddLocalProfile(this._repo);
  final ProfilesRepository _repo;
  @override
  Future<Either<Failure, PersonProfile>> call(AddLocalProfileParams p) =>
      _repo.addLocalProfile(uid: p.uid, name: p.name.trim(), relation: p.relation);
}

class EnsureSelfProfileParams extends Equatable {
  const EnsureSelfProfileParams({required this.uid, required this.name, required this.email});
  final String uid;
  final String name;
  final String email;
  @override
  List<Object?> get props => [uid, name, email];
}

class EnsureSelfProfile implements UseCase<Unit, EnsureSelfProfileParams> {
  const EnsureSelfProfile(this._repo);
  final ProfilesRepository _repo;
  @override
  Future<Either<Failure, Unit>> call(EnsureSelfProfileParams p) =>
      _repo.ensureSelfProfile(uid: p.uid, name: p.name, email: p.email);
}
