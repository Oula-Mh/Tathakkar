import '../../../medications/domain/entities/medication.dart';
import '../../../profiles/domain/entities/person_profile.dart';
import '../entities/reminder_payload.dart';

/// Abstraction over the OS scheduler so domain/presentation never touch plugins.
abstract interface class ReminderScheduler {
  /// Replaces ALL scheduled daily reminders with the given medications.
  Future<void> syncAll(
    Map<PersonProfile, List<Medication>> byProfile, {
    required String languageCode,
    required bool enabled,
  });

  /// One-off re-reminder after the user taps "remind me later".
  Future<void> snooze(
    ReminderPayload payload,
    Medication medication, {
    required String profileName,
    required String languageCode,
  });

  /// Stops the ringing notification that opened the screen, keeping tomorrow's alarm.
  Future<void> silence(
    ReminderPayload payload,
    Medication medication, {
    required String profileName,
    required String languageCode,
  });

  /// A dose was confirmed (on this phone OR another one): stop its snoozes,
  /// dismiss its ringing alarm and don't ring again today.
  Future<void> acknowledge(
    PersonProfile profile,
    Medication medication,
    int minutesOfDay, {
    required String languageCode,
  });

  Future<void> cancelSnooze(ReminderPayload payload);
  Future<void> cancelAll();
}
