import 'package:dartz/dartz.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/stream_utils.dart';
import '../../../medications/domain/entities/medication.dart';
import '../../../profiles/domain/entities/person_profile.dart';
import '../../domain/entities/dose_log.dart';
import '../../domain/repositories/doses_repository.dart';
import '../datasources/doses_remote_data_source.dart';

class DosesRepositoryImpl implements DosesRepository {
  const DosesRepositoryImpl(this._remote);
  final DosesRemoteDataSource _remote;

  @override
  Stream<Either<Failure, List<DoseLog>>> watchRange(
          PersonProfile profile, DateTime from, DateTime to) =>
      eitherStream(_remote.watchRange(profile, from, to));

  @override
  Future<Either<Failure, Unit>> confirmDose(
          PersonProfile profile, Medication medication, DateTime scheduledAt) =>
      guard(() async {
        await _remote.confirm(profile, medication, scheduledAt);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> ensurePending(
          PersonProfile profile, Medication medication, List<DateTime> slots) =>
      guard(() async {
        await _remote.ensurePending(profile, medication, slots);
        return unit;
      });
}
