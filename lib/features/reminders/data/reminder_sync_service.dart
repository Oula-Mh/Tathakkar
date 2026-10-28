import 'dart:async';

import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/formatters.dart';
import '../../doses/domain/usecases/doses_usecases.dart';
import '../../medications/domain/entities/medication.dart';
import '../../medications/domain/usecases/medications_usecases.dart';
import '../../profiles/domain/entities/person_profile.dart';
import '../domain/repositories/reminder_scheduler.dart';

/// Keeps OS reminders in sync with Firestore/Hive data for every profile
/// that rings on THIS phone (self + local). When a caregiver edits an
/// elder's medications remotely, the elder's phone reschedules here.
class ReminderSyncService {
  ReminderSyncService({
    required WatchMedications watchMedications,
    required EnsurePendingDoses ensurePending,
    required ReminderScheduler scheduler,
  })  : _watch = watchMedications,
        _ensurePending = ensurePending,
        _scheduler = scheduler;

  final WatchMedications _watch;
  final EnsurePendingDoses _ensurePending;
  final ReminderScheduler _scheduler;

  final _subs = <String, StreamSubscription<Either<Failure, List<Medication>>>>{};
  final _data = <String, (PersonProfile, List<Medication>)>{};
  Timer? _debounce;
  String _lang = 'ar';
  bool _enabled = true;

  void update(List<PersonProfile> profiles, {required String languageCode, required bool enabled}) {
    final langChanged = _lang != languageCode || _enabled != enabled;
    _lang = languageCode;
    _enabled = enabled;

    final wanted = {for (final p in profiles.where((p) => p.remindsOnThisDevice)) p.key: p};
    for (final key in _subs.keys.toList()) {
      if (!wanted.containsKey(key)) {
        _subs.remove(key)?.cancel();
        _data.remove(key);
      }
    }
    for (final p in wanted.values) {
      if (_subs.containsKey(p.key)) continue;
      _subs[p.key] = _watch(p).listen((r) {
        r.fold((_) {}, (meds) {
          _data[p.key] = (p, meds);
          _schedule();
          if (p.managedByUid != null) _pendingFor(p, meds);
        });
      });
    }
    if (langChanged) _schedule();
  }

  void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      _scheduler.syncAll(
        {for (final e in _data.values) e.$1: e.$2},
        languageCode: _lang,
        enabled: _enabled,
      );
    });
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
    _subs.clear();
    _data.clear();
  }
}
