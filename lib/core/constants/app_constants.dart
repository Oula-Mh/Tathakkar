/// Hive boxes, Firestore collections and business rules in one place.
abstract final class HiveBoxes {
  static const settings = 'settings_box';
  static const medicationsCache = 'medications_cache_box';
  static const flags = 'flags_box';
}

abstract final class FirestorePaths {
  static const users = 'users';
  static const profiles = 'profiles';
  static const medications = 'medications';
  static const doseLogs = 'doseLogs';
  static const notifications = 'notifications';
  static const linkTokens = 'linkTokens';
  static const careLinks = 'careLinks';
  static const selfProfileId = 'self';
}

abstract final class BusinessRules {
  /// Minutes after the original dose time before the caregiver is notified.
  static const missedDoseGraceMinutes = 30;
  static const linkTokenValidMinutes = 10;
  static const snoozeOptions = [5, 10, 15];
  static const defaultSnoozeMinutes = 10;
  static const maxSnoozes = 2; // snooze #1 -> re-reminder, snooze #2 -> final
  static const defaultAlertThreshold = 5;
  static const minPasswordLength = 8;
}

abstract final class Assets {
  /// Relative to assets/ (audioplayers AssetSource).
  static const alarmSound = 'sounds/mixkit-classic-alarm-995.wav';
}
