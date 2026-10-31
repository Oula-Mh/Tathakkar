import '../../../core/constants/app_constants.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/push_service.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/utils/app_logger.dart';
import '../domain/repositories/session_cleaner.dart';

class LocalSessionCleaner implements SessionCleaner {
  LocalSessionCleaner({
    required NotificationService notifications,
    required PushService push,
    required LocalStorage medicationsCache,
    required LocalStorage flags,
  })  : _notifications = notifications,
        _push = push,
        _meds = medicationsCache,
        _flags = flags;

  final NotificationService _notifications;
  final PushService _push;
  final LocalStorage _meds;
  final LocalStorage _flags;

  @override
  Future<void> prepareFor(String uid) async {
    final last = _flags.read<String>(HiveKeys.lastUid);
    if (last != null && last != uid) {
      AppLogger.w('Different user on this device: wiping previous session data');
      await _wipe();
    }
    await _flags.write(HiveKeys.lastUid, uid);
  }

  @override
  Future<void> clearForSignOut(String? uid) async {
    // Best effort: sign-out must never be blocked by a cleanup failure.
    if (uid != null) {
      try {
        await _push.unregister(uid);
      } catch (e) {
        AppLogger.w('push unregister failed: $e');
      }
    }
    await _wipe();
  }

  Future<void> _wipe() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      AppLogger.w('cancelAll failed: $e');
    }
    try {
      await _meds.clear();
      await _flags.clear();
    } catch (e) {
      AppLogger.w('local wipe failed: $e');
    }
  }
}
