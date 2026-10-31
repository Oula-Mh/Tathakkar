import 'package:flutter/material.dart' show Locale;

import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/l10n_keys.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/utils/app_logger.dart';
import '../../medications/domain/entities/medication.dart';
import '../../profiles/domain/entities/person_profile.dart';
import '../domain/entities/reminder_payload.dart';
import '../domain/entities/stock_level.dart';
import '../domain/repositories/stock_alert_notifier.dart';
import 'local_reminder_scheduler.dart';

/// Shows ONE local notification each time a medication's stock crosses its
/// alert level (low, then out). The last alerted level is persisted so nothing
/// repeats on every Firestore snapshot or app restart.
class LocalStockAlertNotifier implements StockAlertNotifier {
  LocalStockAlertNotifier(this._notifications, this._flags);
  final NotificationService _notifications;
  final LocalStorage _flags;

  StockLevel? _stored(String key) {
    final v = _flags.read<String>(key);
    if (v == null) return null;
    for (final lvl in StockLevel.values) {
      if (lvl.name == v) return lvl;
    }
    return null;
  }

  @override
  Future<void> evaluate(PersonProfile profile, List<Medication> medications,
      {required String languageCode}) async {
    final l = AppLocalizations(Locale(languageCode));
    for (final m in medications) {
      if (m.id.isEmpty) continue;
      final key = 'stock/${profile.key}/${m.id}';
      try {
        final ended = m.isCourseEnded(DateTime.now());
        final current = ended ? StockLevel.ok : stockLevelOf(m);
        final last = _stored(key);
        final due = stockAlertDue(current: current, lastAlerted: last);

        if (current == StockLevel.ok) {
          if (last != null) await _flags.remove(key);
        } else if (last != current) {
          await _flags.write(key, current.name);
        }
        if (due == null) continue;

        final who = profile.isSelf ? '' : '${l.tr(L.notifFor, args: {'name': profile.name})} • ';
        final out = due == StockLevel.out;
        await _notifications.showSimple(
          id: LocalReminderScheduler.stableId(key),
          title: '$who${l.tr(out ? L.stockAlertOutTitle : L.stockAlertLowTitle)}',
          body: l.tr(out ? L.stockAlertOutBody : L.stockAlertLowBody,
              args: {'med': m.name, 'n': '${m.remaining}'}),
          channelId: NotificationIds.stockChannel,
          channelName: l.tr(L.channelStock),
          payload: ReminderPayload(
            ownerUid: profile.ownerUid,
            profileId: profile.profileId,
            medicationId: m.id,
            kind: ReminderKind.stock,
          ).encode(),
        );
      } catch (e, st) {
        AppLogger.e('stock alert failed for ${m.name}', e, st);
      }
    }
  }
}
