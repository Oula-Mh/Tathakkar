import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/l10n_keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/status_chip.dart';

/// Simple composed illustrations (no image assets needed).
class OnboardingDosePreview extends StatelessWidget {
  const OnboardingDosePreview({super.key});

  @override
  Widget build(BuildContext context) => GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _PillBadge(size: 84),
            const SizedBox(height: 14),
            Text(context.tr(L.sampleMedName),
                style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(context.tr(L.sampleDose), style: TextStyle(color: context.inkSoftColor)),
            const SizedBox(height: 16),
            Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.turquoise,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(context.tr(L.tookMedicine),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
}

class OnboardingListPreview extends StatelessWidget {
  const OnboardingListPreview({super.key});

  @override
  Widget build(BuildContext context) {
    Widget row(String name, String time, String status, ChipTone tone) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            blur: 0,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const _PillBadge(size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      Text(time, style: TextStyle(color: context.inkSoftColor, fontSize: 13)),
                    ],
                  ),
                ),
                StatusChip(label: status, tone: tone),
              ],
            ),
          ),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row(context.tr(L.sampleMedName), '8:00', context.tr(L.doseTaken), ChipTone.success),
        row('Losartan', '14:00', context.tr(L.doseUpcoming), ChipTone.info),
        row(context.tr(L.sampleMedName), '20:00', context.tr(L.doseUpcoming), ChipTone.info),
      ],
    );
  }
}

class OnboardingFamilyPreview extends StatelessWidget {
  const OnboardingFamilyPreview({super.key});

  @override
  Widget build(BuildContext context) {
    Widget avatar(String letter, double size, Color color) => Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Text(letter,
              style: TextStyle(color: Colors.white, fontSize: size * 0.4, fontWeight: FontWeight.w800)),
        );
    return SizedBox(
      width: 260,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.25)),
          ),
          Positioned(top: 10, right: 20, child: avatar('A', 84, AppColors.turquoise)),
          Positioned(bottom: 10, left: 20, child: avatar('B', 96, AppColors.slateBlue)),
          Positioned(
            bottom: 50,
            right: 10,
            child: avatar('✓', 44, AppColors.success),
          ),
        ],
      ),
    );
  }
}

class _PillBadge extends StatelessWidget {
  const _PillBadge({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.iceBlue,
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
        child: Icon(Icons.medication_rounded, size: size * 0.55, color: AppColors.turquoise),
      );
}
