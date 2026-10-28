import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';
import 'glass_card.dart';

abstract final class ConfirmDialog {
  /// Returns true when the user confirms.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black38,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: GlassCard(
          tint: ctx.isDark ? null : Colors.white.withValues(alpha: 0.92),
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: ctx.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text(message, style: TextStyle(fontSize: 15, height: 1.6, color: ctx.inkSoftColor)),
              const SizedBox(height: 22),
              AppButton(
                label: confirmLabel,
                variant: destructive ? AppButtonVariant.danger : AppButtonVariant.primary,
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
              const SizedBox(height: 10),
              AppButton(
                label: ctx.tr('cancel'),
                variant: AppButtonVariant.secondary,
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }
}
