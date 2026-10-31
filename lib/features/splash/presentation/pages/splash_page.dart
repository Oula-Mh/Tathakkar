import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/l10n_keys.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../widgets/capsule_icon.dart';

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
    // An alarm that opened the app must show its screen immediately.
    final fromAlarm = getIt<NotificationService>().hasLaunchTap;
    Future.delayed(Duration(milliseconds: fromAlarm ? 250 : 1800), () {
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
                const _AppLogo(),
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
class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 108,
      height: 108,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.ink.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: AppColors.ink.withValues(alpha: 0.45),
                  width: 1.5,
                ),
              ),
              child:  Center(
                child: CapsuleIcon(
                  width: 72,
                  height: 32,
                  angle: -0.85,
                  leftColor: AppColors.turquoise,
                  rightColor: AppColors.ink,
                ),
              ),
            ),
          ),
          Positioned(
            top: -10,
            right: -10,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.ink.withValues(alpha: 0.22),
                border: Border.all(
                  color: AppColors.ink.withValues(alpha: 0.85),
                  width: 1.8,
                ),
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 20,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}