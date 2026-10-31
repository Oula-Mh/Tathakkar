import 'package:equatable/equatable.dart';

/// Snapshot of everything that must be true for alarms to ring on time.
class ReminderHealth extends Equatable {
  const ReminderHealth({
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

  /// Critical items: without them alarms are missing or late.
  bool get isOk => notificationsGranted && exactAlarmsGranted;

  @override
  List<Object?> get props => [
        notificationsGranted,
        exactAlarmsGranted,
        batteryOptimizationIgnored,
        pendingDoseAlarms,
        isAndroid,
      ];
}

enum HealthItem { notifications, exactAlarms, fullScreen, battery }
