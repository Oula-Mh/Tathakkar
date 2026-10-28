import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';

/// App-wide preferences, also the defaults for new medications' reminders.
class AppSettings extends Equatable {
  const AppSettings({
    this.languageCode = 'ar',
    this.darkMode = false,
    this.onboardingSeen = false,
    this.notificationsPrompted = false,
    this.remindersEnabled = true,
    this.soundEnabled = true,
    this.speakEnabled = true,
    this.showImage = true,
    this.fullScreen = true,
    this.snoozeMinutes = BusinessRules.defaultSnoozeMinutes,
  });

  final String languageCode;
  final bool darkMode;
  final bool onboardingSeen;
  final bool notificationsPrompted;
  final bool remindersEnabled;
  final bool soundEnabled;
  final bool speakEnabled;
  final bool showImage;
  final bool fullScreen;
  final int snoozeMinutes;

  AppSettings copyWith({
    String? languageCode,
    bool? darkMode,
    bool? onboardingSeen,
    bool? notificationsPrompted,
    bool? remindersEnabled,
    bool? soundEnabled,
    bool? speakEnabled,
    bool? showImage,
    bool? fullScreen,
    int? snoozeMinutes,
  }) =>
      AppSettings(
        languageCode: languageCode ?? this.languageCode,
        darkMode: darkMode ?? this.darkMode,
        onboardingSeen: onboardingSeen ?? this.onboardingSeen,
        notificationsPrompted: notificationsPrompted ?? this.notificationsPrompted,
        remindersEnabled: remindersEnabled ?? this.remindersEnabled,
        soundEnabled: soundEnabled ?? this.soundEnabled,
        speakEnabled: speakEnabled ?? this.speakEnabled,
        showImage: showImage ?? this.showImage,
        fullScreen: fullScreen ?? this.fullScreen,
        snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      );

  @override
  List<Object?> get props => [
        languageCode,
        darkMode,
        onboardingSeen,
        notificationsPrompted,
        remindersEnabled,
        soundEnabled,
        speakEnabled,
        showImage,
        fullScreen,
        snoozeMinutes,
      ];
}
