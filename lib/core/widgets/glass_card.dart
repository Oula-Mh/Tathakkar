import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Moderate glassmorphism card. Set [blur] to 0 for long lists (cheaper).
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
    this.blur = 14,
    this.onTap,
    this.borderColor,
    this.tint,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    final fill = tint ??
        (dark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.66));
    final border = borderColor ??
        (dark ? Colors.white.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.85));
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.turquoise.withValues(alpha: dark ? 0.0 : 0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );

    Widget card = blur > 0
        ? ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: content,
            ),
          )
        : content;

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: card,
        ),
      );
    }
    return card;
  }
}
