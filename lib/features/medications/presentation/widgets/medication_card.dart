import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../domain/entities/medication.dart';
import 'med_labels.dart';
import 'medication_avatar.dart';

class MedicationCard extends StatelessWidget {
  const MedicationCard({super.key, required this.medication, required this.onTap});
  final Medication medication;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m = medication;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        blur: 0,
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            MedicationAvatar(imagePath: m.imagePath, size: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                    '${MedLabels.dose(context, m)} · ${MedLabels.timesSummary(context, m)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: context.inkSoftColor),
                  ),
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    StatusChip(label: MedLabels.type(context, m.type), tone: ChipTone.info),
                    MedLabels.stockChip(context, m),
                  ]),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.inkSoftColor),
          ],
        ),
      ),
    );
  }
}
