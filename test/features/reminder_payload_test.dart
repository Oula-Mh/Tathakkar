import 'package:flutter_test/flutter_test.dart';
import 'package:tathakkar/features/reminders/domain/entities/reminder_payload.dart';

void main() {
  const daily = ReminderPayload(
      ownerUid: 'u1', profileId: 'self', medicationId: 'm1', minutesOfDay: 480);

  test('encode/parse round trip', () {
    final p = ReminderPayload.tryParse(daily.encode());
    expect(p, daily);
  });

  test('rejects garbage', () {
    expect(ReminderPayload.tryParse('t'), isNull);
    expect(ReminderPayload.tryParse('x|a|b|c|1|1'), isNull);
    expect(ReminderPayload.tryParse('d|a|b|c|notanumber|0'), isNull);
  });

  test('snooze keeps the ORIGINAL day (works past midnight)', () {
    final now = DateTime(2026, 10, 27, 23, 55);
    final first = daily.copyWith2(minutes: 23 * 60 + 50);
    final snoozed = first.snoozed(now);
    expect(snoozed.kind, ReminderKind.snooze);
    expect(snoozed.snoozeCount, 1);
    final after = DateTime(2026, 10, 28, 0, 5);
    expect(snoozed.originalTime(after), DateTime(2026, 10, 27, 23, 50));
  });

  test('person name survives encoding (even with | and Arabic)', () {
    const p = ReminderPayload(
        ownerUid: 'u1', profileId: 'kid1', medicationId: 'm1', minutesOfDay: 480, personName: 'ليلى | الصغيرة');
    final parsed = ReminderPayload.tryParse(p.encode())!;
    expect(parsed.personName, 'ليلى | الصغيرة');
    expect(parsed, p);
  });

  test('isCurrentDose rejects stale and far-future intents', () {
    final dose = daily.copyWith2(minutes: 8 * 60); // 08:00
    expect(dose.isCurrentDose(DateTime(2026, 10, 27, 8, 0, 30)), isTrue);
    expect(dose.isCurrentDose(DateTime(2026, 10, 27, 8, 40)), isTrue);
    expect(dose.isCurrentDose(DateTime(2026, 10, 27, 9, 30)), isFalse); // old intent
    expect(dose.isCurrentDose(DateTime(2026, 10, 27, 7, 0)), isFalse); // dose not yet due
  });

  test('stock payload is recognised', () {
    const k = ReminderPayload(
        ownerUid: 'u1', profileId: 'self', medicationId: 'm1', kind: ReminderKind.stock);
    expect(ReminderPayload.tryParse(k.encode())!.isStock, isTrue);
  });
}

extension on ReminderPayload {
  ReminderPayload copyWith2({required int minutes}) => ReminderPayload(
      ownerUid: ownerUid, profileId: profileId, medicationId: medicationId, minutesOfDay: minutes);
}
