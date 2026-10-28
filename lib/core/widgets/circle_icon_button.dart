import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 44,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip ?? '',
        child: Material(
          color: Colors.white.withValues(alpha: context.isDark ? 0.12 : 0.85),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(icon, size: size * 0.5, color: context.inkColor),
            ),
          ),
        ),
      );
}
