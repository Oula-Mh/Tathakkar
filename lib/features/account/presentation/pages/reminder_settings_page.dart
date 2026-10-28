import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/l10n_keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/switch_row.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';

class ReminderSettingsPage extends StatelessWidget {
  const ReminderSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsBloc>().state.settings;
    final bloc = context.read<SettingsBloc>();
    final on = s.remindersEnabled;
    return AppScaffold(
      showBack: true,
      title: context.tr(L.reminderSettings),
      body: Column(children: [
        GlassCard(
          blur: 0,
          child: Column(children: [
            SwitchRow(
              label: context.tr(L.enableReminders),
              subtitle: context.tr(L.enableRemindersGlobalHint),
              value: on,
              onChanged: (v) => bloc.add(ReminderPrefsChanged(remindersEnabled: v)),
            ),
            SwitchRow(label: context.tr(L.alarmSound), value: s.soundEnabled,
                onChanged: on ? (v) => bloc.add(ReminderPrefsChanged(soundEnabled: v)) : null),
            SwitchRow(label: context.tr(L.speakNameAndInstructions), value: s.speakEnabled,
                onChanged: on ? (v) => bloc.add(ReminderPrefsChanged(speakEnabled: v)) : null),
            SwitchRow(label: context.tr(L.showMedicationPhoto), value: s.showImage,
                onChanged: on ? (v) => bloc.add(ReminderPrefsChanged(showImage: v)) : null),
            SwitchRow(label: context.tr(L.fullScreenAlert), value: s.fullScreen,
                onChanged: on ? (v) => bloc.add(ReminderPrefsChanged(fullScreen: v)) : null),
          ]),
        ),
        const SizedBox(height: 12),
        GlassCard(
          blur: 0,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.tr(L.snoozeDuration), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, children: [
              for (final m in BusinessRules.snoozeOptions)
                ChoiceChip(
                  label: Text(context.tr(L.minutesN, args: {'n': Fmt.number(context, m)})),
                  selected: s.snoozeMinutes == m,
                  onSelected: (_) => bloc.add(ReminderPrefsChanged(snoozeMinutes: m)),
                ),
            ]),
            const SizedBox(height: 8),
            Text(context.tr(L.defaultsNote), style: TextStyle(fontSize: 12.5, color: context.inkSoftColor)),
          ]),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.tr(L.fullScreenNeedsPermission),
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.warning)),
            const SizedBox(height: 4),
            Text(context.tr(L.fullScreenNeedsPermissionSub),
                style: const TextStyle(color: AppColors.warning, height: 1.5)),
            const SizedBox(height: 10),
            AppButton(
              label: context.tr(L.openPhoneSettings),
              variant: AppButtonVariant.secondary,
              height: 46,
              onPressed: openAppSettings,
            ),
          ]),
        ),
      ]),
    );
  }
}
