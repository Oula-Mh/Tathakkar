import 'package:flutter/material.dart' show Locale;

import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/l10n_keys.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/utils/app_logger.dart';
import '../../medications/domain/entities/medication.dart';
import '../../profiles/domain/entities/person_profile.dart';
import '../domain/entities/reminder_payload.dart';
import '../domain/repositories/reminder_scheduler.dart';

class LocalReminderScheduler implements ReminderScheduler {
  LocalReminderScheduler(this._notifications, this._flags);
  final NotificationService _notifications;

  /// Remembers which doses were already taken today ("ack/<yyyymmdd>/...").
  final LocalStorage _flags;

  /// FNV-1a: String.hashCode is not stable between app runs.
  static int stableId(String s) {
    var h = 0x811C9DC5;
    for (final c in s.codeUnits) {
      h = ((h ^ c) * 0x01000193) & 0x7FFFFFFF;
    }
    return h;
  }

  static int dailyId(String profileKey, String medId, int minutes) =>
      stableId('$profileKey/$medId/$minutes');

  static String _ackKey(String profileKey, String medId, int minutes) =>
      'ack/${ReminderPayload.dayKey(DateTime.now())}/$profileKey/$medId/$minutes';

  bool _isAcked(String profileKey, String medId, int minutes) =>
      _flags.read<bool>(_ackKey(profileKey, medId, minutes)) ?? false;

  /// Old days' flags are useless: delete them.
  Future<void> _pruneAcks() async {
    final today = 'ack/${ReminderPayload.dayKey(DateTime.now())}/';
    for (final k in _flags.keys.toList()) {
      if (k.startsWith('ack/') && !k.startsWith(today)) await _flags.remove(k);
    }
  }

  static String _snoozeKey(ReminderPayload p) =>
      'snooze/${p.ownerUid}/${p.profileId}/${p.medicationId}/${p.minutesOfDay}';

  String _title(AppLocalizations l, Medication m, String profileName, bool self) =>
      self || profileName.isEmpty
          ? m.name
          : '${l.tr(L.notifFor, args: {'name': profileName})} • ${m.name}';

  String _body(AppLocalizations l, Medication m) {
    final meal = switch (m.meal) {
      MealRelation.before => l.tr(L.mealBefore),
      MealRelation.after => l.tr(L.mealAfter),
      MealRelation.withMeal => l.tr(L.mealWith),
      MealRelation.anytime => '',
    };
    final dose = l.tr(L.doseUnits, args: {'n': '${m.dosePerTake}'});
    return [dose, if (meal.isNotEmpty) meal, ...m.notes].join(' · ');
  }

  Future<void> _scheduleDaily(
    AppLocalizations l,
    String languageCode, {
    required String profileKey,
    required ReminderPayload payload,
    required Medication m,
    required String profileName,
    required bool self,
    bool skipToday = false,
  }) =>
      _notifications.scheduleDaily(
        id: dailyId(profileKey, m.id, payload.minutesOfDay),
        title: _title(l, m, profileName, self),
        body: _body(l, m),
        minutesOfDay: payload.minutesOfDay,
        payload: payload.encode(),
        sound: m.soundEnabled,
        fullScreen: m.fullScreen,
        languageCode: languageCode,
        takenLabel: l.tr(L.actionTaken),
        snoozeLabel: l.tr(L.actionSnoozeShort),
        skipToday: skipToday,
      );

  @override
  Future<void> syncAll(
    Map<PersonProfile, List<Medication>> byProfile, {
    required String languageCode,
    required bool enabled,
  }) async {
    final l = AppLocalizations(Locale(languageCode));
    final known = {for (final p in byProfile.keys) p.key};
    final active = <String>{}; // "profileKey/medId" that should have alarms

    try {
      await _pruneAcks();
      await _notifications.updateChannelNames(languageCode);

      // Cancel dailies ONLY for profiles whose data we have (others keep their alarms).
      for (final req in await _notifications.pending()) {
        final p = ReminderPayload.tryParse(req.payload ?? '');
        if (p != null && p.kind == ReminderKind.daily && known.contains(p.profileKey)) {
          await _notifications.cancel(req.id);
        }
      }
    } catch (e, st) {
      AppLogger.e('syncAll cleanup failed', e, st);
    }

    if (enabled) {
      for (final entry in byProfile.entries) {
        final profile = entry.key;
        if (!profile.remindsOnThisDevice) continue;
        for (final m in entry.value) {
          if (!m.remindersEnabled || m.isCourseEnded(DateTime.now())) continue;
          active.add('${profile.key}/${m.id}');
          for (final minutes in m.times) {
            // One failing alarm must never prevent the others from being scheduled.
            try {
              await _scheduleDaily(
                l,
                languageCode,
                profileKey: profile.key,
                payload: ReminderPayload(
                  ownerUid: profile.ownerUid,
                  profileId: profile.profileId,
                  medicationId: m.id,
                  minutesOfDay: minutes,
                  personName: profile.isSelf ? '' : profile.name,
                ),
                m: m,
                profileName: profile.name,
                self: profile.isSelf,
                // Already taken today (here or on another phone): ring from tomorrow.
                skipToday: _isAcked(profile.key, m.id, minutes),
              );
            } catch (e, st) {
              AppLogger.e('Could not schedule ${m.name} @ $minutes', e, st);
            }
          }
        }
      }
    }

    // Drop snoozes of medications that were deleted / switched off.
    try {
      for (final req in await _notifications.pending()) {
        final p = ReminderPayload.tryParse(req.payload ?? '');
        if (p != null && p.isSnooze && known.contains(p.profileKey) &&
            !active.contains('${p.profileKey}/${p.medicationId}')) {
          await _notifications.cancel(req.id);
        }
      }
    } catch (e, st) {
      AppLogger.e('snooze cleanup failed', e, st);
    }
  }

