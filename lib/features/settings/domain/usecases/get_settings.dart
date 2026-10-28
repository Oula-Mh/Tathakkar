import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

class GetSettings {
  const GetSettings(this._repo);
  final SettingsRepository _repo;
  AppSettings call() => _repo.load();
}
