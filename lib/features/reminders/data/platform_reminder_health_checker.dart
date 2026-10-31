import 'package:flutter/material.dart' show Locale;

import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/l10n_keys.dart';
import '../../../core/services/notification_service.dart';
import '../domain/entities/reminder_health.dart';
import '../domain/repositories/reminder_health_checker.dart';

class PlatformReminderHealthChecker implements ReminderHealthChecker {
  PlatformReminderHealthChecker(this._notifications);
  final NotificationService _notifications;

  @override
  Future<ReminderHealth> check() async {
    final s = await _notifications.status();
    return ReminderHealth(
      notificationsGranted: s.notificationsGranted,
      exactAlarmsGranted: s.exactAlarmsGranted,
      batteryOptimizationIgnored: s.batteryOptimizationIgnored,
      pendingDoseAlarms: s.pendingDoseAlarms,
      isAndroid: s.isAndroid,
    );
  }

  @override
  Future<bool> request(HealthItem item) => switch (item) {
        HealthItem.notifications => _notifications.requestNotifications(),
        HealthItem.exactAlarms => _notifications.requestExactAlarms(),
        HealthItem.fullScreen => _notifications.requestFullScreenIntent(),
        HealthItem.battery => _notifications.requestIgnoreBatteryOptimizations(),
      };

  @override
  Future<void> scheduleTest({required int seconds, required String languageCode}) {
    final l = AppLocalizations(Locale(languageCode));
    return _notifications.scheduleOnce(
      id: NotificationIds.testNotificationId,
      title: l.tr(L.testAlarmTitle),
      body: l.tr(L.testAlarmBody),
      at: DateTime.now().add(Duration(seconds: seconds)),
      payload: 't',
      sound: true,
      fullScreen: true,
      languageCode: languageCode,
      takenLabel: l.tr(L.actionTaken),
      snoozeLabel: l.tr(L.actionSnoozeShort),
      withActions: false,
    );
  }

  @override
  Future<void> showTestNow({required String languageCode}) {
    final l = AppLocalizations(Locale(languageCode));
    return _notifications.showDoseNow(
      id: NotificationIds.testNotificationId + 1,
      title: l.tr(L.testAlarmTitle),
      body: l.tr(L.testAlarmBody),
      payload: 't',
      languageCode: languageCode,
      takenLabel: l.tr(L.actionTaken),
      snoozeLabel: l.tr(L.actionSnoozeShort),
    );
  }
}
