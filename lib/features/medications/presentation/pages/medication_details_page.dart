import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/l10n_keys.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/info_row.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../profiles/presentation/bloc/profiles_bloc.dart';
import '../bloc/list/medications_bloc.dart';
import '../../domain/entities/medication.dart';
import '../widgets/med_labels.dart';
import '../widgets/medication_avatar.dart';

class MedicationDetailsPage extends StatelessWidget {
  const MedicationDetailsPage({super.key, required this.medicationId});
  final String medicationId;

  @override
  Widget build(BuildContext context) {
    final canManage = context.select((ProfilesBloc b) => b.state.selected?.canManageMedications ?? false);
    return BlocConsumer<MedicationsBloc, MedicationsState>(
      listenWhen: (p, c) => p.deletedCount != c.deletedCount || p.actionFailureKey != c.actionFailureKey,
      listener: (context, s) {
        if (s.actionFailureKey != null) {
          AppSnackbar.show(context, context.tr(s.actionFailureKey!), error: true);
        } else if (s.byId(medicationId) == null) {
          AppSnackbar.show(context, context.tr(L.medDeleted));
          if (context.canPop()) context.pop();
        }
      },
      builder: (context, s) {
        final m = s.byId(medicationId);
        if (m == null) {
          return const AppScaffold(
              showBack: true, scrollable: false, body: ErrorView(messageKey: 'err_not_found'));
        }
        final ended = m.isCourseEnded(DateTime.now());
        final instructions = [
          if (m.meal != MealRelation.anytime) MedLabels.meal(context, m.meal),
          ...m.notes,
        ].join(' · ');
        return AppScaffold(
          showBack: true,
          title: context.tr(L.medicationDetails),
          bottom: canManage
              ? Column(mainAxisSize: MainAxisSize.min, children: [
                  AppButton(
                    label: context.tr(L.editMedication),
                    onPressed: () => context.push(Routes.medicationEdit(m.id)),
                  ),
                  const SizedBox(height: 8),
                  AppButton(
                    label: context.tr(L.deleteMedication),
                    variant: AppButtonVariant.secondary,
                    onPressed: () async {
                      final bloc = context.read<MedicationsBloc>();
                      final ok = await ConfirmDialog.show(
                        context,
                        title: context.tr(L.deleteMedTitle),
                        message: context.tr(L.deleteMedMessage),
                        confirmLabel: context.tr(L.deleteMedication),
                        destructive: true,
                      );
                      if (ok) bloc.add(MedicationDeleteRequested(m.id));
                    },
                  ),
                ])
              : null,
          body: Column(children: [
            GlassCard(
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      StatusChip(label: MedLabels.type(context, m.type), tone: ChipTone.info),
                      if (ended) StatusChip(label: context.tr(L.courseEnded), tone: ChipTone.neutral),
                    ]),
                  ]),
                ),
                MedicationAvatar(imagePath: m.imagePath, size: 64),
              ]),
            ),
            const SizedBox(height: 12),
            GlassCard(
              blur: 0,
              child: Column(children: [
                InfoRow(label: context.tr(L.times), value: MedLabels.timesSummary(context, m)),
                InfoRow(label: context.tr(L.amountPerDose), value: MedLabels.dose(context, m)),
                InfoRow(label: context.tr(L.instructions), value: instructions.isEmpty ? '—' : instructions),
                InfoRow(label: context.tr(L.treatmentType), value: MedLabels.type(context, m.type)),
                InfoRow(label: context.tr(L.startDate), value: Fmt.date(context, m.startDate)),
                if (m.endDate != null)
                  InfoRow(label: context.tr(L.endDate), value: Fmt.date(context, m.endDate!)),
              ]),
            ),
            const SizedBox(height: 12),
            GlassCard(
              blur: 0,
              child: Column(children: [
                InfoRow(label: context.tr(L.enableReminders), value: context.tr(m.remindersEnabled ? L.on : L.off)),
                InfoRow(label: context.tr(L.alarmSound), value: context.tr(m.soundEnabled ? L.on : L.off)),
                InfoRow(label: context.tr(L.speakNameAndInstructions), value: context.tr(m.speakEnabled ? L.on : L.off)),
                InfoRow(label: context.tr(L.showMedicationPhoto), value: context.tr(m.showImage ? L.on : L.off)),
                InfoRow(label: context.tr(L.fullScreenAlert), value: context.tr(m.fullScreen ? L.on : L.off)),
                InfoRow(
                    label: context.tr(L.snoozeDuration),
                    value: context.tr(L.minutesN, args: {'n': Fmt.number(context, m.snoozeMinutes)})),
              ]),
            ),
            const SizedBox(height: 12),
            GlassCard(
              blur: 0,
              onTap: () => context.push(Routes.medicationStock(m.id)),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(context.tr(L.stock), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    MedLabels.stockChip(context, m),
                  ]),
                ),
                Text(context.tr(L.stockDetails),
                    style: TextStyle(color: context.primaryColor, fontWeight: FontWeight.w700)),
                Icon(Icons.chevron_right_rounded, color: context.primaryColor),
              ]),
            ),
          ]),
        );
      },
    );
  }
}
