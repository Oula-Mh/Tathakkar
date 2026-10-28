import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/di/injection.dart';
import 'core/localization/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/session/session_bloc.dart';
import 'features/connectivity/presentation/bloc/connectivity_bloc.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';

class TathakkarApp extends StatelessWidget {
  const TathakkarApp({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: getIt<SettingsBloc>()),
          BlocProvider.value(value: getIt<SessionBloc>()..add(const SessionStarted())),
          BlocProvider.value(value: getIt<ConnectivityBloc>()..add(const ConnectivityStarted())),
        ],
        child: BlocBuilder<SettingsBloc, SettingsState>(
          buildWhen: (p, c) =>
              p.settings.languageCode != c.settings.languageCode ||
              p.settings.darkMode != c.settings.darkMode,
          builder: (context, s) => MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'تَذَكَّر',
            locale: s.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: s.themeMode,
            routerConfig: getIt<AppRouter>().router,
            // Respect system font scaling but keep layouts from breaking.
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: MediaQuery.of(context)
                    .textScaler
                    .clamp(minScaleFactor: 0.9, maxScaleFactor: 1.35),
              ),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      );
}
