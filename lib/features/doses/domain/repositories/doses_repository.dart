import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../medications/domain/entities/medication.dart';
import '../../../profiles/domain/entities/person_profile.dart';
import '../entities/dose_log.dart';

abstract interface class DosesRepository {
  Stream<Either<Failure, List<DoseLog>>> watchRange(
    PersonProfile profile,
    DateTime from,
    DateTime to,
  );

  /// Marks the dose as taken and deducts stock, atomically and only once.
  Future<Either<Failure, Unit>> confirmDose(
    PersonProfile profile,
    Medication medication,
    DateTime scheduledAt,
  );

  /// Creates "pending" logs (server uses them to detect missed doses).
  Future<Either<Failure, Unit>> ensurePending(
    PersonProfile profile,
    Medication medication,
    List<DateTime> slots,
  );
}
