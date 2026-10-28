import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/l10n_keys.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/app_logger.dart';
import 'package:flutter/material.dart' show Locale;

import '../../medications/domain/entities/medication.dart';
import '../../profiles/domain/entities/person_profile.dart';
import '../domain/entities/reminder_payload.dart';
import '../domain/repositories/reminder_scheduler.dart';

class LocalReminderScheduler implements ReminderScheduler {
  LocalReminderScheduler(this._notifications);
  final NotificationService _notifications;

  /// FNV-1a: String.hashCode is not stable between app runs.
  static int stableId(String s) {
    var h = 0x811C9DC5;
    for (final c in s.codeUnits) {
      h = ((h ^ c) * 0x01000193) & 0x7FFFFFFF;
    }
    return h;
  }

  String _title(AppLocalizations l, Medication m, String profileName, bool self) =>
      self ? m.name : '${l.tr(L.notifFor, args: {'name': profileName})} • ${m.name}';

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

  @override
  Future<void> syncAll(
    Map<PersonProfile, List<Medication>> byProfile, {
    required String languageCode,
    required bool enabled,
  }) async {
    try {
      await _notifications.cancelWhereKind('${ReminderPayload.dailyKind}|');
      if (!enabled) return;
      final l = AppLocalizations(Locale(languageCode));
      for (final entry in byProfile.entries) {
        final profile = entry.key;
        if (!profile.remindsOnThisDevice) continue;
        for (final m in entry.value) {
          if (!m.remindersEnabled || m.isCourseEnded(DateTime.now())) continue;
          for (final minutes in m.times) {
            final payload = ReminderPayload(
              ownerUid: profile.ownerUid,
              profileId: profile.profileId,
              medicationId: m.id,
              minutesOfDay: minutes,
            );
            await _notifications.scheduleDaily(
              id: stableId('${profile.key}/${m.id}/$minutes'),
              title: _title(l, m, profile.name, profile.isSelf),
              body: _body(l, m),
              minutesOfDay: minutes,
              payload: payload.encode(),
              sound: m.soundEnabled,
              fullScreen: m.fullScreen,
            );
          }
        }
      }
    } catch (e, st) {
      // Scheduling must never crash the app (e.g. permission revoked).
      AppLogger.e('syncAll failed', e, st);
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
    final next = payload.snoozed();
    final isFinal = next.snoozeCount >= 2;
    try {
      await _notifications.scheduleOnce(
        id: stableId(_snoozeKey(payload)),
        title: '${isFinal ? '${l.tr(L.finalReminder)} • ' : ''}${medication.name}',
        body: _body(l, medication),
        at: DateTime.now().add(Duration(minutes: medication.snoozeMinutes)),
        payload: next.encode(),
        sound: medication.soundEnabled,
        fullScreen: medication.fullScreen,
      );
    } catch (e, st) {
      AppLogger.e('snooze failed', e, st);
    }
  }

  static String _snoozeKey(ReminderPayload p) =>
      'snooze/${p.ownerUid}/${p.profileId}/${p.medicationId}/${p.minutesOfDay}';

  @override
  Future<void> cancelSnooze(ReminderPayload payload) async {
    try {
      await _notifications.cancel(stableId(_snoozeKey(payload)));
    } catch (_) {}
  }
}
