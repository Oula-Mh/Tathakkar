import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// "+  2  −" control from the design. Large touch targets for seniors.
class NumberStepper extends StatelessWidget {
  const NumberStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 999,
    this.step = 1,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final int step;

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData icon, bool enabled, VoidCallback onTap, {bool filled = false}) =>
        Material(
          color: filled ? AppColors.turquoise : Colors.white.withValues(alpha: 0.9),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: enabled ? onTap : null,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                icon,
                color: !enabled
                    ? AppColors.platinum
                    : filled
                        ? Colors.white
                        : AppColors.ink,
              ),
            ),
          ),
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn(Icons.add, value + step <= max, () => onChanged(value + step), filled: true),
        SizedBox(
          width: 64,
          child: Text(
            Fmt.number(context, value),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: context.inkColor),
          ),
        ),
        btn(Icons.remove, value - step >= min, () => onChanged(value - step)),
      ],
    );
  }
}
