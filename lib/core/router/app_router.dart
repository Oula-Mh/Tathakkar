import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/account/presentation/pages/account_page.dart';
import '../../features/account/presentation/pages/notification_permission_page.dart';
import '../../features/account/presentation/pages/reminder_settings_page.dart';
import '../../features/auth/presentation/bloc/session/session_bloc.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/care_link/presentation/pages/care_page.dart';
import '../../features/care_link/presentation/pages/care_qr_page.dart';
import '../../features/care_link/presentation/pages/care_result_pages.dart';
import '../../features/care_link/presentation/pages/care_scan_page.dart';
import '../../features/history/presentation/pages/history_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/pages/main_shell.dart';
import '../../features/home/presentation/pages/session_scope.dart';
import '../../features/inbox/presentation/pages/inbox_page.dart';
import '../../features/medications/presentation/pages/medication_details_page.dart';
import '../../features/medications/presentation/pages/medication_form_page.dart';
import '../../features/medications/presentation/pages/medications_page.dart';
import '../../features/medications/presentation/pages/stock_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/profiles/presentation/pages/add_family_page.dart';
import '../../features/profiles/presentation/pages/family_page.dart';
import '../../features/reminders/presentation/pages/reminder_page.dart';
import '../../features/settings/presentation/bloc/settings_bloc.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import 'routes.dart';

/// Owns the GoRouter. Redirects react to splash, session and onboarding state.
class AppRouter {
  AppRouter({required SessionBloc session, required SettingsBloc settings})
      : _session = session,
        _settings = settings {
    router = GoRouter(
      initialLocation: Routes.splash,
      refreshListenable: Listenable.merge([
        splashDone,
        _BlocListenable(session.stream),
        _BlocListenable(settings.stream),
      ]),
      redirect: _redirect,
      routes: _routes,
      errorBuilder: (context, state) => const _NotFoundPage(),
    );
  }

  final SessionBloc _session;
  final SettingsBloc _settings;
  final splashDone = ValueNotifier<bool>(false);
  late final GoRouter router;

  void markSplashDone() => splashDone.value = true;

  String? _redirect(BuildContext context, GoRouterState state) {
    final loc = state.matchedLocation;
    final session = _session.state;
    final ready = splashDone.value && session is! SessionUnknown;
    if (!ready) return loc == Routes.splash ? null : Routes.splash;

    if (!_settings.state.settings.onboardingSeen) {
      return loc == Routes.onboarding ? null : Routes.onboarding;
    }
    final authed = session is SessionAuthenticated;
    if (!authed) {
      return Routes.authRoutes.contains(loc) ? null : Routes.login;
    }
    if (loc == Routes.splash || loc == Routes.onboarding || Routes.authRoutes.contains(loc)) {
      return Routes.home;
    }
    return null;
  }

  Page<void> _fade(GoRouterState s, Widget child) => CustomTransitionPage<void>(
        key: s.pageKey,
        child: child,
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      );

  late final List<RouteBase> _routes = [
    GoRoute(path: Routes.splash, pageBuilder: (c, s) => _fade(s, const SplashPage())),
    GoRoute(path: Routes.onboarding, pageBuilder: (c, s) => _fade(s, const OnboardingPage())),
    GoRoute(path: Routes.login, pageBuilder: (c, s) => _fade(s, const LoginPage())),
    GoRoute(path: Routes.register, builder: (c, s) => const RegisterPage()),
    GoRoute(path: Routes.forgotPassword, builder: (c, s) => const ForgotPasswordPage()),

    // Everything below needs a signed-in user and shares the session blocs.
    ShellRoute(
      builder: (context, state, child) => SessionScope(child: child),
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => MainShell(shell: shell),
          branches: [
            StatefulShellBranch(routes: [GoRoute(path: Routes.home, builder: (c, s) => const HomePage())]),
            StatefulShellBranch(routes: [GoRoute(path: Routes.medications, builder: (c, s) => const MedicationsPage())]),
            StatefulShellBranch(routes: [GoRoute(path: Routes.history, builder: (c, s) => const HistoryPage())]),
            StatefulShellBranch(routes: [GoRoute(path: Routes.account, builder: (c, s) => const AccountPage())]),
          ],
        ),
        // 'new' must be declared before ':id'.
        GoRoute(path: Routes.medicationNew, builder: (c, s) => const MedicationFormPage()),
        GoRoute(
          path: '/medications/:id',
          builder: (c, s) => MedicationDetailsPage(medicationId: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/medications/:id/edit',
          builder: (c, s) => MedicationFormPage(medicationId: s.pathParameters['id']),
        ),
        GoRoute(
          path: '/medications/:id/stock',
          builder: (c, s) => StockPage(medicationId: s.pathParameters['id']!),
        ),
        GoRoute(path: Routes.family, builder: (c, s) => const FamilyPage()),
        GoRoute(path: Routes.familyAdd, builder: (c, s) => const AddFamilyPage()),
        GoRoute(path: Routes.familyAddLocal, builder: (c, s) => const AddLocalProfilePage()),
        GoRoute(path: Routes.care, builder: (c, s) => const CarePage()),
        GoRoute(path: Routes.careQr, builder: (c, s) => const CareQrPage()),
        GoRoute(path: Routes.careScan, builder: (c, s) => const CareScanPage()),
        GoRoute(path: Routes.careResult, builder: (c, s) => const CareResultPage()),
        GoRoute(path: Routes.careLinkedElder, builder: (c, s) => const CareLinkedElderPage()),
        GoRoute(path: Routes.careUnlinked, builder: (c, s) => const CareUnlinkedPage()),
        GoRoute(path: Routes.inbox, builder: (c, s) => const InboxPage()),
        GoRoute(path: Routes.reminderSettings, builder: (c, s) => const ReminderSettingsPage()),
        GoRoute(path: Routes.notificationPermission, builder: (c, s) => const NotificationPermissionPage()),
        GoRoute(
          path: Routes.reminder,
          builder: (c, s) => ReminderPage(rawPayload: s.uri.queryParameters['p'] ?? ''),
        ),
      ],
    ),
  ];
}

/// Adapts a Bloc stream to a Listenable for GoRouter.refreshListenable.
class _BlocListenable extends ChangeNotifier {
  _BlocListenable(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage();
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => context.go(Routes.home),
            child: const Text('Home'),
          ),
        ),
      );
}
