import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/l10n_keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../domain/entities/reminder_health.dart';
import '../bloc/health/reminder_health_bloc.dart';

/// "Alarm status": shows exactly what is missing and fixes it with one tap.
class ReminderHealthPage extends StatelessWidget {
  const ReminderHealthPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.read<SettingsBloc>().state.settings.languageCode;
    final bloc = context.read<ReminderHealthBloc>()..add(const HealthRefreshed());

    return BlocConsumer<ReminderHealthBloc, ReminderHealthState>(
      listenWhen: (p, c) => p.messageSeq != c.messageSeq && c.messageKey != null,
      listener: (context, s) => AppSnackbar.show(context, context.tr(s.messageKey!),
          error: s.messageKey == 'err_test_failed'),
      builder: (context, s) {
        final h = s.health;
        return AppScaffold(
          showBack: true,
          title: context.tr(L.healthTitle),
          body: h == null
              ? const SizedBox(height: 300, child: LoadingView())
              : Column(children: [
                  _Summary(ok: h.isOk),
                  const SizedBox(height: 12),
                  _Row(
                    title: context.tr(L.healthNotifications),
                    hint: context.tr(L.healthNotificationsHint),
                    ok: h.notificationsGranted,
                    onFix: () => bloc.add(const HealthFixRequested(HealthItem.notifications)),
                  ),
                  if (h.isAndroid) ...[
                    _Row(
                      title: context.tr(L.healthExactAlarms),
                      hint: context.tr(L.healthExactAlarmsHint),
                      ok: h.exactAlarmsGranted,
                      onFix: () => bloc.add(const HealthFixRequested(HealthItem.exactAlarms)),
                    ),
                    _Row(
                      title: context.tr(L.healthFullScreen),
                      hint: context.tr(L.healthFullScreenHint),
                      ok: null, // Android gives no way to read this state
                      onFix: () => bloc.add(const HealthFixRequested(HealthItem.fullScreen)),
                    ),
                    _Row(
                      title: context.tr(L.healthBattery),
                      hint: context.tr(L.healthBatteryHint),
                      ok: h.batteryOptimizationIgnored,
                      onFix: () => bloc.add(const HealthFixRequested(HealthItem.battery)),
                    ),
                  ],
                  GlassCard(
                    blur: 0,
                    child: Row(children: [
                      const Icon(Icons.alarm_on_rounded, color: AppColors.turquoise),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          context.tr(L.healthScheduledCount,
                              args: {'n': Fmt.number(context, h.pendingDoseAlarms)}),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: context.tr(L.healthTestIn10),
                    icon: Icons.timer_outlined,
                    onPressed: () => bloc.add(HealthTestScheduled(lang)),
                  ),
                  const SizedBox(height: 10),
                  AppButton(
                    label: context.tr(L.healthTestNow),
                    variant: AppButtonVariant.secondary,
                    onPressed: () => bloc.add(HealthTestShownNow(lang)),
                  ),
                  const SizedBox(height: 12),
                  Text(context.tr(L.healthTestHint),
                      style: TextStyle(fontSize: 13, height: 1.6, color: context.inkSoftColor)),
                ]),
        );
      },
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.ok});
  final bool ok;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ok ? AppColors.successBg : AppColors.warningBg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(children: [
          Icon(ok ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
              color: ok ? AppColors.success : AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.tr(ok ? L.healthAllGood : L.healthNeedsAttention),
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: ok ? AppColors.success : AppColors.warning),
            ),
          ),
        ]),
      );
}

class _Row extends StatelessWidget {
  const _Row({required this.title, required this.hint, required this.ok, required this.onFix});
  final String title;
  final String hint;

  /// null = cannot be detected (shows only the action button).
  final bool? ok;
  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GlassCard(
          blur: 0,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(
                ok == null
                    ? Icons.info_outline_rounded
                    : (ok! ? Icons.check_circle_rounded : Icons.cancel_rounded),
                color: ok == null ? AppColors.slateBlue : (ok! ? AppColors.success : AppColors.danger),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ]),
            const SizedBox(height: 6),
            Text(hint, style: TextStyle(fontSize: 13.5, height: 1.5, color: context.inkSoftColor)),
            if (ok != true) ...[
              const SizedBox(height: 10),
              AppButton(
                label: context.tr(L.healthFix),
                variant: AppButtonVariant.secondary,
                height: 44,
                onPressed: onFix,
              ),
            ],
          ]),
        ),
      );
}
