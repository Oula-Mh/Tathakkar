import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

class SaveSettings implements UseCase<Unit, AppSettings> {
  const SaveSettings(this._repo);
  final SettingsRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(AppSettings params) => _repo.save(params);
}
