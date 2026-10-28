import 'package:equatable/equatable.dart';

import '../../../medications/domain/entities/medication.dart';

/// What the UI shows for a dose slot.
enum DoseDisplayStatus { upcoming, due, taken, unconfirmed }

class ScheduledDose extends Equatable {
  const ScheduledDose({
    required this.medication,
    required this.scheduledAt,
    required this.status,
  });

  final Medication medication;
  final DateTime scheduledAt;
  final DoseDisplayStatus status;

  bool get canConfirm =>
      status == DoseDisplayStatus.due ||
      status == DoseDisplayStatus.unconfirmed ||
      status == DoseDisplayStatus.upcoming;

  @override
  List<Object?> get props => [medication, scheduledAt, status];
}
