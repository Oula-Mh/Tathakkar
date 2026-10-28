import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/l10n_keys.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../profiles/presentation/bloc/profiles_bloc.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../domain/entities/medication.dart';
import '../bloc/form/medication_form_bloc.dart';
import '../bloc/list/medications_bloc.dart';
import '../widgets/wizard/step_dose.dart';
import '../widgets/wizard/step_info.dart';
import '../widgets/wizard/step_reminders.dart';
import '../widgets/wizard/step_review.dart';
import '../widgets/wizard/step_stock.dart';
import '../widgets/wizard/wizard_header.dart';

/// Add (medicationId == null) or edit a medication.
class MedicationFormPage extends StatelessWidget {
  const MedicationFormPage({super.key, this.medicationId});
  final String? medicationId;

  @override
  Widget build(BuildContext context) {
    final profile = context.read<ProfilesBloc>().state.selected;
    final existing =
        medicationId == null ? null : context.read<MedicationsBloc>().state.byId(medicationId!);

    // Elders under care are read-only; unknown medication => nothing to edit.
    if (profile == null || !profile.canManageMedications || (medicationId != null && existing == null)) {
      return AppScaffold(
        showBack: true,
        scrollable: false,
        body: ErrorView(messageKey: profile?.canManageMedications == false ? 'err_permission' : 'err_not_found'),
      );
    }

    final s = context.read<SettingsBloc>().state.settings;
    final initial = existing ??
        Medication(
          name: '',
          startDate: DateTime.now(),
          remindersEnabled: s.remindersEnabled,
          soundEnabled: s.soundEnabled,
          speakEnabled: s.speakEnabled,
          showImage: s.showImage,
          fullScreen: s.fullScreen,
          snoozeMinutes: s.snoozeMinutes,
        );

    return BlocProvider(
      create: (_) => MedicationFormBloc(
        saveMedication: getIt(),
        profile: profile,
        initial: initial,
      ),
      child: _FormView(isEdit: existing != null),
    );
  }
}

class _FormView extends StatelessWidget {
  const _FormView({required this.isEdit});
  final bool isEdit;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<MedicationFormBloc>();
    return BlocConsumer<MedicationFormBloc, MedicationFormState>(
      listenWhen: (p, c) => p.status != c.status && c.status == MedFormStatus.failure,
      listener: (context, s) =>
          AppSnackbar.show(context, context.tr(s.failureKey ?? 'err_unknown'), error: true),
      builder: (context, s) {
        if (s.status == MedFormStatus.saved) {
          return AppScaffold(
            scrollable: false,
            body: MessageView(
              icon: Icons.check_rounded,
              title: context.tr(L.medSaved),
              message: context.tr(L.medSavedSub),
              actionLabel: context.tr(L.backToHome),
              onAction: () => context.go('/home'),
            ),
          );
        }
        final step = s.step;
        return PopScope(
          canPop: step == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) bloc.add(const MedPreviousStep());
          },
          child: AppScaffold(
            title: context.tr(isEdit ? L.editMedication : L.addMedication),
            showBack: true,
            onBack: () => step == 0 ? context.pop() : bloc.add(const MedPreviousStep()),
            bottom: AppButton(
              label: context.tr(s.isLastStep ? L.saveMedication : L.next),
              isLoading: s.isSaving,
              onPressed: () => bloc.add(s.isLastStep ? const MedSubmitted() : const MedNextStep()),
            ),
            body: Column(children: [
              WizardSteps(current: step, onTapStep: (i) => bloc.add(MedGoToStep(i))),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: KeyedSubtree(
                  key: ValueKey(step),
                  child: switch (step) {
                    0 => StepInfo(state: s),
                    1 => StepDose(state: s),
                    2 => StepStock(state: s),
                    3 => StepReminders(state: s),
                    _ => StepReview(medication: s.draft),
                  },
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}
