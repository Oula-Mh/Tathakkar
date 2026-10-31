import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/active_reminder_registry.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/push_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../auth/domain/repositories/session_cleaner.dart';
import '../../../auth/presentation/bloc/session/session_bloc.dart';
import '../../../care_link/presentation/bloc/care_link_bloc.dart';
import '../../../doses/presentation/bloc/doses_bloc.dart';
import '../../../history/presentation/bloc/history_bloc.dart';
import '../../../inbox/presentation/bloc/inbox_bloc.dart';
import '../../../medications/presentation/bloc/list/medications_bloc.dart';
import '../../../profiles/domain/usecases/profiles_usecases.dart';
import '../../../profiles/presentation/bloc/profiles_bloc.dart';
import '../../../reminders/data/reminder_sync_service.dart';
import '../../../reminders/domain/entities/reminder_payload.dart';
import '../../../reminders/presentation/bloc/health/reminder_health_bloc.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';

/// Per-login scope: creates the data blocs once and wires them together,
/// so switching the active person reloads medications, doses and history.
class SessionScope extends StatefulWidget {
  const SessionScope({super.key, required this.child});
  final Widget child;

  @override
  State<SessionScope> createState() => _SessionScopeState();
}

class _SessionScopeState extends State<SessionScope> with WidgetsBindingObserver {
  late final ProfilesBloc _profiles;
  late final MedicationsBloc _medications;
  late final DosesBloc _doses;
  late final HistoryBloc _history;
  late final CareLinkBloc _care;
  late final InboxBloc _inbox;
  late final ReminderHealthBloc _health;
  late final ReminderSyncService _sync;
  StreamSubscription<NotificationTap>? _tapSub;
  StreamSubscription<void>? _pushSub;
  Timer? _dueTimer;
  bool _foreground = true;
  bool _bootstrapped = false;
  final _shownDue = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _profiles = getIt<ProfilesBloc>();
    _medications = getIt<MedicationsBloc>();
    _doses = getIt<DosesBloc>();
    _history = getIt<HistoryBloc>();
    _care = getIt<CareLinkBloc>();
    _inbox = getIt<InboxBloc>();
    _health = getIt<ReminderHealthBloc>()..add(const HealthRefreshed());
    _sync = getIt<ReminderSyncService>();

    final session = context.read<SessionBloc>().state;
    if (session is SessionAuthenticated) _bootstrap(session);
    _dueTimer = Timer.periodic(const Duration(seconds: 10), (_) => _checkDue());

    // Notification taps / buttons open the right screen (also from a cold start).
    final notifications = getIt<NotificationService>();
    _tapSub = notifications.taps.listen(_handleTap);
    final launch = notifications.takeLaunchTap();
    if (launch != null) WidgetsBinding.instance.addPostFrameCallback((_) => _handleLaunch(launch));
    _pushSub = getIt<PushService>().opens.listen((_) {
      if (mounted) context.push(Routes.inbox);
    });

    // Ask for notification permission once, after first login.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!context.read<SettingsBloc>().state.settings.notificationsPrompted) {
        context.push(Routes.notificationPermission);
      }
    });
  }

  /// Order matters: first drop leftovers of ANOTHER user, then start the streams.
  Future<void> _bootstrap(SessionAuthenticated session) async {
    if (_bootstrapped) return;
    _bootstrapped = true;
    final user = session.user;
    try {
      await getIt<SessionCleaner>().prepareFor(user.id);
    } catch (e) {
      AppLogger.w('prepareFor failed: $e');
    }
    if (!mounted) return;
    _profiles.add(ProfilesWatchRequested(uid: user.id, userName: user.name));
    _care.add(CareLinkWatchStarted(uid: user.id, name: user.name));
    _inbox.add(InboxWatchRequested(user.id));
    final lang = context.read<SettingsBloc>().state.settings.languageCode;
    getIt<PushService>().register(user.id, languageCode: lang);
    // Repairs accounts whose registration batch failed (no user doc / self profile).
    getIt<EnsureSelfProfile>()(
        EnsureSelfProfileParams(uid: user.id, name: user.name, email: user.email));
  }

  /// Android re-delivers the ORIGINAL notification intent when the process is
  /// restored later, which used to open an old reminder (with sound) at random.
  /// A launch is only honoured while its dose is current (or its button was used).
  void _handleLaunch(NotificationTap tap) {
    final p = ReminderPayload.tryParse(tap.payload);
    if (p != null && !p.isStock && tap.actionId == null) {
      final now = DateTime.now();
      if (!p.isCurrentDose(now)) {
        AppLogger.w('Ignoring stale notification launch');
        return;
      }
    }
    _handleTap(tap);
  }

  void _handleTap(NotificationTap tap) {
    if (!mounted) return;
    if (tap.payload == 'i') {
      context.push(Routes.inbox);
      return;
    }
    final p = ReminderPayload.tryParse(tap.payload);
    if (p == null) return; // test notification: nothing to open
    if (p.isStock) {
      _profiles.add(ProfileSelected(p.profileKey));
      context.push(Routes.medicationStock(p.medicationId));
      return;
    }
    // From a notification: alarm mode (only the alarm screen, closing leaves the app).
    context.push(Routes.reminderLocation(tap.payload, action: tap.actionId, alarm: true));
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

  /// App is OPEN: open the alarm screen at the exact dose time (once per dose).
  void _checkDue() {
    if (!mounted || !_foreground || ActiveReminderRegistry.anyOpen) return;
    final now = DateTime.now();
    for (final p in _sync.dueNow(now)) {
      final key = '${ReminderPayload.dayKey(now)}/'
          '${ActiveReminderRegistry.keyOf(p.profileKey, p.medicationId, p.minutesOfDay)}';
      if (!_shownDue.add(key)) continue;
      context.push(Routes.reminderLocation(p.encode()));
      break;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    // Back from system settings (permissions granted?) -> re-check and re-apply alarms.
    if (state == AppLifecycleState.resumed) {
      _health.add(const HealthRefreshed());
      _sync.resync();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tapSub?.cancel();
    _pushSub?.cancel();
    _dueTimer?.cancel();
    _sync.dispose();
    _profiles.close();
    _medications.close();
    _doses.close();
    _history.close();
    _care.close();
    _inbox.close();
    _health.close();
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
          BlocProvider.value(value: _health),
        ],
        child: MultiBlocListener(
          listeners: [
            // Session may resolve AFTER this scope was built (alarm cold start).
            BlocListener<SessionBloc, SessionState>(
              listenWhen: (p, c) => c is SessionAuthenticated && !_bootstrapped,
              listener: (_, s) => _bootstrap(s as SessionAuthenticated),
            ),
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
