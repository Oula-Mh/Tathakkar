part of 'settings_bloc.dart';

class SettingsState extends Equatable {
  const SettingsState(this.settings);
  final AppSettings settings;

  Locale get locale => Locale(settings.languageCode);
  ThemeMode get themeMode => settings.darkMode ? ThemeMode.dark : ThemeMode.light;

  @override
  List<Object?> get props => [settings];
}
