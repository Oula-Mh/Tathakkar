import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/l10n_keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/circle_icon_button.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../doses/domain/entities/dose_log.dart';
import '../bloc/history_bloc.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) => AppScaffold(
        title: context.tr(L.historyTitle),
        body: BlocBuilder<HistoryBloc, HistoryState>(
          builder: (context, s) => Column(children: [
            _MonthHeader(month: s.month),
            const SizedBox(height: 8),
            GlassCard(blur: 0, padding: const EdgeInsets.all(12), child: _Calendar(state: s)),
            const SizedBox(height: 16),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(Fmt.dayHeader(context, s.selectedDay),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 10),
            if (s.loading)
              const SkeletonList(count: 2)
            else if (s.failureKey != null)
              ErrorView(messageKey: s.failureKey!)
            else if (s.logsOfSelectedDay.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(context.tr(L.noHistory), style: TextStyle(color: context.inkSoftColor)),
              )
            else
              for (final l in s.logsOfSelectedDay) _LogTile(log: l),
          ]),
        ),
      );
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.month});
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<HistoryBloc>();
    return Row(children: [
      CircleIconButton(icon: Icons.chevron_left_rounded, size: 40, onPressed: () => bloc.add(const HistoryMonthShifted(-1))),
      Expanded(
        child: Text(Fmt.monthYear(context, month),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      ),
      CircleIconButton(icon: Icons.chevron_right_rounded, size: 40, onPressed: () => bloc.add(const HistoryMonthShifted(1))),
    ]);
  }
}

class _Calendar extends StatelessWidget {
  const _Calendar({required this.state});
  final HistoryState state;

  @override
  Widget build(BuildContext context) {
    final first = state.month;
    final daysInMonth = DateTime(first.year, first.month + 1, 0).day;
    final lead = first.weekday % 7; // Sunday-first grid
    final locale = Localizations.localeOf(context).languageCode;
    final sunday = DateTime(2023, 1, 1); // a Sunday
    final today = DateTime.now().dateOnly;

    Color? dot(DateTime day) {
      final logs = state.logsOf(day);
      if (logs.isEmpty) return null;
      final graceOver = DateTime.now().isAfter(day.add(const Duration(days: 1)));
      final anyMissed = logs.any((l) =>
          l.status == DoseStatus.missed ||
          (l.status == DoseStatus.pending &&
              (graceOver ||
                  DateTime.now().isAfter(l.scheduledAt
                      .add(const Duration(minutes: BusinessRules.missedDoseGraceMinutes))))));
      if (anyMissed) return AppColors.danger;
      return logs.every((l) => l.status == DoseStatus.taken) ? AppColors.success : AppColors.slateBlue;
    }

    return Column(children: [
      Row(children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Center(
              child: Text(DateFormat.E(locale).format(sunday.add(Duration(days: i))),
                  style: TextStyle(fontSize: 12, color: context.inkSoftColor)),
            ),
          ),
      ]),
      const SizedBox(height: 6),
      GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1,
        children: [
          for (var i = 0; i < lead; i++) const SizedBox.shrink(),
          for (var d = 1; d <= daysInMonth; d++)
            Builder(builder: (context) {
              final day = DateTime(first.year, first.month, d);
              final selected = day.isSameDay(state.selectedDay);
              final c = dot(day);
              return InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => context.read<HistoryBloc>().add(HistoryDaySelected(day)),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? AppColors.turquoise : Colors.transparent,
                    border: day.isSameDay(today) && !selected
                        ? Border.all(color: AppColors.turquoise)
                        : null,
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(Fmt.number(context, d),
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : context.inkColor)),
                    SizedBox(
                      height: 6,
                      child: c == null
                          ? null
                          : Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle, color: selected ? Colors.white : c)),
                    ),
                  ]),
                ),
              );
            }),
        ],
      ),
    ]);
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.log});
  final DoseLog log;

  @override
  Widget build(BuildContext context) {
    final overdue = DateTime.now().isAfter(
        log.scheduledAt.add(const Duration(minutes: BusinessRules.missedDoseGraceMinutes)));
    final (label, tone) = switch (log.status) {
      DoseStatus.taken => (L.doseTaken, ChipTone.success),
      DoseStatus.missed => (L.doseUnconfirmed, ChipTone.danger),
      DoseStatus.pending => overdue ? (L.doseUnconfirmed, ChipTone.danger) : (L.doseUpcoming, ChipTone.info),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        blur: 0,
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(log.medicationName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              Text(Fmt.time(context, log.scheduledAt),
                  style: TextStyle(fontSize: 13, color: context.inkSoftColor)),
            ]),
          ),
          StatusChip(label: context.tr(label), tone: tone),
        ]),
      ),
    );
  }
}
