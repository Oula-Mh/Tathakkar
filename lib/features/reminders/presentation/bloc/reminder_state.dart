part of 'reminder_bloc.dart';

enum ReminderStatus { loading, ready, working, taken, snoozed, failure }

enum ReminderPhase { due, again, finalCall }

class ReminderState extends Equatable {
  const ReminderState({
    this.status = ReminderStatus.loading,
    this.medication,
    this.payload,
    this.failureKey,
    this.actionFailureKey,
  });

  final ReminderStatus status;
  final Medication? medication;
  final ReminderPayload? payload;
  final String? failureKey;
  final String? actionFailureKey;

  ReminderPhase get phase {
    final n = payload?.snoozeCount ?? 0;
    if (n >= BusinessRules.maxSnoozes) return ReminderPhase.finalCall;
    return n == 0 ? ReminderPhase.due : ReminderPhase.again;
  }

  /// The final reminder cannot be snoozed again.
  bool get canSnooze => phase != ReminderPhase.finalCall;

  DateTime? get scheduledAt => payload?.originalTime(DateTime.now());

  /// True once the 30-minute grace period has passed.
  bool get isUnconfirmed =>
      scheduledAt != null &&
      DateTime.now()
          .isAfter(scheduledAt!.add(const Duration(minutes: BusinessRules.missedDoseGraceMinutes)));

  ReminderState copyWith({
    ReminderStatus? status,
    Medication? medication,
    ReminderPayload? payload,
    String? failureKey,
    String? actionFailureKey,
  }) =>
      ReminderState(
        status: status ?? this.status,
        medication: medication ?? this.medication,
        payload: payload ?? this.payload,
        failureKey: failureKey,
        actionFailureKey: actionFailureKey,
      );

  @override
  List<Object?> get props => [status, medication, payload, failureKey, actionFailureKey];
}
