import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/l10n_keys.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../doses/domain/entities/scheduled_dose.dart';
import '../../../medications/presentation/widgets/med_labels.dart';
import '../../../medications/presentation/widgets/medication_avatar.dart';

class DoseTile extends StatelessWidget {
  const DoseTile({super.key, required this.dose, this.onTap});
  final ScheduledDose dose;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (label, tone, icon) = switch (dose.status) {
      DoseDisplayStatus.taken => (
        L.doseTaken,
        ChipTone.success,
        Icons.check_rounded,
      ),
      DoseDisplayStatus.due => (
        L.doseDue,
        ChipTone.warning,
        Icons.notifications_active_outlined,
      ),
      DoseDisplayStatus.unconfirmed => (
        L.doseUnconfirmed,
        ChipTone.danger,
        Icons.priority_high_rounded,
      ),
      DoseDisplayStatus.upcoming => (
        L.doseUpcoming,
        ChipTone.info,
        Icons.schedule_rounded,
      ),
    };
    final m = dose.medication;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        blur: 0,
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            MedicationAvatar(imagePath: m.imagePath, size: 42),

            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${Fmt.time(context, dose.scheduledAt)} · ${MedLabels.dose(context, m)}',
                    style: TextStyle(fontSize: 13, color: context.inkSoftColor),
                  ),
                ],
              ),
            ),
            StatusChip(label: context.tr(label), tone: tone, icon: icon),
          ],
        ),
      ),
    );
  }
}
