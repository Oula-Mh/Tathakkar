part of 'settings_bloc.dart';

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object?> get props => [];
}

class LanguageChanged extends SettingsEvent {
  const LanguageChanged(this.code);
  final String code;
  @override
  List<Object?> get props => [code];
}

class DarkModeChanged extends SettingsEvent {
  const DarkModeChanged(this.enabled);
  final bool enabled;
  @override
  List<Object?> get props => [enabled];
}

class OnboardingCompleted extends SettingsEvent {
  const OnboardingCompleted();
}

class NotificationsPrompted extends SettingsEvent {
  const NotificationsPrompted();
}

/// Any reminder preference (sound, speak, image, fullscreen, snooze...).
class ReminderPrefsChanged extends SettingsEvent {
  const ReminderPrefsChanged({
    this.remindersEnabled,
    this.soundEnabled,
    this.speakEnabled,
    this.showImage,
    this.fullScreen,
    this.snoozeMinutes,
  });
  final bool? remindersEnabled;
  final bool? soundEnabled;
  final bool? speakEnabled;
  final bool? showImage;
  final bool? fullScreen;
  final int? snoozeMinutes;
  @override
  List<Object?> get props =>
      [remindersEnabled, soundEnabled, speakEnabled, showImage, fullScreen, snoozeMinutes];
}
