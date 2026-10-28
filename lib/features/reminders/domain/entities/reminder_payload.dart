import 'package:equatable/equatable.dart';

/// What a notification carries so the reminder screen can open offline.
/// Format: kind|ownerUid|profileId|medicationId|minutesOfDay|snoozeCount
class ReminderPayload extends Equatable {
  const ReminderPayload({
    required this.ownerUid,
    required this.profileId,
    required this.medicationId,
    required this.minutesOfDay,
    this.snoozeCount = 0,
    this.isSnooze = false,
  });

  final String ownerUid;
  final String profileId;
  final String medicationId;
  final int minutesOfDay;
  final int snoozeCount;
  final bool isSnooze;

  static const dailyKind = 'd';
  static const snoozeKind = 's';

  String encode() =>
      '${isSnooze ? snoozeKind : dailyKind}|$ownerUid|$profileId|$medicationId|$minutesOfDay|$snoozeCount';

  static ReminderPayload? tryParse(String raw) {
    final p = raw.split('|');
    if (p.length != 6) return null;
    final minutes = int.tryParse(p[4]);
    final snooze = int.tryParse(p[5]);
    if (minutes == null || snooze == null) return null;
    return ReminderPayload(
      isSnooze: p[0] == snoozeKind,
      ownerUid: p[1],
      profileId: p[2],
      medicationId: p[3],
      minutesOfDay: minutes,
      snoozeCount: snooze,
    );
  }

  ReminderPayload snoozed() => ReminderPayload(
        ownerUid: ownerUid,
        profileId: profileId,
        medicationId: medicationId,
        minutesOfDay: minutesOfDay,
        snoozeCount: snoozeCount + 1,
        isSnooze: true,
      );

  /// Scheduled time of the ORIGINAL dose: today at [minutesOfDay],
  /// or yesterday if that moment is more than 12h ahead (past-midnight snooze).
  DateTime originalTime(DateTime now) {
    var at = DateTime(now.year, now.month, now.day, minutesOfDay ~/ 60, minutesOfDay % 60);
    if (at.difference(now) > const Duration(hours: 12)) at = at.subtract(const Duration(days: 1));
    return at;
  }

  @override
  List<Object?> get props => [ownerUid, profileId, medicationId, minutesOfDay, snoozeCount, isSnooze];
}
