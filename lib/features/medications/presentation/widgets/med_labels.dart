import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/l10n_keys.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../domain/entities/medication.dart';

/// Presentation-only text helpers for medication fields.
abstract final class MedLabels {
  static const knownUnits = ['pill', 'ml', 'unit'];

  static String meal(BuildContext c, MealRelation m) => switch (m) {
        MealRelation.before => c.tr(L.mealBefore),
        MealRelation.after => c.tr(L.mealAfter),
        MealRelation.withMeal => c.tr(L.mealWith),
        MealRelation.anytime => c.tr(L.mealAnytime),
      };

  static String unit(BuildContext c, String u) => switch (u) {
        'pill' => c.tr(L.unitPill),
        'ml' => c.tr(L.unitMl),
        'unit' => c.tr(L.unitUnit),
        _ => u,
      };

  static String dose(BuildContext c, Medication m) =>
      c.tr(L.doseUnits, args: {'n': Fmt.number(c, m.dosePerTake)});

  static String type(BuildContext c, TreatmentType t) =>
      c.tr(t == TreatmentType.permanent ? L.typePermanent : L.typeTemporary);

  /// Stock chip: out of stock > low > ok.
  static StatusChip stockChip(BuildContext c, Medication m) {
    if (m.isOutOfStock) {
      return StatusChip(label: c.tr(L.stockOut), tone: ChipTone.danger);
    }
    if (m.isLowStock) {
      return StatusChip(label: c.tr(L.stockLow), tone: ChipTone.warning);
    }
    return StatusChip(label: c.tr(L.stockOk), tone: ChipTone.success);
  }

  static String timesSummary(BuildContext c, Medication m) =>
      m.times.map((t) => Fmt.minutesToTime(c, t)).join(' • ');
}
