import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../profiles/domain/entities/person_profile.dart';
import '../entities/medication.dart';
import '../repositories/medications_repository.dart';

class WatchMedications {
  const WatchMedications(this._repo);
  final MedicationsRepository _repo;
  Stream<Either<Failure, List<Medication>>> call(PersonProfile p) => _repo.watch(p);
}

class MedicationRef extends Equatable {
  const MedicationRef(this.profile, this.medicationId);
  final PersonProfile profile;
  final String medicationId;
  @override
  List<Object?> get props => [profile, medicationId];
}

class GetMedication implements UseCase<Medication, MedicationRef> {
  const GetMedication(this._repo);
  final MedicationsRepository _repo;
  @override
  Future<Either<Failure, Medication>> call(MedicationRef r) =>
      _repo.getById(r.profile, r.medicationId);
}

class SaveMedicationParams extends Equatable {
  const SaveMedicationParams(this.profile, this.medication);
  final PersonProfile profile;
  final Medication medication;
  @override
  List<Object?> get props => [profile, medication];
}

/// Enforces the permission rule: elders under care cannot edit medications.
class SaveMedication implements UseCase<Medication, SaveMedicationParams> {
  const SaveMedication(this._repo);
  final MedicationsRepository _repo;
  @override
  Future<Either<Failure, Medication>> call(SaveMedicationParams p) async {
    if (!p.profile.canManageMedications) return const Left(PermissionFailure());
    return _repo.save(p.profile, p.medication);
  }
}

class DeleteMedication implements UseCase<Unit, MedicationRef> {
  const DeleteMedication(this._repo);
  final MedicationsRepository _repo;
  @override
  Future<Either<Failure, Unit>> call(MedicationRef r) async {
    if (!r.profile.canManageMedications) return const Left(PermissionFailure());
    return _repo.delete(r.profile, r.medicationId);
  }
}

class UpdateStockParams extends Equatable {
  const UpdateStockParams({
    required this.profile,
    required this.medication,
    required this.remaining,
    required this.packSize,
    required this.alertThreshold,
  });
  final PersonProfile profile;
  final Medication medication;
  final int remaining;
  final int packSize;
  final int alertThreshold;
  @override
  List<Object?> get props => [profile, medication, remaining, packSize, alertThreshold];
}

class UpdateStock implements UseCase<Medication, UpdateStockParams> {
  const UpdateStock(this._save);
  final SaveMedication _save;
  @override
  Future<Either<Failure, Medication>> call(UpdateStockParams p) => _save(SaveMedicationParams(
        p.profile,
        p.medication.copyWith(
          remaining: p.remaining,
          packSize: p.packSize,
          alertThreshold: p.alertThreshold,
        ),
      ));
}
