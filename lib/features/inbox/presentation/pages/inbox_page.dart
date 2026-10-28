import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/l10n_keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/inbox_item.dart';
import '../bloc/inbox_bloc.dart';

class InboxPage extends StatelessWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context) => AppScaffold(
        showBack: true,
        scrollable: false,
        title: context.tr(L.notificationsTitle),
        body: BlocBuilder<InboxBloc, InboxState>(
          builder: (context, s) {
            if (s.loading) return const SkeletonList();
            if (s.failureKey != null && s.items.isEmpty) return ErrorView(messageKey: s.failureKey!);
            if (s.items.isEmpty) {
              return MessageView(
                icon: Icons.notifications_none_rounded,
                title: context.tr(L.noNotifications),
                message: context.tr(L.noNotificationsSub),
              );
            }
            return ListView.separated(
              itemCount: s.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _InboxTile(item: s.items[i]),
            );
          },
        ),
      );
}

class _InboxTile extends StatelessWidget {
  const _InboxTile({required this.item});
  final InboxItem item;

  @override
  Widget build(BuildContext context) {
    final (color, titleKey, bodyKey) = switch (item.type) {
      InboxType.missedDose => (AppColors.danger, L.inboxMissedTitle, L.inboxMissedBody),
      InboxType.lowStock => (AppColors.warning, L.inboxLowTitle, L.inboxLowBody),
      InboxType.outOfStock => (AppColors.danger, L.inboxOutTitle, L.inboxOutBody),
    };
    final args = {
      'person': item.personName,
      'med': item.medicationName,
      'time': item.scheduledAt == null ? '' : Fmt.time(context, item.scheduledAt!),
      'n': Fmt.number(context, item.remaining ?? 0),
    };
    return GlassCard(
      blur: 0,
      borderColor: color.withValues(alpha: 0.5),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(context.tr(titleKey, args: args),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          ),
          Text(Fmt.time(context, item.createdAt),
              style: TextStyle(fontSize: 12, color: context.inkSoftColor)),
        ]),
        const SizedBox(height: 6),
        Text(context.tr(bodyKey, args: args), style: const TextStyle(fontSize: 14.5, height: 1.5)),
        if (item.type == InboxType.missedDose) ...[
          const SizedBox(height: 6),
          Text(context.tr(L.missedNote),
              style: TextStyle(fontSize: 12.5, color: context.inkSoftColor)),
        ],
      ]),
    );
  }
}
