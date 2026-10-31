import 'package:equatable/equatable.dart';

enum ReminderKind {
  daily('d'),
  snooze('s'),
  stock('k');

  const ReminderKind(this.code);
  final String code;

  static ReminderKind? fromCode(String c) {
    for (final k in values) {
      if (k.code == c) return k;
    }
    return null;
  }
}

/// What a notification carries so the right screen can open offline.
/// Format: kind|ownerUid|profileId|medicationId|minutesOfDay|snoozeCount|yyyymmdd-or-empty|urlEncodedName
class ReminderPayload extends Equatable {
  const ReminderPayload({
    required this.ownerUid,
    required this.profileId,
    required this.medicationId,
    this.minutesOfDay = 0,
    this.snoozeCount = 0,
    this.kind = ReminderKind.daily,
    this.originalDay,
    this.personName = '',
  });

  final String ownerUid;
  final String profileId;
  final String medicationId;
  final int minutesOfDay;
  final int snoozeCount;
  final ReminderKind kind;

  /// yyyymmdd of the ORIGINAL dose (set on snoozes so the date is never guessed).
  final int? originalDay;

  /// Name of the person (empty for the signed-in user): lets the alarm screen
  /// say "dose for Layla" even when it opens before any data is loaded.
  final String personName;

  static const dailyKind = 'd';
  static const snoozeKind = 's';
  static const stockKind = 'k';

  bool get isSnooze => kind == ReminderKind.snooze;
  bool get isStock => kind == ReminderKind.stock;
  String get profileKey => '$ownerUid/$profileId';

  String encode() => [
        kind.code,
        ownerUid,
        profileId,
        medicationId,
        minutesOfDay,
        snoozeCount,
        originalDay ?? '',
        Uri.encodeComponent(personName),
      ].join('|');

  static ReminderPayload? tryParse(String raw) {
    final p = raw.split('|');
    if (p.length < 6 || p.length > 8) return null;
    final kind = ReminderKind.fromCode(p[0]);
    final minutes = int.tryParse(p[4]);
    final snooze = int.tryParse(p[5]);
    if (kind == null || minutes == null || snooze == null) return null;
    return ReminderPayload(
      kind: kind,
      ownerUid: p[1],
      profileId: p[2],
      medicationId: p[3],
      minutesOfDay: minutes,
      snoozeCount: snooze,
      originalDay: p.length > 6 ? int.tryParse(p[6]) : null,
      personName: p.length > 7 ? Uri.decodeComponent(p[7]) : '',
    );
  }

  /// True while this dose is current. Android re-delivers an OLD notification
  /// intent when a killed app is restored; that must not open an alarm screen.
  bool isCurrentDose(DateTime now) {
    final age = now.difference(originalTime(now));
    return age >= const Duration(minutes: -2) && age <= const Duration(minutes: 60);
  }

  static int dayKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  /// The payload for the re-reminder after "remind me later".
  ReminderPayload snoozed(DateTime now) => ReminderPayload(
        ownerUid: ownerUid,
        profileId: profileId,
        medicationId: medicationId,
        minutesOfDay: minutesOfDay,
        snoozeCount: snoozeCount + 1,
        kind: ReminderKind.snooze,
        originalDay: originalDay ?? dayKey(originalTime(now)),
        personName: personName,
      );

  /// Scheduled time of the ORIGINAL dose. Snoozes carry the exact day;
  /// daily alarms assume today (or yesterday if that would be >12h ahead).
  DateTime originalTime(DateTime now) {
    final h = minutesOfDay ~/ 60, m = minutesOfDay % 60;
    final day = originalDay;
    if (day != null) return DateTime(day ~/ 10000, (day ~/ 100) % 100, day % 100, h, m);
    var at = DateTime(now.year, now.month, now.day, h, m);
    if (at.difference(now) > const Duration(hours: 12)) at = at.subtract(const Duration(days: 1));
    return at;
  }

  @override
  List<Object?> get props =>
      [ownerUid, profileId, medicationId, minutesOfDay, snoozeCount, kind, originalDay, personName];
}
