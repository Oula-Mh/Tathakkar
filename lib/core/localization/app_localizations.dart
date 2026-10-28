import 'package:flutter/material.dart';

import '../utils/app_logger.dart';
import 'strings_ar.dart';
import 'strings_en.dart';

/// Lightweight localization: typed keys (see l10n_keys.dart) + two maps.
/// Missing keys fall back to English, then to the key itself.
class AppLocalizations {
  AppLocalizations(this.locale);
  final Locale locale;

  static const supportedLocales = [Locale('ar'), Locale('en')];
  static const delegate = _Delegate();

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  bool get isArabic => locale.languageCode == 'ar';

  String tr(String key, {Map<String, String> args = const {}}) {
    var text = (isArabic ? stringsAr[key] : stringsEn[key]) ?? stringsEn[key];
    if (text == null) {
      AppLogger.w('Missing translation: $key');
      return key;
    }
    args.forEach((k, v) => text = text!.replaceAll('{$k}', v));
    return text!;
  }
}

class _Delegate extends LocalizationsDelegate<AppLocalizations> {
  const _Delegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.any((l) => l.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}

extension L10nX on BuildContext {
  /// Usage: context.tr(L.login)  or  context.tr(L.dosesCount, args: {'n': '3'})
  String tr(String key, {Map<String, String> args = const {}}) =>
      AppLocalizations.of(this).tr(key, args: args);

  bool get isArabic => AppLocalizations.of(this).isArabic;
}
