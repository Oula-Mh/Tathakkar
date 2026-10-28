import 'package:flutter/material.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/localization/l10n_keys.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/formatters.dart';

/// Numbered step indicator (info, dose, stock, reminders, review).
class WizardSteps extends StatelessWidget {
  const WizardSteps({super.key, required this.current, required this.onTapStep});
  final int current;
  final ValueChanged<int> onTapStep;

  static const _labels = [L.stepInfo, L.stepDose, L.stepStock, L.stepReminders, L.stepReview];

  @override
  Widget build(BuildContext context) => Row(
        children: List.generate(_labels.length, (i) {
          final done = i < current;
          final active = i == current;
          final color = done || active ? AppColors.turquoise : AppColors.platinum;
          return Expanded(
            child: InkWell(
              onTap: done ? () => onTapStep(i) : null,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: active ? color : (done ? color.withValues(alpha: 0.2) : Colors.white70),
                    child: done
                        ? const Icon(Icons.check, size: 16, color: AppColors.turquoise)
                        : Text(Fmt.number(context, i + 1),
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: active ? Colors.white : context.inkSoftColor)),
                  ),
                  const SizedBox(height: 4),
                  Text(context.tr(_labels[i]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                          color: active ? context.primaryColor : context.inkSoftColor)),
                ],
              ),
            ),
          );
        }),
      );
}
