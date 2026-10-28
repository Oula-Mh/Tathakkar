import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

enum ChipTone { success, warning, danger, neutral, info }

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, this.tone = ChipTone.neutral, this.icon});
  final String label;
  final ChipTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    final (bg, fg) = switch (tone) {
      ChipTone.success => (AppColors.successBg, AppColors.success),
      ChipTone.warning => (AppColors.warningBg, AppColors.warning),
      ChipTone.danger => (AppColors.dangerBg, AppColors.danger),
      ChipTone.info => (AppColors.iceBlue, AppColors.turquoise),
      ChipTone.neutral => (
          dark ? Colors.white12 : AppColors.platinum.withValues(alpha: 0.7),
          context.inkSoftColor
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: fg), const SizedBox(width: 4)],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: fg),
            ),
          ),
        ],
      ),
    );
  }
}
