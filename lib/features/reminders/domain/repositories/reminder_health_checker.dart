import '../entities/reminder_health.dart';

abstract interface class ReminderHealthChecker {
  Future<ReminderHealth> check();
  Future<bool> request(HealthItem item);
  Future<void> scheduleTest({required int seconds, required String languageCode});
  Future<void> showTestNow({required String languageCode});
}
