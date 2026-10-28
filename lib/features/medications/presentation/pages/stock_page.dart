import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/l10n_keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/info_row.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../profiles/presentation/bloc/profiles_bloc.dart';
import '../bloc/list/medications_bloc.dart';
import '../bloc/stock/stock_bloc.dart';
import '../widgets/med_labels.dart';
import '../widgets/wizard/step_stock.dart';

class StockPage extends StatelessWidget {
  const StockPage({super.key, required this.medicationId});
  final String medicationId;

  @override
  Widget build(BuildContext context) {
    final profile = context.read<ProfilesBloc>().state.selected;
    final med = context.watch<MedicationsBloc>().state.byId(medicationId);
    if (profile == null || med == null) {
      return const AppScaffold(showBack: true, scrollable: false, body: ErrorView(messageKey: 'err_not_found'));
    }
    final canEdit = profile.canManageMedications;
    return BlocProvider(
      create: (_) => StockBloc(updateStock: getIt(), profile: profile, medication: med),
      child: BlocConsumer<StockBloc, StockState>(
        listenWhen: (p, c) => p.status != c.status,
        listener: (context, s) {
          if (s.status == StockStatus.saved) {
            AppSnackbar.show(context, context.tr(L.stockUpdated));
            context.pop();
          } else if (s.status == StockStatus.failure) {
            AppSnackbar.show(context, context.tr(s.failureKey ?? 'err_unknown'), error: true);
          }
        },
        builder: (context, s) {
          final bloc = context.read<StockBloc>();
          final color = s.remaining <= 0
              ? AppColors.danger
              : (s.remaining <= s.threshold ? AppColors.warning : AppColors.success);
          final progress = s.packSize <= 0 ? 0.0 : (s.remaining / s.packSize).clamp(0.0, 1.0);
          return AppScaffold(
            showBack: true,
            title: '${context.tr(L.stock)} · ${med.name}',
            bottom: canEdit
                ? AppButton(
                    label: context.tr(L.updateStock),
                    isLoading: s.status == StockStatus.saving,
                    onPressed: () => bloc.add(const StockSubmitted()),
                  )
                : null,
            body: Column(children: [
              GlassCard(
                child: Column(children: [
                  Text(Fmt.number(context, s.remaining),
                      style: TextStyle(fontSize: 56, fontWeight: FontWeight.w800, color: color)),
                  Text(context.tr(L.remaining), style: TextStyle(color: context.inkSoftColor)),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                        value: progress, minHeight: 10, color: color, backgroundColor: AppColors.platinum),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              if (s.remaining <= 0)
                _Banner(text: context.tr(L.stockOutBanner), bg: AppColors.dangerBg, fg: AppColors.danger)
              else if (s.remaining <= s.threshold)
                _Banner(
                    text: context.tr(L.stockLowBanner, args: {'n': Fmt.number(context, s.remaining)}),
                    bg: AppColors.warningBg,
                    fg: AppColors.warning),
              const SizedBox(height: 12),
              GlassCard(
                blur: 0,
                child: Column(children: [
                  InfoRow(label: context.tr(L.packSize), value: Fmt.number(context, s.packSize)),
                  InfoRow(
                      label: context.tr(L.currentStock),
                      value: '${Fmt.number(context, s.remaining)} ${MedLabels.unit(context, med.unit)}'),
                  InfoRow(label: context.tr(L.deductPerDose), value: MedLabels.dose(context, med)),
                  InfoRow(label: context.tr(L.alertThreshold), value: Fmt.number(context, s.threshold)),
                  InfoRow(
                      label: context.tr(L.daysLeft),
                      value: Fmt.number(context,
                          med.copyWith(remaining: s.remaining).daysOfStockLeft)),
                ]),
              ),
              if (canEdit) ...[
                const SizedBox(height: 16),
                StockFields(
                  packSize: s.packSize,
                  remaining: s.remaining,
                  threshold: s.threshold,
                  unit: med.unit,
                  onPackSize: (v) => bloc.add(StockValuesChanged(packSize: v)),
                  onRemaining: (v) => bloc.add(StockValuesChanged(remaining: v)),
                  onThreshold: (v) => bloc.add(StockValuesChanged(threshold: v)),
                ),
              ],
            ]),
          );
        },
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.bg, required this.fg});
  final String text;
  final Color bg;
  final Color fg;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Icon(Icons.warning_amber_rounded, color: fg),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w600))),
        ]),
      );
}
