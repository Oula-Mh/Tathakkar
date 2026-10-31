import 'package:dartz/dartz.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/stream_utils.dart';
import '../../../profiles/domain/entities/person_profile.dart';
import '../../domain/entities/medication.dart';
import '../../domain/repositories/medications_repository.dart';
import '../datasources/medications_local_data_source.dart';
import '../datasources/medications_remote_data_source.dart';

class MedicationsRepositoryImpl implements MedicationsRepository {
  const MedicationsRepositoryImpl(this._remote, this._local);
  final MedicationsRemoteDataSource _remote;
  final MedicationsLocalDataSource _local;


// @override
// Stream<Either<Failure, List<Medication>>> watch(
//   PersonProfile profile,
// ) async* {
//   final cached = _local.read(profile.key);
//   if (cached != null) {
//     yield Right<Failure, List<Medication>>(cached);
//   }

//   final live = _remote.watch(profile).map((models) {
//     _local.write(profile.key, models);
//     return models.map<Medication>((model) => model).toList();
//   });

//   yield* eitherStream<List<Medication>>(live);
// }
@override
Stream<Either<Failure, List<Medication>>> watch(
  PersonProfile profile,
) async* {
  final cached = _local.read(profile.key);

  if (cached != null) {
    yield Right<Failure, List<Medication>>(cached);
  }

  final live = _remote.watch(profile).map<List<Medication>>((models) {
    _local.write(profile.key, models);
    return models;
  });

  yield* eitherStream<List<Medication>>(live);
}


  @override
  Future<Either<Failure, Medication>> getById(PersonProfile profile, String id) =>
      guard<Medication>(() async {
        try {
          return await _remote.getById(profile, id);
        } catch (_) {
          // Offline fallback: the cached list may contain it.
          final hit = _local.read(profile.key)?.where((m) => m.id == id);
          if (hit != null && hit.isNotEmpty) return hit.first;
          rethrow;
        }
      });

  @override
  Future<Either<Failure, Medication>> save(PersonProfile profile, Medication medication) =>
      guard(() => _remote.save(profile, medication));

  @override
  Future<Either<Failure, Unit>> delete(PersonProfile profile, String id) =>
      guard(() async {
        await _remote.delete(profile, id);
        return unit;
      });
}
