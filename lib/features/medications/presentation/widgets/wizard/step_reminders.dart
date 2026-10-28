import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/localization/l10n_keys.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/glass_card.dart';
import '../../../../../core/widgets/switch_row.dart';
import '../../bloc/form/medication_form_bloc.dart';

class StepReminders extends StatelessWidget {
  const StepReminders({super.key, required this.state});
  final MedicationFormState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<MedicationFormBloc>();
    final d = state.draft;
    final on = d.remindersEnabled;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GlassCard(
        blur: 0,
        child: Column(children: [
          SwitchRow(
            label: context.tr(L.enableReminders),
            value: on,
            onChanged: (v) => bloc.add(MedReminderPrefsChanged(remindersEnabled: v)),
          ),
          SwitchRow(
            label: context.tr(L.alarmSound),
            value: d.soundEnabled,
            onChanged: on ? (v) => bloc.add(MedReminderPrefsChanged(soundEnabled: v)) : null,
          ),
          SwitchRow(
            label: context.tr(L.speakNameAndInstructions),
            value: d.speakEnabled,
            onChanged: on ? (v) => bloc.add(MedReminderPrefsChanged(speakEnabled: v)) : null,
          ),
          SwitchRow(
            label: context.tr(L.showMedicationPhoto),
            value: d.showImage,
            onChanged: on ? (v) => bloc.add(MedReminderPrefsChanged(showImage: v)) : null,
          ),
          SwitchRow(
            label: context.tr(L.fullScreenAlert),
            subtitle: context.tr(L.fullScreenAlertHint),
            value: d.fullScreen,
            onChanged: on ? (v) => bloc.add(MedReminderPrefsChanged(fullScreen: v)) : null,
          ),
        ]),
      ),
      const SizedBox(height: 14),
      GlassCard(
        blur: 0,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(context.tr(L.snoozeDuration),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: [
            for (final m in BusinessRules.snoozeOptions)
              ChoiceChip(
                label: Text(context.tr(L.minutesN, args: {'n': Fmt.number(context, m)})),
                selected: d.snoozeMinutes == m,
                onSelected: on ? (_) => bloc.add(MedReminderPrefsChanged(snoozeMinutes: m)) : null,
              ),
          ]),
          const SizedBox(height: 8),
          Text(context.tr(L.snoozeNote),
              style: TextStyle(fontSize: 12.5, color: context.inkSoftColor)),
        ]),
      ),
    ]);
  }
}
