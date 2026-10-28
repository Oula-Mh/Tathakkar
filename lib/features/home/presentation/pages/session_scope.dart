import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/push_service.dart';
import '../../../auth/presentation/bloc/session/session_bloc.dart';
import '../../../care_link/presentation/bloc/care_link_bloc.dart';
import '../../../doses/presentation/bloc/doses_bloc.dart';
import '../../../history/presentation/bloc/history_bloc.dart';
import '../../../inbox/presentation/bloc/inbox_bloc.dart';
import '../../../medications/presentation/bloc/list/medications_bloc.dart';
import '../../../profiles/presentation/bloc/profiles_bloc.dart';
import '../../../reminders/data/reminder_sync_service.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';

/// Per-login scope: creates the data blocs once and wires them together,
/// so switching the active person reloads medications, doses and history.
class SessionScope extends StatefulWidget {
  const SessionScope({super.key, required this.child});
  final Widget child;

  @override
  State<SessionScope> createState() => _SessionScopeState();
}

class _SessionScopeState extends State<SessionScope> {
  late final ProfilesBloc _profiles;
  late final MedicationsBloc _medications;
  late final DosesBloc _doses;
  late final HistoryBloc _history;
  late final CareLinkBloc _care;
  late final InboxBloc _inbox;
  late final ReminderSyncService _sync;
  StreamSubscription<String>? _tapSub;

  @override
  void initState() {
    super.initState();
    final session = context.read<SessionBloc>().state;
    final user = session is SessionAuthenticated ? session.user : null;

    _profiles = getIt<ProfilesBloc>();
    _medications = getIt<MedicationsBloc>();
    _doses = getIt<DosesBloc>();
    _history = getIt<HistoryBloc>();
    _care = getIt<CareLinkBloc>();
    _inbox = getIt<InboxBloc>();
    _sync = getIt<ReminderSyncService>();

    if (user != null) {
      _profiles.add(ProfilesWatchRequested(uid: user.id, userName: user.name));
      _care.add(CareLinkWatchStarted(uid: user.id, name: user.name));
      _inbox.add(InboxWatchRequested(user.id));
      getIt<PushService>().register(user.id);
    }

    // Notification taps open the reminder screen (also from a cold start).
    final notifications = getIt<NotificationService>();
    _tapSub = notifications.taps.listen(_openReminder);
    final launch = notifications.takeLaunchPayload();
    if (launch != null) WidgetsBinding.instance.addPostFrameCallback((_) => _openReminder(launch));

    // Ask for notification permission once, after first login.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!context.read<SettingsBloc>().state.settings.notificationsPrompted) {
        context.push(Routes.notificationPermission);
      }
    });
  }

  void _openReminder(String payload) {
    if (!mounted) return;
    context.push(Routes.reminderLocation(payload));
  }

  void _onSelectedChanged() {
    final p = _profiles.state.selected;
    if (p == null) return;
    _medications.add(MedicationsWatchRequested(p));
    _doses.add(DosesWatchRequested(p));
    _history.add(HistoryProfileChanged(p));
  }

  void _syncReminders() {
    final s = context.read<SettingsBloc>().state.settings;
    _sync.update(_profiles.state.profiles,
        languageCode: s.languageCode, enabled: s.remindersEnabled);
  }

  @override
  void dispose() {
    _tapSub?.cancel();
    _sync.dispose();
    _profiles.close();
    _medications.close();
    _doses.close();
    _history.close();
    _care.close();
    _inbox.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _profiles),
          BlocProvider.value(value: _medications),
          BlocProvider.value(value: _doses),
          BlocProvider.value(value: _history),
          BlocProvider.value(value: _care),
          BlocProvider.value(value: _inbox),
        ],
        child: MultiBlocListener(
          listeners: [
            BlocListener<ProfilesBloc, ProfilesState>(
              listenWhen: (p, c) => p.selected != c.selected,
              listener: (_, __) => _onSelectedChanged(),
            ),
            BlocListener<ProfilesBloc, ProfilesState>(
              listenWhen: (p, c) => p.profiles != c.profiles,
              listener: (_, __) => _syncReminders(),
            ),
            BlocListener<SettingsBloc, SettingsState>(
              listenWhen: (p, c) =>
                  p.settings.languageCode != c.settings.languageCode ||
                  p.settings.remindersEnabled != c.settings.remindersEnabled,
              listener: (_, __) => _syncReminders(),
            ),
          ],
          child: widget.child,
        ),
      );
}
