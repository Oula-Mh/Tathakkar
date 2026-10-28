import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/l10n_keys.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';

/// Shown once after first login: asks for notification permission.
class NotificationPermissionPage extends StatelessWidget {
  const NotificationPermissionPage({super.key});

  @override
  Widget build(BuildContext context) {
    Future<void> finish({required bool request}) async {
      final settings = context.read<SettingsBloc>();
      final router = GoRouter.of(context);
      if (request) {
        try {
          await getIt<NotificationService>().requestPermission();
        } catch (_) {}
      }
      settings.add(const NotificationsPrompted());
      if (router.canPop()) router.pop();
    }

    return AppScaffold(
      scrollable: false,
      body: MessageView(
        icon: Icons.notifications_none_rounded,
        title: context.tr(L.allowNotificationsTitle),
        message: context.tr(L.allowNotificationsSub),
        actionLabel: context.tr(L.allow),
        onAction: () => finish(request: true),
        secondaryLabel: context.tr(L.notNow),
        onSecondary: () => finish(request: false),
      ),
    );
  }
}
