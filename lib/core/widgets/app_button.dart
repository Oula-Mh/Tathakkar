import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, danger, ghost }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expand = true,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    final (bg, fg, border) = switch (variant) {
      AppButtonVariant.primary => (
          dark ? AppColors.glacier : AppColors.turquoise,
          dark ? AppColors.darkBg1 : Colors.white,
          Colors.transparent
        ),
      AppButtonVariant.secondary => (
          Colors.white.withValues(alpha: dark ? 0.12 : 0.95),
          dark ? Colors.white : AppColors.ink,
          Colors.transparent
        ),
      AppButtonVariant.danger => (AppColors.danger, Colors.white, Colors.transparent),
      AppButtonVariant.ghost => (
          Colors.transparent,
          dark ? Colors.white : AppColors.turquoise,
          Colors.transparent
        ),
    };
    final enabled = onPressed != null && !isLoading;
    final button = Opacity(
      opacity: onPressed == null && !isLoading ? 0.5 : 1,
      child: Material(
        color: bg,
        elevation: 0,
        shape: StadiumBorder(side: BorderSide(color: border)),
        shadowColor: AppColors.turquoise,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: enabled ? onPressed : null,
          child: Container(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            alignment: Alignment.center,
            child: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: fg),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: fg, size: 22),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: fg,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
