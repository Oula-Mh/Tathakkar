import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/l10n_keys.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_background.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Minimum branding time; the router then decides where to go.
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) getIt<AppRouter>().markSplashDone();
    });
  }

  @override
  Widget build(BuildContext context) => GradientBackground(
        strong: true,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogo(size: 110),
                const SizedBox(height: 20),
                Text(
                  context.tr(L.appName),
                  style: context.textStyles.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'TATHAKKAR',
                  style: TextStyle(
                    letterSpacing: 4,
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

/// App mark: glass square with a pill and a check badge.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 88});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(size * 0.3),
                border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1.4),
              ),
              child: Icon(Icons.medication_rounded, size: size * 0.5, color: Colors.white),
            ),
            PositionedDirectional(
              top: -6,
              end: -6,
              child: Container(
                width: size * 0.3,
                height: size * 0.3,
                decoration: const BoxDecoration(color: AppColors.turquoise, shape: BoxShape.circle),
                child: Icon(Icons.check, size: size * 0.18, color: Colors.white),
              ),
            ),
          ],
        ),
      );
}
