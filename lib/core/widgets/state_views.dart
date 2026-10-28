import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';
import 'icon_badge.dart';

/// Centered illustration + title + message + optional action.
/// Used for empty, error, offline and success states.
class MessageView extends StatelessWidget {
  const MessageView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconBadge(icon: icon, color: iconColor),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (message != null) ...[
                const SizedBox(height: 10),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, height: 1.6, color: context.inkSoftColor),
                ),
              ],
              if (actionLabel != null) ...[
                const SizedBox(height: 28),
                AppButton(label: actionLabel!, onPressed: onAction),
              ],
              if (secondaryLabel != null) ...[
                const SizedBox(height: 12),
                AppButton(
                  label: secondaryLabel!,
                  onPressed: onSecondary,
                  variant: AppButtonVariant.secondary,
                ),
              ],
            ],
          ),
        ),
      );
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.messageKey, this.onRetry});
  final String messageKey;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => MessageView(
        icon: Icons.error_outline_rounded,
        title: context.tr('err_title'),
        message: context.tr(messageKey),
        actionLabel: onRetry == null ? null : context.tr('retry'),
        onAction: onRetry,
      );
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator());
}

/// Skeleton cards used while the first list is loading.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 3});
  final int count;

  @override
  Widget build(BuildContext context) => Column(
        children: List.generate(
          count,
          (_) => Container(
            height: 84,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      );
}
