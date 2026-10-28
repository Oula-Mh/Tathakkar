import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Rounded glass square holding an icon (hero of empty/error/success screens).
class IconBadge extends StatelessWidget {
  const IconBadge({super.key, required this.icon, this.size = 88, this.color});
  final IconData icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: context.isDark ? 0.12 : 0.8),
          borderRadius: BorderRadius.circular(size * 0.3),
          border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
          boxShadow: [
            BoxShadow(
              color: AppColors.turquoise.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Icon(icon, size: size * 0.45, color: color ?? context.primaryColor),
      );
}
