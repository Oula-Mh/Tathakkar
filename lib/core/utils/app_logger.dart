import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

abstract final class AppLogger {
  static final Logger _log = Logger(
    printer: PrettyPrinter(methodCount: 0, noBoxingByDefault: true),
    level: kReleaseMode ? Level.warning : Level.debug,
  );

  static void d(String m) => _log.d(m);
  static void i(String m) => _log.i(m);
  static void w(String m) => _log.w(m);
  static void e(String m, [Object? error, StackTrace? st]) =>
      _log.e(m, error: error, stackTrace: st);
}
