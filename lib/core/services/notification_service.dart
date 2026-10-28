import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../utils/app_logger.dart';

/// Thin wrapper over flutter_local_notifications (local, works offline).
class NotificationService {
  NotificationService() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final _taps = StreamController<String>.broadcast();
  String? _launchPayload;

  /// Payloads of notifications the user tapped.
  Stream<String> get taps => _taps.stream;

  /// Payload of the notification that cold-started the app (consume once).
  String? takeLaunchPayload() {
    final p = _launchPayload;
    _launchPayload = null;
    return p;
  }

  Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      AppLogger.w('Timezone init failed, using UTC: $e');
    }

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (r) {
        final p = r.payload;
        if (p != null) _taps.add(p);
      },
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      _launchPayload = launch!.notificationResponse?.payload;
    }
  }

  Future<bool> isGranted() async => (await Permission.notification.status).isGranted;

  /// Asks for notification (+ exact alarm on Android 12+) permission.
  Future<bool> requestPermission() async {
    final res = await Permission.notification.request();
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestExactAlarmsPermission();
    } catch (_) {}
    return res.isGranted;
  }

  NotificationDetails _details({required bool sound, required bool fullScreen}) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          sound ? 'doses_sound' : 'doses_silent',
          sound ? 'Dose reminders' : 'Dose reminders (silent)',
          channelDescription: 'Medication dose reminders',
          importance: Importance.max,
          priority: Priority.high,
          playSound: sound,
          fullScreenIntent: fullScreen,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
        ),
        iOS: DarwinNotificationDetails(
          presentSound: sound,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      );

  tz.TZDateTime _nextInstance(int minutesOfDay) {
    final now = tz.TZDateTime.now(tz.local);
    var at = tz.TZDateTime(tz.local, now.year, now.month, now.day, minutesOfDay ~/ 60, minutesOfDay % 60);
    if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
    return at;
  }

  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int minutesOfDay,
    required String payload,
    required bool sound,
    required bool fullScreen,
  }) =>
      _schedule(id, title, body, _nextInstance(minutesOfDay), payload, sound, fullScreen, daily: true);

  Future<void> scheduleOnce({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    required String payload,
    required bool sound,
    required bool fullScreen,
  }) =>
      _schedule(id, title, body, tz.TZDateTime.from(at, tz.local), payload, sound, fullScreen, daily: false);

  Future<void> _schedule(int id, String title, String body, tz.TZDateTime when, String payload,
      bool sound, bool fullScreen,
      {required bool daily}) async {
    final details = _details(sound: sound, fullScreen: fullScreen);
    Future<void> go(AndroidScheduleMode mode) => _plugin.zonedSchedule(
          id,
          title,
          body,
          when,
          details,
          androidScheduleMode: mode,
          matchDateTimeComponents: daily ? DateTimeComponents.time : null,
          payload: payload,
        );
    try {
      await go(AndroidScheduleMode.exactAllowWhileIdle);
    } catch (e) {
      // Exact alarms not permitted: fall back to inexact so reminders still fire.
      AppLogger.w('Exact schedule failed ($e), using inexact');
      await go(AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  Future<void> cancel(int id) => _plugin.cancel(id);

  /// Cancels pending notifications whose payload starts with [prefix].
  Future<void> cancelWhereKind(String prefix) async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final p in pending) {
      if ((p.payload ?? '').startsWith(prefix)) await _plugin.cancel(p.id);
    }
  }
}
