import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'core/constants/app_constants.dart';
import 'core/di/injection.dart';
import 'core/services/notification_service.dart';
import 'core/utils/app_logger.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (d) => AppLogger.e('FlutterError', d.exception, d.stack);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    try {
      await Hive.initFlutter();
      await Hive.openBox<dynamic>(HiveBoxes.settings);
      await Hive.openBox<dynamic>(HiveBoxes.medicationsCache);
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);      FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
      await initializeDateFormatting('ar');
      await initializeDateFormatting('en');
      await configureDependencies();
      await getIt<NotificationService>().init();
    } catch (e, st) {
      AppLogger.e('Startup failed', e, st);
      runApp(const _StartupError());
      return;
    }
    runApp(const TathakkarApp());
  }, (e, st) => AppLogger.e('Uncaught', e, st));
}

/// Last-resort screen if Firebase/Hive could not start.
class _StartupError extends StatelessWidget {
  const _StartupError();

  @override
  Widget build(BuildContext context) => const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'تعذّر تشغيل التطبيق. تحقق من إعداد Firebase ثم أعد التشغيل.\n'
                'The app could not start. Check the Firebase setup and restart.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
}
