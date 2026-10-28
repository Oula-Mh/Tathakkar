import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static const fontFamily = 'Cairo';

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final isDark = b == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.turquoise,
      brightness: b,
    ).copyWith(
      primary: isDark ? AppColors.glacier : AppColors.turquoise,
      onPrimary: isDark ? AppColors.darkBg1 : Colors.white,
      surface: isDark ? AppColors.darkSurface : Colors.white,
      error: AppColors.danger,
    );
    final text = isDark ? Colors.white : AppColors.ink;
    final base = ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: Colors.transparent,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: fontFamily,
        bodyColor: text,
        displayColor: text,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      dividerColor: AppColors.glacier.withValues(alpha: 0.5),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? AppColors.turquoise
                : AppColors.platinum),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(
            fontFamily: fontFamily, color: Colors.white, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

/// Theme-aware helpers so widgets never hard-code colors.
extension ThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get inkColor => isDark ? Colors.white : AppColors.ink;
  Color get inkSoftColor => isDark ? AppColors.glacier : AppColors.inkSoft;
  Color get primaryColor => Theme.of(this).colorScheme.primary;
  TextTheme get textStyles => Theme.of(this).textTheme;
}
