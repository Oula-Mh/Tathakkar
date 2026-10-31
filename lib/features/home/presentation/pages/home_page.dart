import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/l10n_keys.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/circle_icon_button.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/now_builder.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../doses/domain/entities/scheduled_dose.dart';
import '../../../doses/domain/usecases/doses_usecases.dart';
import '../../../doses/presentation/bloc/doses_bloc.dart';
import '../../../medications/presentation/bloc/list/medications_bloc.dart';
import '../../../medications/presentation/widgets/med_labels.dart';
import '../../../medications/presentation/widgets/medication_avatar.dart';
import '../../../profiles/domain/entities/person_profile.dart';
import '../../../profiles/presentation/bloc/profiles_bloc.dart';
import '../../../reminders/domain/entities/reminder_payload.dart';
import '../widgets/dose_tile.dart';
import '../widgets/profile_switcher.dart';
import '../widgets/reminder_health_banner.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.select((ProfilesBloc b) => b.state.selected);
    final meds = context.watch<MedicationsBloc>().state;
    final doses = context.watch<DosesBloc>().state;

    return BlocListener<DosesBloc, DosesState>(
      listenWhen: (p, c) =>
          p.actionFailureKey != c.actionFailureKey &&
          c.actionFailureKey != null,
      listener: (context, s) => AppSnackbar.show(
        context,
        context.tr(s.actionFailureKey!),
        error: true,
      ),
      child: AppScaffold(
        strongBackground: true,
        titleWidget: const ProfileSwitcher(),

        scrollable: false,
        title: '',
        trailing: CircleIconButton(
          icon: Icons.notifications_none_rounded,
          tooltip: context.tr(L.notificationsTitle),
          onPressed: () => context.push(Routes.inbox),
        ),
        body: profile == null
            ? ListView(children: const [SizedBox(height: 16), SkeletonList()])
            // NowBuilder: dose status (upcoming -> due -> unconfirmed) follows the clock.
            : NowBuilder(
                builder: (context, now) =>
                    _body(context, profile, meds, doses, now),
              ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    PersonProfile profile,
    MedicationsState meds,
    DosesState doses,
    DateTime now,
  ) {
    if (meds.status == MedicationsStatus.failure) {
      return ErrorView(
        messageKey: meds.failureKey ?? 'err_unknown',
        onRetry: () => context.read<MedicationsBloc>().add(
          MedicationsWatchRequested(profile),
        ),
      );
    }
    if (meds.status == MedicationsStatus.failure) {
      return ErrorView(
        messageKey: meds.failureKey ?? 'err_unknown',
        onRetry: () => context.read<MedicationsBloc>().add(
          MedicationsWatchRequested(profile, force: true),
        ),
      );
    }

    final header = [
      // const ProfileSwitcher(),
      const SizedBox(height: 8),
      ProfileContextBanner(profile: profile),
      const SizedBox(height: 12),
      const ReminderHealthBanner(),
    ];

    if (meds.medications.isEmpty) {
      return ListView(
        children: [
          ...header,
          GlassCard(
            child: Column(
              children: [
                const SizedBox(height: 8),
                const Icon(
                  Icons.medication_rounded,
                  size: 56,
                  color: AppColors.turquoise,
                ),
                const SizedBox(height: 12),
                Text(
                  context.tr(L.homeEmptyTitle),
                  textAlign: TextAlign.center,
                  style: context.textStyles.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr(L.homeEmptySub),
                  textAlign: TextAlign.center,
                  style: TextStyle(height: 1.6, color: context.inkSoftColor),
                ),
                if (profile.canManageMedications) ...[
                  const SizedBox(height: 20),
                  AppButton(
                    label: context.tr(L.addMedication),
                    onPressed: () => context.push(Routes.medicationNew),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final (i, key) in [
                L.homeStep1,
                L.homeStep2,
                L.homeStep3,
              ].indexed)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GlassCard(
                      blur: 0,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 8,
                      ),
                      child: Column(
                        children: [
                          Text(
                            Fmt.number(context, i + 1),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.turquoise,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.tr(key),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      );
    }

    const builder = BuildDaySchedule();
    final today = builder(
      medications: meds.medications,
      logs: doses.logs,
      day: now.dateOnly,
      now: now,
    );
    final next = builder.next(today);
    final taken = today
        .where((d) => d.status == DoseDisplayStatus.taken)
        .length;
    final lowStock = meds.medications
        .where((m) => m.isLowStock || m.isOutOfStock)
        .toList();

    void confirm(ScheduledDose d) => context.read<DosesBloc>().add(
      DoseConfirmRequested(d.medication, d.scheduledAt),
    );

    return ListView(
      children: [
        ...header,
        // Progress
        GlassCard(
          blur: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      Fmt.dayHeader(context, now),
                      style: TextStyle(color: context.inkSoftColor),
                    ),
                  ),
                  Text(
                    context.tr(
                      L.dosesProgress,
                      args: {
                        'a': Fmt.number(context, taken),
                        'b': Fmt.number(context, today.length),
                      },
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: today.isEmpty ? 0 : taken / today.length,
                  minHeight: 10,
                  color: AppColors.turquoise,
                  backgroundColor: AppColors.platinum,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Next dose
        if (next != null)
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(L.nextDose),
                  style: TextStyle(fontSize: 13, color: context.inkSoftColor),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    MedicationAvatar(
                      imagePath: next.medication.imagePath,
                      size: 56,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            next.medication.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${Fmt.time(context, next.scheduledAt)} · ${MedLabels.dose(context, next.medication)}',
                            style: TextStyle(color: context.inkSoftColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                AppButton(
                  label: context.tr(L.tookMedicine),
                  icon: Icons.check_rounded,
                  isLoading: context.select(
                    (DosesBloc b) => b.state.confirming,
                  ),
                  onPressed: () => confirm(next),
                ),
                if (profile.remindsOnThisDevice)
                  TextButton(
                    onPressed: () => context.push(
                      Routes.reminderLocation(
                        ReminderPayload(
                          ownerUid: profile.ownerUid,
                          profileId: profile.profileId,
                          medicationId: next.medication.id,
                          minutesOfDay:
                              next.scheduledAt.hour * 60 +
                              next.scheduledAt.minute,
                        ).encode(),
                      ),
                    ),
                    child: Text(context.tr(L.openReminder)),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 18),
        Text(
          context.tr(L.todaySchedule),
          style: context.textStyles.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        if (today.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                context.tr(L.noDosesToday),
                style: TextStyle(color: context.inkSoftColor),
              ),
            ),
          ),
        for (final d in today)
          DoseTile(
            dose: d,
            onTap: d.status == DoseDisplayStatus.taken
                ? null
                : () => confirm(d),
          ),
        for (final m in lowStock)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: InkWell(
              onTap: () => context.push(Routes.medicationStock(m.id)),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: m.isOutOfStock
                      ? AppColors.dangerBg
                      : AppColors.warningBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: m.isOutOfStock
                          ? AppColors.danger
                          : AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.tr(
                          m.isOutOfStock ? L.homeOutBanner : L.homeLowBanner,
                          args: {
                            'med': m.name,
                            'n': Fmt.number(context, m.remaining),
                          },
                        ),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: m.isOutOfStock
                              ? AppColors.danger
                              : AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        // if (profile.canManageMedications) ...[
        //   const SizedBox(height: 12),
        //   AppButton(
        //     label: context.tr(L.addMedication),
        //     variant: AppButtonVariant.secondary,
        //     onPressed: () => context.push(Routes.medicationNew),
        //   ),
        // ],
      ],
    );
  }
}
