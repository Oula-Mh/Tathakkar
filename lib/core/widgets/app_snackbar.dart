import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

abstract final class AppSnackbar {
  static void show(BuildContext context, String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.danger : AppColors.ink,
      ));
  }
}
