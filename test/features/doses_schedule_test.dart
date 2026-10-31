import 'package:flutter_test/flutter_test.dart';
import 'package:tathakkar/features/doses/domain/entities/dose_log.dart';
import 'package:tathakkar/features/doses/domain/entities/scheduled_dose.dart';
import 'package:tathakkar/features/doses/domain/usecases/doses_usecases.dart';
import 'package:tathakkar/features/medications/domain/entities/medication.dart';

void main() {
  const builder = BuildDaySchedule();
  final day = DateTime(2026, 10, 27);
  final med = Medication(
    id: 'm1',
    name: 'Metformin',
    startDate: DateTime(2026, 10, 1),
    times: const [8 * 60, 20 * 60],
  );

  test('upcoming before the time, due within 30 min, unconfirmed after', () {
    List<ScheduledDose> at(int h, int m) => builder(
        medications: [med], logs: const [], day: day, now: DateTime(2026, 10, 27, h, m));
    expect(at(7, 0).first.status, DoseDisplayStatus.upcoming);
    expect(at(8, 10).first.status, DoseDisplayStatus.due);
    expect(at(8, 45).first.status, DoseDisplayStatus.unconfirmed);
  });

  test('stays DUE through every snooze, then becomes unconfirmed', () {
    // snooze 10 min x 2 snoozes + 5 min last ring = due until 08:25
    List<ScheduledDose> at(int h, int m, [int s = 0]) => builder(
        medications: [med], logs: const [], day: day, now: DateTime(2026, 10, 27, h, m, s));
    expect(at(8, 0).first.status, DoseDisplayStatus.due); // exactly on time
    expect(at(8, 10).first.status, DoseDisplayStatus.due); // after snooze 1
    expect(at(8, 20).first.status, DoseDisplayStatus.due); // last ring
    expect(at(8, 25).first.status, DoseDisplayStatus.due);
    expect(at(8, 26).first.status, DoseDisplayStatus.unconfirmed);
  });

  test('server "missed" flag does not end the due state early', () {
    final log = DoseLog(
      id: doseLogId('m1', DateTime(2026, 10, 27, 8)),
      medicationId: 'm1',
      medicationName: 'Metformin',
      scheduledAt: DateTime(2026, 10, 27, 8),
      status: DoseStatus.missed,
    );
    final r = builder(
        medications: [med], logs: [log], day: day, now: DateTime(2026, 10, 27, 8, 12));
    expect(r.first.status, DoseDisplayStatus.due);
  });

  test('a taken log wins over time', () {
    final log = DoseLog(
      id: doseLogId('m1', DateTime(2026, 10, 27, 8)),
      medicationId: 'm1',
      medicationName: 'Metformin',
      scheduledAt: DateTime(2026, 10, 27, 8),
      status: DoseStatus.taken,
    );
    final r = builder(medications: [med], logs: [log], day: day, now: DateTime(2026, 10, 27, 12));
    expect(r.first.status, DoseDisplayStatus.taken);
  });

  test('ended temporary course produces no doses', () {
    final ended = med.copyWith(type: TreatmentType.temporary, endDate: DateTime(2026, 10, 20));
    expect(builder(medications: [ended], logs: const [], day: day, now: day), isEmpty);
  });

  test('dose log id is deterministic (no double stock deduction)', () {
    final t = DateTime(2026, 10, 27, 8, 5);
    expect(doseLogId('m1', t), doseLogId('m1', t));
    expect(doseLogId('m1', t), 'm1_202610270805');
  });
}
