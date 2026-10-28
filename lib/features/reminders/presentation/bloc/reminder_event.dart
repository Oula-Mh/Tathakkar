part of 'reminder_bloc.dart';

sealed class ReminderEvent extends Equatable {
  const ReminderEvent();
  @override
  List<Object?> get props => [];
}

class ReminderOpened extends ReminderEvent {
  const ReminderOpened(this.payload, {required this.languageCode, this.profileName = ''});
  final ReminderPayload payload;
  final String languageCode;
  final String profileName;
  @override
  List<Object?> get props => [payload, languageCode, profileName];
}

class ReminderTakenPressed extends ReminderEvent {
  const ReminderTakenPressed();
}

class ReminderSnoozePressed extends ReminderEvent {
  const ReminderSnoozePressed();
}
