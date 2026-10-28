import 'dart:async';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/person_profile.dart';
import '../../domain/repositories/profiles_repository.dart';
import '../datasources/profiles_remote_data_source.dart';

class ProfilesRepositoryImpl implements ProfilesRepository {
  const ProfilesRepositoryImpl(this._remote);
  final ProfilesRemoteDataSource _remote;

  @override
  Stream<Either<Failure, List<PersonProfile>>> watchProfiles({
    required String uid,
    required String userName,
  }) =>
      _remote.watch(uid, userName).transform(
            StreamTransformer<List<PersonProfile>, Either<Failure, List<PersonProfile>>>.fromHandlers(
              handleData: (data, sink) => sink.add(Right(data)),
              handleError: (e, st, sink) => sink.add(Left(ErrorMapper.toFailure(e, st))),
            ),
          );

  @override
  Future<Either<Failure, PersonProfile>> addLocalProfile({
    required String uid,
    required String name,
    required String relation,
  }) =>
      guard(() => _remote.addLocal(uid, name, relation));
}
