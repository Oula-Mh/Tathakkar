import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/l10n_keys.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/circle_icon_button.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../profiles/presentation/bloc/profiles_bloc.dart';
import '../bloc/list/medications_bloc.dart';
import '../widgets/medication_card.dart';

class MedicationsPage extends StatelessWidget {
  const MedicationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.select((ProfilesBloc b) => b.state.selected);
    final canAdd = profile?.canManageMedications ?? false;

    return AppScaffold(
      title: context.tr(L.medicationsTitle),
      scrollable: false,
      trailing: canAdd
          ? CircleIconButton(
              icon: Icons.add_rounded,
              tooltip: context.tr(L.addMedication),
              onPressed: () => context.push(Routes.medicationNew),
            )
          : null,
      body: BlocBuilder<MedicationsBloc, MedicationsState>(
        builder: (context, s) {
          switch (s.status) {
            case MedicationsStatus.loading:
              return const Padding(padding: EdgeInsets.only(top: 8), child: SkeletonList());
            case MedicationsStatus.failure:
              return ErrorView(
                messageKey: s.failureKey ?? 'err_unknown',
                onRetry: profile == null
                    ? null
                    : () => context.read<MedicationsBloc>().add(MedicationsWatchRequested(profile)),
              );
            case MedicationsStatus.ready:
              if (s.medications.isEmpty) {
                return MessageView(
                  icon: Icons.add_circle_outline_rounded,
                  title: context.tr(L.noMedsTitle),
                  message: context.tr(L.noMedsSub),
                  actionLabel: canAdd ? context.tr(L.addMedication) : null,
                  onAction: () => context.push(Routes.medicationNew),
                );
              }
              final list = s.filtered;
              return ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  TextField(
                    onChanged: (v) => context.read<MedicationsBloc>().add(MedicationsSearchChanged(v)),
                    decoration: InputDecoration(
                      hintText: context.tr(L.searchMedication),
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: context.isDark ? 0.08 : 0.9),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _StockSummary(state: s),
                  const SizedBox(height: 14),
                  if (list.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(context.tr(L.noResults),
                            style: TextStyle(color: context.inkSoftColor)),
                      ),
                    ),
                  for (final m in list)
                    MedicationCard(
                      medication: m,
                      onTap: () => context.push(Routes.medicationDetails(m.id)),
                    ),
                ],
              );
          }
        },
      ),
    );
  }
}

class _StockSummary extends StatelessWidget {
  const _StockSummary({required this.state});
  final MedicationsState state;

  @override
  Widget build(BuildContext context) {
    final ok = state.medications.length - state.lowStockCount - state.outOfStockCount;
    Widget cell(int n, String label, Color color) => Expanded(
          child: Column(
            children: [
              Text(Fmt.number(context, n),
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color)),
              Text(label, style: TextStyle(fontSize: 12.5, color: context.inkSoftColor)),
            ],
          ),
        );
    return GlassCard(
      blur: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr(L.stockStatusTitle),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 10),
          Row(children: [
            cell(ok, context.tr(L.stockOk), AppColors.success),
            cell(state.lowStockCount, context.tr(L.stockLow), AppColors.warning),
            cell(state.outOfStockCount, context.tr(L.stockOut), AppColors.danger),
          ]),
          if (state.endedCount > 0) ...[
            const SizedBox(height: 8),
            Text(context.tr(L.coursesEnded, args: {'n': Fmt.number(context, state.endedCount)}),
                style: TextStyle(fontSize: 13, color: context.inkSoftColor)),
          ],
        ],
      ),
    );
  }
}
