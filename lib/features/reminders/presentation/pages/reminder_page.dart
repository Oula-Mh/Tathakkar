import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/l10n_keys.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/alarm_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../medications/domain/entities/medication.dart';
import '../../../medications/presentation/widgets/med_labels.dart';
import '../../../medications/presentation/widgets/medication_avatar.dart';
import '../../../profiles/presentation/bloc/profiles_bloc.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../domain/entities/reminder_payload.dart';
import '../bloc/reminder_bloc.dart';

/// Full-screen, senior-friendly dose reminder.
class ReminderPage extends StatelessWidget {
  const ReminderPage({super.key, required this.rawPayload});
  final String rawPayload;

  @override
  Widget build(BuildContext context) {
    final payload = ReminderPayload.tryParse(rawPayload);
    if (payload == null) {
      return const AppScaffold(showBack: true, scrollable: false, body: ErrorView(messageKey: 'err_not_found'));
    }
    final settings = context.read<SettingsBloc>().state.settings;
    final profileName = context
            .read<ProfilesBloc>()
            .state
            .profiles
            .where((p) => p.ownerUid == payload.ownerUid && p.profileId == payload.profileId)
            .map((p) => p.name)
            .firstOrNull ??
        '';
    return BlocProvider(
      create: (_) => getIt<ReminderBloc>()
        ..add(ReminderOpened(payload, languageCode: settings.languageCode, profileName: profileName)),
      child: _ReminderView(profileName: profileName),
    );
  }
}

class _ReminderView extends StatefulWidget {
  const _ReminderView({required this.profileName});
  final String profileName;

  @override
  State<_ReminderView> createState() => _ReminderViewState();
}

class _ReminderViewState extends State<_ReminderView> {
  final _alarm = getIt<AlarmService>();
  bool _alarmStarted = false;

  @override
  void dispose() {
    _alarm.stop();
    super.dispose();
  }

  void _startAlarm(Medication m) {
    if (_alarmStarted) return;
    _alarmStarted = true;
    final lang = context.read<SettingsBloc>().state.settings.languageCode;
    if (m.soundEnabled) _alarm.startSound();
    if (m.speakEnabled) {
      final who = widget.profileName.isEmpty ? '' : '${widget.profileName}. ';
      final instr = [if (m.meal != MealRelation.anytime) MedLabels.meal(context, m.meal), ...m.notes].join('. ');
      _alarm.speak('$who${m.name}. $instr', lang);
    }
  }

  void _close() {
    _alarm.stop();
    context.canPop() ? context.pop() : context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<ReminderBloc, ReminderState>(
        listener: (context, s) {
          if (s.status == ReminderStatus.ready && s.medication != null) _startAlarm(s.medication!);
          if (s.actionFailureKey != null) {
            AppSnackbar.show(context, context.tr(s.actionFailureKey!), error: true);
          }
          if (s.status == ReminderStatus.taken || s.status == ReminderStatus.snoozed) _alarm.stop();
        },
        builder: (context, s) {
          if (s.status == ReminderStatus.loading) {
            return const AppScaffold(scrollable: false, body: LoadingView());
          }
          if (s.status == ReminderStatus.failure) {
            return AppScaffold(
              showBack: true,
              onBack: _close,
              scrollable: false,
              body: ErrorView(messageKey: s.failureKey ?? 'err_not_found'),
            );
          }
          if (s.status == ReminderStatus.taken || s.status == ReminderStatus.snoozed) {
            final taken = s.status == ReminderStatus.taken;
            return AppScaffold(
              scrollable: false,
              body: MessageView(
                icon: taken ? Icons.check_rounded : Icons.schedule_rounded,
                title: context.tr(taken ? L.doseConfirmed : L.snoozed),
                message: taken
                    ? null
                    : context.tr(L.snoozedSub, args: {
                        'n': Fmt.number(context, s.medication?.snoozeMinutes ?? 10),
                      }),
                actionLabel: context.tr(L.backToHome),
                onAction: _close,
              ),
            );
          }

          final m = s.medication!;
          final at = s.scheduledAt!;
          final working = s.status == ReminderStatus.working;
          final (phaseLabel, phaseTone) = switch (s.phase) {
            ReminderPhase.due => (L.reminderDue, ChipTone.info),
            ReminderPhase.again => (L.reminderAgain, ChipTone.warning),
            ReminderPhase.finalCall => (L.reminderFinal, ChipTone.danger),
          };
          final settings = context.read<SettingsBloc>().state.settings;

          return AppScaffold(
            strongBackground: true,
            scrollable: false,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            bottom: Column(mainAxisSize: MainAxisSize.min, children: [
              AppButton(
                label: context.tr(L.tookMedicine),
                icon: Icons.check_rounded,
                height: 62,
                isLoading: working,
                onPressed: () => context.read<ReminderBloc>().add(const ReminderTakenPressed()),
              ),
              const SizedBox(height: 10),
              if (s.canSnooze)
                AppButton(
                  label: context.tr(L.remindLater, args: {'n': Fmt.number(context, m.snoozeMinutes)}),
                  icon: Icons.schedule_rounded,
                  variant: AppButtonVariant.secondary,
                  onPressed: working ? null : () => context.read<ReminderBloc>().add(const ReminderSnoozePressed()),
                )
              else
                AppButton(
                  label: context.tr(L.close),
                  variant: AppButtonVariant.secondary,
                  onPressed: _close,
                ),
            ]),
            body: Column(children: [
              const SizedBox(height: 24),
              Center(child: StatusChip(label: context.tr(s.isUnconfirmed ? L.doseUnconfirmed : phaseLabel), tone: s.isUnconfirmed ? ChipTone.danger : phaseTone)),
              const SizedBox(height: 12),
              Text(Fmt.time(context, at),
                  style: const TextStyle(fontSize: 54, fontWeight: FontWeight.w800, color: Colors.white)),
              Text(
                widget.profileName.isEmpty
                    ? context.tr(L.doseForYou)
                    : context.tr(L.doseForPerson, args: {'name': widget.profileName}),
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 24),
              GlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  if (settings.showImage && m.showImage)
                    MedicationAvatar(imagePath: m.imagePath, size: 120)
                  else
                    const SizedBox(height: 8),
                  const SizedBox(height: 16),
                  Text(m.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
                    StatusChip(label: MedLabels.dose(context, m), tone: ChipTone.info),
                    if (m.meal != MealRelation.anytime)
                      StatusChip(label: MedLabels.meal(context, m.meal), tone: ChipTone.neutral),
                    for (final n in m.notes) StatusChip(label: n, tone: ChipTone.neutral),
                  ]),
                  if (s.isUnconfirmed) ...[
                    const SizedBox(height: 12),
                    Text(context.tr(L.unconfirmedNote),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13.5, color: context.inkSoftColor)),
                  ],
                ]),
              ),
            ]),
          );
        },
      );
}
