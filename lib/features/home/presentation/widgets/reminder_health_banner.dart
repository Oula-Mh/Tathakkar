import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/l10n_keys.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../reminders/presentation/bloc/health/reminder_health_bloc.dart';

/// Appears on the home screen when alarms cannot ring reliably.
class ReminderHealthBanner extends StatelessWidget {
  const ReminderHealthBanner({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<ReminderHealthBloc, ReminderHealthState>(
        builder: (context, s) {
          if (!s.needsAttention) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => context.push(Routes.reminderHealth),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(children: [
                  const Icon(Icons.alarm_off_rounded, color: AppColors.warning),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.tr(L.healthBanner),
                      style: const TextStyle(
                          color: AppColors.warning, fontWeight: FontWeight.w700, height: 1.4),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.warning),
                ]),
              ),
            ),
          );
        },
      );
}