  @override
  Future<void> snooze(
    ReminderPayload payload,
    Medication medication, {
    required String profileName,
    required String languageCode,
  }) async {
    final l = AppLocalizations(Locale(languageCode));
    final next = payload.snoozed(DateTime.now());
    final isFinal = next.snoozeCount >= 2;
    final self = payload.profileId == 'self';
    final title = _title(l, medication, profileName, self);
    try {
      await _notifications.scheduleOnce(
        id: stableId(_snoozeKey(payload)),
        title: isFinal ? '${l.tr(L.finalReminder)} • $title' : title,
        body: _body(l, medication),
        at: DateTime.now().add(Duration(minutes: medication.snoozeMinutes)),
        payload: next.encode(),
        sound: medication.soundEnabled,
        fullScreen: medication.fullScreen,
        languageCode: languageCode,
        takenLabel: l.tr(L.actionTaken),
        snoozeLabel: l.tr(L.actionSnoozeShort),
        allowSnooze: !isFinal,
      );
    } catch (e, st) {
      AppLogger.e('snooze failed', e, st);
      rethrow; // the UI must not claim "snoozed" if nothing was scheduled
    }
  }

  @override
  Future<void> silence(
    ReminderPayload payload,
    Medication medication, {
    required String profileName,
    required String languageCode,
  }) async {
    try {
      if (payload.isStock) return;
      if (payload.isSnooze) {
        await cancelSnooze(payload);
        return;
      }
      // Cancel the ringing notification, then restore the recurring alarm.
      final id = dailyId(payload.profileKey, medication.id, payload.minutesOfDay);
      await _notifications.cancel(id);
      await _scheduleDaily(
        AppLocalizations(Locale(languageCode)),
        languageCode,
        profileKey: payload.profileKey,
        payload: payload,
        m: medication,
        profileName: profileName,
        self: payload.profileId == 'self',
      );
    } catch (e, st) {
      AppLogger.e('silence failed', e, st);
    }
  }

  @override
  Future<void> acknowledge(
    PersonProfile profile,
    Medication medication,
    int minutesOfDay, {
    required String languageCode,
  }) async {
    final key = _ackKey(profile.key, medication.id, minutesOfDay);
    if (_flags.read<bool>(key) ?? false) return; // already handled
    try {
      await _flags.write(key, true);
      final payload = ReminderPayload(
        ownerUid: profile.ownerUid,
        profileId: profile.profileId,
        medicationId: medication.id,
        minutesOfDay: minutesOfDay,
        personName: profile.isSelf ? '' : profile.name,
      );
      await cancelSnooze(payload); // no more "remind me later" rings
      if (!medication.remindersEnabled) return;
      // Dismiss the ringing/pending alarm and restart the daily one from tomorrow.
      await _notifications.cancel(dailyId(profile.key, medication.id, minutesOfDay));
      await _scheduleDaily(
        AppLocalizations(Locale(languageCode)),
        languageCode,
        profileKey: profile.key,
        payload: payload,
        m: medication,
        profileName: profile.name,
        self: profile.isSelf,
        skipToday: true,
      );
    } catch (e, st) {
      AppLogger.e('acknowledge failed', e, st);
    }
  }

  @override
  Future<void> cancelSnooze(ReminderPayload payload) async {
    try {
      await _notifications.cancel(stableId(_snoozeKey(payload)));
    } catch (_) {}
  }

  @override
  Future<void> cancelAll() => _notifications.cancelAll();
}
