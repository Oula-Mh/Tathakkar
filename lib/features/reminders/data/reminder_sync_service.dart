import 'dart:async';

import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/formatters.dart';
import '../../doses/domain/entities/dose_log.dart';
import '../../doses/domain/usecases/doses_usecases.dart';
import '../../medications/domain/entities/medication.dart';
import '../../medications/domain/usecases/medications_usecases.dart';
import '../../profiles/domain/entities/person_profile.dart';
import '../domain/entities/reminder_payload.dart';
import '../domain/repositories/reminder_scheduler.dart';
import '../domain/repositories/stock_alert_notifier.dart';

/// Keeps OS alarms and stock alerts in sync with the data of every profile
/// that rings on THIS phone (self + local). When a caregiver edits an
/// elder's medications remotely, the elder's phone reschedules here.
class ReminderSyncService {
  ReminderSyncService({
    required WatchMedications watchMedications,
    required WatchDoseLogs watchDoseLogs,
    required EnsurePendingDoses ensurePending,
    required ReminderScheduler scheduler,
    required StockAlertNotifier stockAlerts,
  })  : _watch = watchMedications,
        _watchLogs = watchDoseLogs,
        _ensurePending = ensurePending,
        _scheduler = scheduler,
        _stockAlerts = stockAlerts;

  final WatchMedications _watch;
  final WatchDoseLogs _watchLogs;
  final EnsurePendingDoses _ensurePending;
  final ReminderScheduler _scheduler;
  final StockAlertNotifier _stockAlerts;

  final _subs = <String, StreamSubscription<Either<Failure, List<Medication>>>>{};
  final _data = <String, (PersonProfile, List<Medication>)>{};

  // Today's dose logs per profile: a "taken" log (from ANY phone) silences that dose's alarms.
  final _logSubs = <String, StreamSubscription<Either<Failure, List<DoseLog>>>>{};
  final _takenLogs = <String, List<DoseLog>>{};
  int? _logsDay;
  Timer? _debounce;
  String _lang = 'ar';
  bool _enabled = true;

  void update(List<PersonProfile> profiles, {required String languageCode, required bool enabled}) {
    final changed = _lang != languageCode || _enabled != enabled;
    _lang = languageCode;
    _enabled = enabled;

    final wanted = {for (final p in profiles.where((p) => p.remindsOnThisDevice)) p.key: p};
    for (final key in _subs.keys.toList()) {
      if (!wanted.containsKey(key)) {
        _subs.remove(key)?.cancel();
        _logSubs.remove(key)?.cancel();
        _takenLogs.remove(key);
        _data.remove(key);
      }
    }
    for (final p in wanted.values) {
      if (_subs.containsKey(p.key)) {
        // Profile data may have changed (e.g. a caregiver link appeared).
        final old = _data[p.key];
        if (old != null && old.$1 != p) _data[p.key] = (p, old.$2);
        continue;
      }
      _watchTodayLogs(p);
      _subs[p.key] = _watch(p).listen((r) {
        r.fold(
          (f) => AppLogger.w('reminder sync: ${f.messageKey}'),
          (meds) {
            _data[p.key] = (p, meds);
            _applyAcks(p);
            _schedule();
            _stockAlerts.evaluate(p, meds, languageCode: _lang);
            if (p.managedByUid != null) _pendingFor(p, meds);
          },
        );
      });
    }
    if (changed) _schedule();
  }

  /// Doses whose exact time was within the last ~75 s and are not taken yet.
  /// Used while the app is OPEN so the alarm screen appears at the exact time
  /// (with tone, voice and big buttons) even if the phone hides banner buttons.
  List<ReminderPayload> dueNow(DateTime now) {
    if (!_enabled) return const [];
    final result = <ReminderPayload>[];
    for (final entry in _data.values) {
      final p = entry.$1;
      for (final m in entry.$2) {
        if (!m.remindersEnabled || !m.isActiveOn(now)) continue;
        for (final minutes in m.times) {
          final late = now.difference(minutes.onDay(now.dateOnly));
          if (late < Duration.zero || late > const Duration(seconds: 75)) continue;
          final taken = (_takenLogs[p.key] ?? const <DoseLog>[]).any((l) =>
              l.medicationId == m.id && l.scheduledAt.hour * 60 + l.scheduledAt.minute == minutes);
          if (taken) continue;
          result.add(ReminderPayload(
            ownerUid: p.ownerUid,
            profileId: p.profileId,
            medicationId: m.id,
            minutesOfDay: minutes,
            personName: p.isSelf ? '' : p.name,
          ));
        }
      }
    }
    return result;
  }

  /// Re-applies the schedule now (after a permission was granted, app resumed...).
  /// A new day also needs fresh "taken today" subscriptions.
  void resync() {
    if (_logsDay != ReminderPayload.dayKey(DateTime.now())) {
      for (final p in _data.values.map((e) => e.$1)) {
        _watchTodayLogs(p);
      }
    }
    _schedule(immediate: true);
  }

  void _watchTodayLogs(PersonProfile p) {
    _logSubs.remove(p.key)?.cancel();
    final today = DateTime.now().dateOnly;
    _logsDay = ReminderPayload.dayKey(today);
    _logSubs[p.key] = _watchLogs(p, today, today.add(const Duration(days: 1))).listen((r) {
      r.fold((_) {}, (logs) {
        _takenLogs[p.key] = logs.where((l) => l.status == DoseStatus.taken).toList();
        _applyAcks(p);
      });
    });
  }

  /// Taken today anywhere => no more rings for that dose (snoozes included).
  void _applyAcks(PersonProfile p) {
    final meds = _data[p.key]?.$2;
    final taken = _takenLogs[p.key];
    if (meds == null || taken == null) return;
    for (final log in taken) {
      final med = meds.where((m) => m.id == log.medicationId).firstOrNull;
      if (med == null) continue;
      _scheduler.acknowledge(p, med, log.scheduledAt.hour * 60 + log.scheduledAt.minute,
          languageCode: _lang);
    }
  }

  void _schedule({bool immediate = false}) {
    _debounce?.cancel();
    void run() => _scheduler.syncAll(
          {for (final e in _data.values) e.$1: e.$2},
          languageCode: _lang,
          enabled: _enabled,
        );
    if (immediate) {
      run();
    } else {
      _debounce = Timer(const Duration(milliseconds: 600), run);
    }
  }

  /// For managed elders: create "pending" logs for today so the server can
  /// notify the caregiver if a dose isn't confirmed within 30 minutes.
  Future<void> _pendingFor(PersonProfile p, List<Medication> meds) async {
    final today = DateTime.now().dateOnly;
    for (final m in meds) {
      if (!m.isActiveOn(today) || !m.remindersEnabled) continue;
      final slots = m.times.map((t) => t.onDay(today)).toList();
      final r = await _ensurePending(EnsurePendingParams(p, m, slots));
      r.leftMap((f) => AppLogger.w('ensurePending failed: ${f.messageKey}'));
    }
  }

  void dispose() {
    _debounce?.cancel();
    for (final s in _subs.values) {
      s.cancel();
    }
    for (final s in _logSubs.values) {
      s.cancel();
    }
    _subs.clear();
    _logSubs.clear();
    _takenLogs.clear();
    _data.clear();
  }
}
