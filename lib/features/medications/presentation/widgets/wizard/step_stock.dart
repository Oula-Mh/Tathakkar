import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/localization/l10n_keys.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/glass_card.dart';
import '../../../../../core/widgets/number_stepper.dart';
import '../../bloc/form/medication_form_bloc.dart';
import '../med_labels.dart';

/// Stock inputs shared by the wizard step and the dedicated stock screen.
class StockFields extends StatelessWidget {
  const StockFields({
    super.key,
    required this.packSize,
    required this.remaining,
    required this.threshold,
    required this.unit,
    required this.onPackSize,
    required this.onRemaining,
    required this.onThreshold,
    this.onUnit,
    this.error,
  });

  final int packSize;
  final int remaining;
  final int threshold;
  final String unit;
  final ValueChanged<int> onPackSize;
  final ValueChanged<int> onRemaining;
  final ValueChanged<int> onThreshold;
  final ValueChanged<String>? onUnit;
  final String? error;

  @override
  Widget build(BuildContext context) {
    Widget row(String label, String hint, int v, ValueChanged<int> cb) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                Text(hint, style: TextStyle(fontSize: 12.5, color: context.inkSoftColor)),
              ]),
            ),
            NumberStepper(value: v, min: 0, max: 9999, onChanged: cb),
          ]),
        );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GlassCard(
        blur: 0,
        child: Column(children: [
          row(context.tr(L.packSize), context.tr(L.packSizeHint), packSize, onPackSize),
          const Divider(),
          row(context.tr(L.currentStock), context.tr(L.currentStockHint), remaining, onRemaining),
          const Divider(),
          row(context.tr(L.alertThreshold), context.tr(L.alertThresholdHint), threshold, onThreshold),
        ]),
      ),
      if (onUnit != null) ...[
        const SizedBox(height: 14),
        GlassCard(
          blur: 0,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.tr(L.stockUnit),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, children: [
              for (final u in MedLabels.knownUnits)
                ChoiceChip(
                  label: Text(MedLabels.unit(context, u)),
                  selected: unit == u,
                  onSelected: (_) => onUnit!(u),
                ),
            ]),
          ]),
        ),
      ],
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Icon(Icons.info_outline, size: 18, color: context.inkSoftColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(context.tr(L.stockDeductNote),
                style: TextStyle(fontSize: 13, color: context.inkSoftColor)),
          ),
        ]),
      ),
      if (error != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(context.tr(error!), style: const TextStyle(color: AppColors.danger)),
        ),
    ]);
  }
}

class StepStock extends StatelessWidget {
  const StepStock({super.key, required this.state});
  final MedicationFormState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<MedicationFormBloc>();
    final d = state.draft;
    return StockFields(
      packSize: d.packSize,
      remaining: d.remaining,
      threshold: d.alertThreshold,
      unit: d.unit,
      error: state.stockError,
      onPackSize: (v) => bloc.add(MedStockChanged(packSize: v, remaining: d.packSize == 0 && d.remaining == 0 ? v : null)),
      onRemaining: (v) => bloc.add(MedStockChanged(remaining: v)),
      onThreshold: (v) => bloc.add(MedStockChanged(threshold: v)),
      onUnit: (u) => bloc.add(MedStockChanged(unit: u)),
    );
  }
}
