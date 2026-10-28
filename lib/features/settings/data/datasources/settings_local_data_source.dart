import '../../../../core/storage/local_storage.dart';
import '../../domain/entities/app_settings.dart';

class SettingsLocalDataSource {
  const SettingsLocalDataSource(this._storage);
  final LocalStorage _storage;
  static const _key = 'app_settings';

  AppSettings read() {
    final m = _storage.read<Map>(_key);
    if (m == null) return const AppSettings();
    const d = AppSettings();
    return AppSettings(
      languageCode: m['lang'] as String? ?? d.languageCode,
      darkMode: m['dark'] as bool? ?? d.darkMode,
      onboardingSeen: m['onboarding'] as bool? ?? d.onboardingSeen,
      notificationsPrompted: m['notifPrompted'] as bool? ?? d.notificationsPrompted,
      remindersEnabled: m['reminders'] as bool? ?? d.remindersEnabled,
      soundEnabled: m['sound'] as bool? ?? d.soundEnabled,
      speakEnabled: m['speak'] as bool? ?? d.speakEnabled,
      showImage: m['image'] as bool? ?? d.showImage,
      fullScreen: m['full'] as bool? ?? d.fullScreen,
      snoozeMinutes: m['snooze'] as int? ?? d.snoozeMinutes,
    );
  }

  Future<void> write(AppSettings s) => _storage.write(_key, {
        'lang': s.languageCode,
        'dark': s.darkMode,
        'onboarding': s.onboardingSeen,
        'notifPrompted': s.notificationsPrompted,
        'reminders': s.remindersEnabled,
        'sound': s.soundEnabled,
        'speak': s.speakEnabled,
        'image': s.showImage,
        'full': s.fullScreen,
        'snooze': s.snoozeMinutes,
      });
}
