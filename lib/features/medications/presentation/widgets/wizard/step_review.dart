import 'package:flutter/material.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/localization/l10n_keys.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/glass_card.dart';
import '../../../../../core/widgets/info_row.dart';
import '../../../domain/entities/medication.dart';
import '../med_labels.dart';
import '../medication_avatar.dart';

/// Read-only summary, reused by the review step.
class StepReview extends StatelessWidget {
  const StepReview({super.key, required this.medication});
  final Medication medication;

  @override
  Widget build(BuildContext context) {
    final m = medication;
    final yes = context.tr(L.on), no = context.tr(L.off);
    final instructions = [
      if (m.meal != MealRelation.anytime) MedLabels.meal(context, m.meal),
      ...m.notes,
    ].join(' · ');
    return Column(children: [
      GlassCard(
        blur: 0,
        child: Column(children: [
          Row(children: [
            MedicationAvatar(imagePath: m.imagePath, size: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Text(m.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            ),
          ]),
          const Divider(height: 24),
          InfoRow(label: context.tr(L.treatmentType), value: MedLabels.type(context, m.type)),
          InfoRow(
            label: context.tr(L.period),
            value: m.endDate == null
                ? Fmt.date(context, m.startDate)
                : '${Fmt.date(context, m.startDate)} → ${Fmt.date(context, m.endDate!)}',
          ),
          InfoRow(label: context.tr(L.amountPerDose), value: MedLabels.dose(context, m)),
          InfoRow(label: context.tr(L.times), value: MedLabels.timesSummary(context, m)),
          InfoRow(label: context.tr(L.instructions), value: instructions.isEmpty ? '—' : instructions),
        ]),
      ),
      const SizedBox(height: 12),
      GlassCard(
        blur: 0,
        child: Column(children: [
          InfoRow(
              label: context.tr(L.currentStock),
              value: '${Fmt.number(context, m.remaining)} ${MedLabels.unit(context, m.unit)}'),
          InfoRow(label: context.tr(L.alertThreshold), value: Fmt.number(context, m.alertThreshold)),
          InfoRow(label: context.tr(L.enableReminders), value: m.remindersEnabled ? yes : no),
          InfoRow(label: context.tr(L.alarmSound), value: m.soundEnabled ? yes : no),
          InfoRow(label: context.tr(L.snoozeDuration), value: context.tr(L.minutesN, args: {'n': Fmt.number(context, m.snoozeMinutes)})),
        ]),
      ),
    ]);
  }
}
