import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_data_source.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._local);
  final SettingsLocalDataSource _local;

  @override
  AppSettings load() {
    try {
      return _local.read();
    } catch (_) {
      return const AppSettings(); // corrupted box -> safe defaults
    }
  }

  @override
  Future<Either<Failure, Unit>> save(AppSettings settings) async {
    try {
      await _local.write(settings);
      return const Right(unit);
    } catch (_) {
      return const Left(CacheFailure());
    }
  }
}
