import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Soft gradient + subtle bubbles used behind every screen.
class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child, this.strong = false});
  final Widget child;

  /// Stronger teal at the top (splash / reminder).
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    final colors = dark
        ? const [AppColors.darkBg2, AppColors.darkBg1]
        : strong
            ? const [AppColors.slateBlue, AppColors.glacier, AppColors.iceBlue]
            : const [AppColors.glacier, AppColors.iceBlue, Color(0xFFEAF4F8)];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
      child: Stack(
        children: [
          const Positioned(top: -80, right: -60, child: _Bubble(240, 0.18)),
          const Positioned(top: 220, left: -90, child: _Bubble(200, 0.12)),
          const Positioned(bottom: -70, right: -40, child: _Bubble(220, 0.14)),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble(this.size, this.opacity);
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              Colors.white.withValues(alpha: opacity),
              Colors.white.withValues(alpha: 0),
            ]),
          ),
        ),
      );
}

/// Marks that an ancestor (e.g. the main shell) already paints the gradient,
/// so nested AppScaffolds stay transparent and the bottom bar blends in.
class BackgroundScope extends InheritedWidget {
  const BackgroundScope({super.key, required super.child});

  static bool exists(BuildContext context) =>
      context.getInheritedWidgetOfExactType<BackgroundScope>() != null;

  @override
  bool updateShouldNotify(BackgroundScope oldWidget) => false;
}
