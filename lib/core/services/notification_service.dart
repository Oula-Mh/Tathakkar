import 'dart:async';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../constants/app_constants.dart';
import '../utils/app_logger.dart';

/// A tap on a notification (or on one of its action buttons).
class NotificationTap extends Equatable {
  const NotificationTap(this.payload, {this.actionId});
  final String payload;
  final String? actionId;
  @override
  List<Object?> get props => [payload, actionId];
}

/// What the OS currently allows us to do (shown on the diagnostics screen).
class PlatformReminderStatus extends Equatable {
  const PlatformReminderStatus({
    required this.notificationsGranted,
    required this.exactAlarmsGranted,
    required this.batteryOptimizationIgnored,
    required this.pendingDoseAlarms,
    required this.isAndroid,
  });
  final bool notificationsGranted;
  final bool exactAlarmsGranted;
  final bool batteryOptimizationIgnored;
  final int pendingDoseAlarms;
  final bool isAndroid;

  @override
  List<Object?> get props => [
        notificationsGranted,
        exactAlarmsGranted,
        batteryOptimizationIgnored,
        pendingDoseAlarms,
        isAndroid,
      ];
}

/// Wrapper over flutter_local_notifications. Works offline; the OS fires the alarms.
class NotificationService {
  NotificationService() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final _taps = StreamController<NotificationTap>.broadcast();
  NotificationTap? _launchTap;

  static final _vibration = Int64List.fromList([0, 900, 400, 900, 400, 900]);

  // /// Channel sound: the app's tone (res/raw) or the phone's alarm ringtone.
  // static const AndroidNotificationSound _alarmSound = NotificationIds.useCustomAlarmSound
  //     ? RawResourceAndroidNotificationSound(NotificationIds.customSoundResource)
  //     : UriAndroidNotificationSound(NotificationIds.alarmSoundUri);

/// Channel sound: using default notification/alarm sound safely
  static const AndroidNotificationSound? _alarmSound = null;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  Stream<NotificationTap> get taps => _taps.stream;

  /// True when the app was started by tapping/ringing a notification.
  bool get hasLaunchTap => _launchTap != null;

  NotificationTap? peekLaunchTap() => _launchTap;

  /// The tap that cold-started the app (consume once).
  NotificationTap? takeLaunchTap() {
    final t = _launchTap;
    _launchTap = null;
    return t;
  }

  // ------------------------------------------------------------------ init
  Future<void> init({String languageCode = 'ar'}) async {
    await _initTimezone();
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: _onResponse,
    );
    await updateChannelNames(languageCode);

