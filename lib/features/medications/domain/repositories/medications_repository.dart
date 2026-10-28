import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../profiles/domain/entities/person_profile.dart';
import '../entities/medication.dart';

abstract interface class MedicationsRepository {
  /// Emits cached data first (offline), then live updates.
  Stream<Either<Failure, List<Medication>>> watch(PersonProfile profile);

  Future<Either<Failure, Medication>> getById(PersonProfile profile, String id);

  /// Creates (empty id) or updates a medication.
  Future<Either<Failure, Medication>> save(PersonProfile profile, Medication medication);

  Future<Either<Failure, Unit>> delete(PersonProfile profile, String id);
}
