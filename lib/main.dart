import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';
import 'core/di/injection.dart';
import 'core/services/app_bloc_observer.dart';
import 'core/services/notification_service.dart';
import 'core/storage/secure_key_store.dart';
import 'core/utils/app_logger.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    if (kDebugMode) Bloc.observer = AppBlocObserver();
    FlutterError.onError = (d) => AppLogger.e('FlutterError', d.exception, d.stack);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    try {
      await Hive.initFlutter();
      await Hive.openBox<dynamic>(HiveBoxes.settings);
      await Hive.openBox<dynamic>(HiveBoxes.flags);
      await _openEncryptedCache();
      await Firebase.initializeApp();
      FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
      await initializeDateFormatting('ar');
      await initializeDateFormatting('en');
      await configureDependencies();
      await getIt<NotificationService>()
          .init(languageCode: Hive.box<dynamic>(HiveBoxes.settings).get('app_settings') is Map
              ? ((Hive.box<dynamic>(HiveBoxes.settings).get('app_settings') as Map)['lang'] as String? ?? 'ar')
              : 'ar');
    } catch (e, st) {
      AppLogger.e('Startup failed', e, st);
      runApp(const _StartupError());
      return;
    }
    runApp(const TathakkarApp());
  }, (e, st) => AppLogger.e('Uncaught', e, st));
}

/// Medication cache = health data: AES-encrypted, key kept in the platform keystore.
/// It is only a cache, so on ANY problem (old plain box, lost key) we recreate it.
Future<void> _openEncryptedCache() async {
  const name = HiveBoxes.medicationsCache;
  try {
    final cipher = await SecureKeyStore().cipher();
    try {
      await Hive.openBox<dynamic>(name, encryptionCipher: cipher);
    } catch (_) {
      await Hive.deleteBoxFromDisk(name); // was unencrypted / key changed
      await Hive.openBox<dynamic>(name, encryptionCipher: cipher);
    }
  } catch (e) {
    AppLogger.w('Secure storage unavailable, caching disabled: $e');
    await Hive.deleteBoxFromDisk(name);
    await Hive.openBox<dynamic>(name); // degraded: plain (still wiped on sign-out)
  }
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
