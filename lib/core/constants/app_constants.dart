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

  /// How long the LAST ring stays active before the dose becomes "unconfirmed".
  static const finalRingMinutes = 5;

  /// A dose stays "due" from its exact time until the whole reminder sequence
  /// is over: first ring + every snooze + the last ring. Only then: unconfirmed.
  static int reminderWindowMinutes(int snoozeMinutes) =>
      snoozeMinutes * maxSnoozes + finalRingMinutes;
  static const maxSnoozes = 2; // snooze #1 -> re-reminder, snooze #2 -> final
  static const defaultAlertThreshold = 5;
  static const minPasswordLength = 8;
}

abstract final class Assets {
  /// In-app alarm (audioplayers AssetSource, relative to assets/). First hit wins.
  static const alarmSounds = ['sounds/alarm.wav', 'sounds/alarm.mp3', 'sounds/alarm.ogg'];
}

/// Notification channels (ids are versioned: Android freezes a channel's
/// sound/importance after creation, so changing them requires a new id).
abstract final class NotificationIds {
  static const doseAlarmChannel = 'dose_alarm_v3';
  static const doseSilentChannel = 'dose_silent_v3';
  static const stockChannel = 'stock_alerts_v2';
  static const caregiverChannel = 'caregiver_alerts_v2';

  static const actionTaken = 'taken';
  static const actionSnooze = 'snooze';

  /// Old channel ids from earlier builds: deleted on start so the phone's
  /// settings list doesn't keep dead channels with the wrong sound.
  static const legacyChannels = ['doses_sound', 'doses_silent', 'dose_alarm_v2', 'dose_silent_v2'];

  /// true  -> the app's own tone: android/app/src/main/res/raw/<customSoundResource>.wav
  /// false -> the phone's alarm ringtone (needs no file)
  // static const useCustomAlarmSound = true;
  static const customSoundResource = 'alarm'; // file name WITHOUT extension, lowercase

  /// The phone's own alarm ringtone (always exists, no asset needed).
  static const alarmSoundUri = 'content://set tings/system/alarm_alert';
  static const alarmTimeoutMs = 20 * 60 * 1000;
  static const testNotificationId = 777001;
}

abstract final class HiveKeys {
  static const lastUid = 'last_uid';
  static const secureKeyName = 'hive_aes_key_v1';
}
