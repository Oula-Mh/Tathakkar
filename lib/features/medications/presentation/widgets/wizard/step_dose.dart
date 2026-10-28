import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/localization/l10n_keys.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/glass_card.dart';
import '../../../../../core/widgets/number_stepper.dart';
import '../../../domain/entities/medication.dart';
import '../../bloc/form/medication_form_bloc.dart';
import '../med_labels.dart';

class StepDose extends StatefulWidget {
  const StepDose({super.key, required this.state});
  final MedicationFormState state;

  @override
  State<StepDose> createState() => _StepDoseState();
}

class _StepDoseState extends State<StepDose> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(int index) async {
    final bloc = context.read<MedicationFormBloc>();
    final current = widget.state.draft.times[index];
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (t != null) bloc.add(MedTimeChanged(index, t.hour * 60 + t.minute));
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<MedicationFormBloc>();
    final d = widget.state.draft;
    const presets = [L.mealBefore, L.mealAfter, L.mealWith];
    const meals = [MealRelation.before, MealRelation.after, MealRelation.withMeal];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GlassCard(
        blur: 0,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(context.tr(L.dosesPerDay),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            NumberStepper(
              value: d.times.length,
              min: 1,
              max: 8,
              onChanged: (v) => bloc.add(MedTimesCountChanged(v)),
            ),
          ]),
          const SizedBox(height: 10),
          for (var i = 0; i < d.times.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _pickTime(i),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: context.isDark ? 0.08 : 0.9),
                      borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    Icon(Icons.access_time_rounded, color: context.primaryColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                          '${context.tr(L.doseN, args: {'n': Fmt.number(context, i + 1)})}  •  ${Fmt.minutesToTime(context, d.times[i])}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                    Icon(Icons.edit_outlined, size: 18, color: context.inkSoftColor),
                  ]),
                ),
              ),
            ),
          if (widget.state.timesError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(context.tr(widget.state.timesError!),
                  style: const TextStyle(color: AppColors.danger, fontSize: 13)),
            ),
        ]),
      ),
      const SizedBox(height: 14),
      GlassCard(
        blur: 0,
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(context.tr(L.amountPerDose),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              Text(context.tr(L.amountPerDoseHint),
                  style: TextStyle(fontSize: 12.5, color: context.inkSoftColor)),
            ]),
          ),
          NumberStepper(
            value: d.dosePerTake,
            min: 1,
            max: 99,
            onChanged: (v) => bloc.add(MedDoseAmountChanged(v)),
          ),
        ]),
      ),
      const SizedBox(height: 14),
      GlassCard(
        blur: 0,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(context.tr(L.instructions),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (var i = 0; i < presets.length; i++)
              ChoiceChip(
                label: Text(context.tr(presets[i])),
                selected: d.meal == meals[i],
                onSelected: (sel) =>
                    bloc.add(MedMealChanged(sel ? meals[i] : MealRelation.anytime)),
              ),
            for (final n in d.notes)
              InputChip(label: Text(n), onDeleted: () => bloc.add(MedNoteRemoved(n))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  hintText: context.tr(L.addInstructionHint),
                  isDense: true,
                ),
                onSubmitted: (v) {
                  bloc.add(MedNoteAdded(v));
                  _noteController.clear();
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_rounded),
              color: context.primaryColor,
              tooltip: context.tr(L.add),
              onPressed: () {
                bloc.add(MedNoteAdded(_noteController.text));
                _noteController.clear();
              },
            ),
          ]),
        ]),
      ),
    ]);
  }
}
