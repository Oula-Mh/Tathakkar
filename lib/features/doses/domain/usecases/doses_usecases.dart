import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/formatters.dart';
import '../../../medications/domain/entities/medication.dart';
import '../../../profiles/domain/entities/person_profile.dart';
import '../entities/dose_log.dart';
import '../entities/scheduled_dose.dart';
import '../repositories/doses_repository.dart';

class WatchDoseLogs {
  const WatchDoseLogs(this._repo);
  final DosesRepository _repo;
  Stream<Either<Failure, List<DoseLog>>> call(PersonProfile p, DateTime from, DateTime to) =>
      _repo.watchRange(p, from, to);
}

class ConfirmDoseParams extends Equatable {
  const ConfirmDoseParams(this.profile, this.medication, this.scheduledAt);
  final PersonProfile profile;
  final Medication medication;
  final DateTime scheduledAt;
  @override
  List<Object?> get props => [profile, medication, scheduledAt];
}

class ConfirmDose implements UseCase<Unit, ConfirmDoseParams> {
  const ConfirmDose(this._repo);
  final DosesRepository _repo;
  @override
  Future<Either<Failure, Unit>> call(ConfirmDoseParams p) =>
      _repo.confirmDose(p.profile, p.medication, p.scheduledAt);
}

class EnsurePendingParams extends Equatable {
  const EnsurePendingParams(this.profile, this.medication, this.slots);
  final PersonProfile profile;
  final Medication medication;
  final List<DateTime> slots;
  @override
  List<Object?> get props => [profile, medication, slots];
}

class EnsurePendingDoses implements UseCase<Unit, EnsurePendingParams> {
  const EnsurePendingDoses(this._repo);
  final DosesRepository _repo;
  @override
  Future<Either<Failure, Unit>> call(EnsurePendingParams p) =>
      _repo.ensurePending(p.profile, p.medication, p.slots);
}

/// Pure logic: today's slots for all active medications + their status.
class BuildDaySchedule {
  const BuildDaySchedule();

  List<ScheduledDose> call({
    required List<Medication> medications,
    required List<DoseLog> logs,
    required DateTime day,
    required DateTime now,
  }) {
    final byId = {for (final l in logs) l.id: l};
    final result = <ScheduledDose>[];
    for (final med in medications) {
      if (!med.isActiveOn(day)) continue;
      for (final minutes in med.times) {
        final at = minutes.onDay(day);
        final log = byId[doseLogId(med.id, at)];
        final status = log?.status == DoseStatus.taken
            ? DoseDisplayStatus.taken
            : _derive(at, now, log?.status == DoseStatus.missed);
        result.add(ScheduledDose(medication: med, scheduledAt: at, status: status));
      }
    }
    result.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return result;
  }

  DoseDisplayStatus _derive(DateTime at, DateTime now, bool markedMissed) {
    final grace = at.add(const Duration(minutes: BusinessRules.missedDoseGraceMinutes));
    if (markedMissed || now.isAfter(grace)) return DoseDisplayStatus.unconfirmed;
    if (!now.isBefore(at)) return DoseDisplayStatus.due;
    return DoseDisplayStatus.upcoming;
  }

  /// The next dose that still needs action (due now, or soonest upcoming).
  ScheduledDose? next(List<ScheduledDose> day) {
    final open = day.where((d) =>
        d.status == DoseDisplayStatus.due || d.status == DoseDisplayStatus.upcoming);
    return open.isEmpty ? null : open.first;
  }
}
