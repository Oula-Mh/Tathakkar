import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/app_settings.dart';

abstract interface class SettingsRepository {
  /// Synchronous read: Hive box is already open at startup.
  AppSettings load();
  Future<Either<Failure, Unit>> save(AppSettings settings);
}