    final launch = await _plugin.getNotificationAppLaunchDetails();
    final r = launch?.notificationResponse;
    if ((launch?.didNotificationLaunchApp ?? false) && r?.payload != null) {
      _launchTap = NotificationTap(r!.payload!, actionId: _cleanAction(r.actionId));
    }
  }

  static String? _cleanAction(String? id) => (id == null || id.isEmpty) ? null : id;

  void _onResponse(NotificationResponse r) {
    final p = r.payload;
    if (p == null) return;
    _taps.add(NotificationTap(p, actionId: _cleanAction(r.actionId)));
  }

  /// Timezone: a wrong local zone silently shifts every alarm, so we never
  /// fall back to UTC: if the plugin fails we match the device UTC offset.
  Future<void> _initTimezone() async {
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
      return;
    } catch (e) {
      AppLogger.w('flutter_timezone failed ($e); matching by UTC offset');
    }
    final offset = DateTime.now().timeZoneOffset;
    for (final loc in tz.timeZoneDatabase.locations.values) {
      if (tz.TZDateTime.now(loc).timeZoneOffset == offset) {
        tz.setLocalLocation(loc);
        return;
      }
    }
  }

  /// (Re)creates the channels with names in the user's language. Android keeps
  /// sound/importance of an existing channel but accepts new names/descriptions.
  Future<void> updateChannelNames(String languageCode) async {
    final android = _android;
    if (android == null) return;
    final ar = languageCode == 'ar';

    for (final old in NotificationIds.legacyChannels) {
      try {
        await android.deleteNotificationChannel(old);
      } catch (_) {}
    }

    await android.createNotificationChannel(AndroidNotificationChannel(
      NotificationIds.doseAlarmChannel,
      ar ? 'منبّه الجرعات' : 'Dose alarms',
      description: ar ? 'تنبيه بصوت المنبّه عند موعد الدواء' : 'Alarm-style reminder when a dose is due',
      importance: Importance.max,
      playSound: true,
      sound: _alarmSound,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      enableVibration: true,
      vibrationPattern: _vibration,
      enableLights: true,
      showBadge: true,
    ));
    await android.createNotificationChannel(AndroidNotificationChannel(
      NotificationIds.doseSilentChannel,
      ar ? 'تذكير الجرعات (صامت)' : 'Dose reminders (silent)',
      description: ar ? 'تنبيه بدون صوت' : 'Reminder without sound',
      importance: Importance.high,
      playSound: false,
      enableVibration: false,
    ));
    await android.createNotificationChannel(AndroidNotificationChannel(
      NotificationIds.stockChannel,
      ar ? 'مخزون الأدوية' : 'Medication stock',
      description: ar ? 'عند اقتراب نفاد الدواء أو نفاده' : 'When a medication is running low or out',
      importance: Importance.high,
      playSound: true,
    ));
    await android.createNotificationChannel(AndroidNotificationChannel(
      NotificationIds.caregiverChannel,
      ar ? 'إشعارات مقدّم الرعاية' : 'Caregiver alerts',
      description: ar ? 'جرعات غير مؤكدة وحالة المخزون' : 'Unconfirmed doses and stock status',
      importance: Importance.high,
      playSound: true,
    ));
  }

  // ----------------------------------------------------------- permissions
  Future<PlatformReminderStatus> status() async {
    final android = _android;
    final notifications = android != null
        ? (await android.areNotificationsEnabled()) ?? false
        : await Permission.notification.isGranted;
    final exact = android != null ? (await android.canScheduleExactNotifications()) ?? false : true;
    final battery = Platform.isAndroid ? await Permission.ignoreBatteryOptimizations.isGranted : true;
    final pending = await _plugin.pendingNotificationRequests();
    return PlatformReminderStatus(
      notificationsGranted: notifications,
      exactAlarmsGranted: exact,
      batteryOptimizationIgnored: battery,
      pendingDoseAlarms: pending.where((p) => (p.payload ?? '').startsWith('d|')).length,
      isAndroid: Platform.isAndroid,
    );
  }

  Future<bool> requestNotifications() async => (await Permission.notification.request()).isGranted;

  /// Opens "Alarms & reminders" settings on Android 12+.
  Future<bool> requestExactAlarms() async {
    try {
      return (await _android?.requestExactAlarmsPermission()) ?? true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestFullScreenIntent() async {
    try {
      return (await _android?.requestFullScreenIntentPermission()) ?? true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestIgnoreBatteryOptimizations() async {
    if (!Platform.isAndroid) return true;
    return (await Permission.ignoreBatteryOptimizations.request()).isGranted;
  }

  // -------------------------------------------------------------- details
  /// Alarm-style dose notification: alarm volume (rings even on silent),
  /// repeats until handled (FLAG_INSISTENT), wakes the screen, action buttons.
  NotificationDetails _doseDetails({
    required String body,
    required bool sound,
    required bool fullScreen,
    required String languageCode,
    required String takenLabel,
    required String snoozeLabel,
    bool withActions = true,
    bool allowSnooze = true,
  }) {
    final ar = languageCode == 'ar';
    return NotificationDetails(
      android: AndroidNotificationDetails(
        sound ? NotificationIds.doseAlarmChannel : NotificationIds.doseSilentChannel,
        sound ? (ar ? 'منبّه الجرعات' : 'Dose alarms') : (ar ? 'تذكير الجرعات (صامت)' : 'Dose reminders (silent)'),
        channelDescription: ar ? 'تنبيه عند موعد الدواء' : 'Reminder when a dose is due',
        importance: Importance.max,
        priority: Priority.max,
        playSound: sound,
        sound: sound ? _alarmSound : null,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        enableVibration: sound,
        vibrationPattern: sound ? _vibration : null,
        enableLights: true,
        fullScreenIntent: fullScreen,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        autoCancel: true,
        ongoing: false,
        timeoutAfter: NotificationIds.alarmTimeoutMs,
        additionalFlags: sound ? Int32List.fromList(<int>[4]) : null, // FLAG_INSISTENT
        ticker: ar ? 'حان موعد الدواء' : 'Time for your medication',
        // Expandable style: phones that hide action buttons in the compact
        // banner show them as soon as the banner is expanded.
        styleInformation: BigTextStyleInformation(body),
        actions: withActions
            ? [
                AndroidNotificationAction(NotificationIds.actionTaken, takenLabel,
                    showsUserInterface: true, cancelNotification: true),
                if (allowSnooze)
                  AndroidNotificationAction(NotificationIds.actionSnooze, snoozeLabel,
                      showsUserInterface: true, cancelNotification: true),
              ]
            : null,
      ),
      iOS: DarwinNotificationDetails(
        presentSound: sound,
        presentAlert: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
  }

  /// Next moment of that clock time. [skipToday] = the dose of today was already
  /// taken, so the recurring alarm starts tomorrow.
  tz.TZDateTime _nextInstance(int minutesOfDay, {bool skipToday = false}) {
    final now = tz.TZDateTime.now(tz.local);
    var at = tz.TZDateTime(tz.local, now.year, now.month, now.day, minutesOfDay ~/ 60, minutesOfDay % 60);
    if (skipToday || !at.isAfter(now)) at = at.add(const Duration(days: 1));
    return at;
  }

  // ----------------------------------------------------------- scheduling
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int minutesOfDay,
    required String payload,
    required bool sound,
    required bool fullScreen,
    required String languageCode,
    required String takenLabel,
    required String snoozeLabel,
    bool skipToday = false,
  }) =>
      _schedule(
        id, title, body, _nextInstance(minutesOfDay, skipToday: skipToday), payload,
        _doseDetails(
          body: body,
          sound: sound,
          fullScreen: fullScreen,
          languageCode: languageCode,
          takenLabel: takenLabel,
          snoozeLabel: snoozeLabel,
        ),
        daily: true,
      );

  Future<void> scheduleOnce({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    required String payload,
    required bool sound,
    required bool fullScreen,
    required String languageCode,
    required String takenLabel,
    required String snoozeLabel,
    bool withActions = true,
    bool allowSnooze = true,
  }) =>
      _schedule(
        id, title, body, tz.TZDateTime.from(at, tz.local), payload,
        _doseDetails(
          body: body,
          sound: sound,
          fullScreen: fullScreen,
          languageCode: languageCode,
          takenLabel: takenLabel,
          snoozeLabel: snoozeLabel,
          withActions: withActions,
          allowSnooze: allowSnooze,
        ),
        daily: false,
      );

  /// Tries the most reliable mode first.
  ///  1) alarmClock: exact, survives Doze, needs NO special permission.
  ///  2) exactAllowWhileIdle: needs the "Alarms & reminders" permission.
  ///  3) inexact: last resort (can be late by minutes).
  Future<void> _schedule(int id, String title, String body, tz.TZDateTime when, String payload,
      NotificationDetails details,
      {required bool daily}) async {
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

    const modes = [
      AndroidScheduleMode.alarmClock,
      AndroidScheduleMode.exactAllowWhileIdle,
      AndroidScheduleMode.inexactAllowWhileIdle,
    ];
    Object? lastError;
    for (final mode in modes) {
      try {
        await go(mode);
        if (mode == AndroidScheduleMode.inexactAllowWhileIdle) {
          AppLogger.w('Alarm $id scheduled INEXACT: it may fire late');
        }
        return;
      } catch (e) {
        lastError = e;
        AppLogger.w('schedule mode $mode failed: $e');
      }
    }
    throw StateError('Could not schedule notification $id: $lastError');
  }

  // ----------------------------------------------------------------- show
  Future<void> showSimple({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    String? payload,
  }) =>
      _plugin.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.reminder,
            visibility: NotificationVisibility.public,
          ),
          iOS: const DarwinNotificationDetails(presentSound: true, presentAlert: true),
        ),
        payload: payload,
      );

  /// Shows a dose-style alarm right now (diagnostics "test now").
  Future<void> showDoseNow({
    required int id,
    required String title,
    required String body,
    required String payload,
    required String languageCode,
    required String takenLabel,
    required String snoozeLabel,
  }) =>
      _plugin.show(
        id,
        title,
        body,
        _doseDetails(
          body: body,
          sound: true,
          fullScreen: true,
          languageCode: languageCode,
          takenLabel: takenLabel,
          snoozeLabel: snoozeLabel,
          withActions: false,
        ),
        payload: payload,
      );

  // --------------------------------------------------------------- cancel
  Future<void> cancel(int id) => _plugin.cancel(id);
  Future<void> cancelAll() => _plugin.cancelAll();

  Future<List<PendingNotificationRequest>> pending() => _plugin.pendingNotificationRequests();

  /// Cancels pending notifications whose payload starts with [prefix].
  Future<void> cancelWhereKind(String prefix) async {
    for (final p in await pending()) {
      if ((p.payload ?? '').startsWith(prefix)) await _plugin.cancel(p.id);
    }
  }
}
