part of 'reminder_health_bloc.dart';

sealed class ReminderHealthEvent extends Equatable {
  const ReminderHealthEvent();
  @override
  List<Object?> get props => [];
}

class HealthRefreshed extends ReminderHealthEvent {
  const HealthRefreshed();
}

class HealthFixRequested extends ReminderHealthEvent {
  const HealthFixRequested(this.item);
  final HealthItem item;
  @override
  List<Object?> get props => [item];
}

class HealthTestScheduled extends ReminderHealthEvent {
  const HealthTestScheduled(this.languageCode, {this.seconds = 10});
  final String languageCode;
  final int seconds;
  @override
  List<Object?> get props => [languageCode, seconds];
}

class HealthTestShownNow extends ReminderHealthEvent {
  const HealthTestShownNow(this.languageCode);
  final String languageCode;
  @override
  List<Object?> get props => [languageCode];
}
