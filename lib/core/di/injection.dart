import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';

import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/auth_usecases.dart';
import '../../features/auth/presentation/bloc/forgot_password/forgot_password_bloc.dart';
import '../../features/auth/presentation/bloc/login/login_bloc.dart';
import '../../features/auth/presentation/bloc/register/register_bloc.dart';
import '../../features/auth/presentation/bloc/session/session_bloc.dart';
import '../../features/care_link/data/care_link_repository_impl.dart';
import '../../features/care_link/domain/repositories/care_link_repository.dart';
import '../../features/care_link/domain/usecases/care_link_usecases.dart';
import '../../features/care_link/presentation/bloc/care_link_bloc.dart';
import '../../features/connectivity/presentation/bloc/connectivity_bloc.dart';
import '../../features/doses/data/datasources/doses_remote_data_source.dart';
import '../../features/doses/data/repositories/doses_repository_impl.dart';
import '../../features/doses/domain/repositories/doses_repository.dart';
import '../../features/doses/domain/usecases/doses_usecases.dart';
import '../../features/doses/presentation/bloc/doses_bloc.dart';
import '../../features/history/presentation/bloc/history_bloc.dart';
import '../../features/inbox/data/inbox_repository_impl.dart';
import '../../features/inbox/domain/repositories/inbox_repository.dart';
import '../../features/inbox/presentation/bloc/inbox_bloc.dart';
import '../../features/medications/data/datasources/medications_local_data_source.dart';
import '../../features/medications/data/datasources/medications_remote_data_source.dart';
import '../../features/medications/data/repositories/medications_repository_impl.dart';
import '../../features/medications/domain/repositories/medications_repository.dart';
import '../../features/medications/domain/usecases/medications_usecases.dart';
import '../../features/medications/presentation/bloc/list/medications_bloc.dart';
import '../../features/profiles/data/datasources/profiles_remote_data_source.dart';
import '../../features/profiles/data/repositories/profiles_repository_impl.dart';
import '../../features/profiles/domain/repositories/profiles_repository.dart';
import '../../features/profiles/domain/usecases/profiles_usecases.dart';
import '../../features/profiles/presentation/bloc/profiles_bloc.dart';
import '../../features/reminders/data/local_reminder_scheduler.dart';
import '../../features/reminders/data/reminder_sync_service.dart';
import '../../features/reminders/domain/repositories/reminder_scheduler.dart';
import '../../features/reminders/presentation/bloc/reminder_bloc.dart';
import '../../features/settings/data/datasources/settings_local_data_source.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/domain/usecases/get_settings.dart';
import '../../features/settings/domain/usecases/save_settings.dart';
import '../../features/settings/presentation/bloc/settings_bloc.dart';
import '../constants/app_constants.dart';
import '../router/app_router.dart';
import '../services/alarm_service.dart';
import '../services/connectivity_service.dart';
import '../services/notification_service.dart';
import '../services/push_service.dart';
import '../storage/local_storage.dart';

final getIt = GetIt.instance;

const _settingsStorage = 'settings_storage';
const _medsCacheStorage = 'meds_cache_storage';

/// Composition root. Hive boxes must already be open (see main.dart).
Future<void> configureDependencies() async {
  // ---- External / core ----
  getIt
    ..registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance)
    ..registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance)
    ..registerLazySingleton<LocalStorage>(
        () => LocalStorage(Hive.box<dynamic>(HiveBoxes.settings)),
        instanceName: _settingsStorage)
    ..registerLazySingleton<LocalStorage>(
        () => LocalStorage(Hive.box<dynamic>(HiveBoxes.medicationsCache)),
        instanceName: _medsCacheStorage)
    ..registerLazySingleton(NotificationService.new)
    ..registerLazySingleton(AlarmService.new)
    ..registerLazySingleton(ConnectivityService.new)
    ..registerLazySingleton(() => PushService(getIt()));

  // ---- Settings ----
  getIt
    ..registerLazySingleton(() => SettingsLocalDataSource(getIt(instanceName: _settingsStorage)))
    ..registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl(getIt()))
    ..registerLazySingleton(() => GetSettings(getIt()))
    ..registerLazySingleton(() => SaveSettings(getIt()))
    ..registerLazySingleton(
        () => SettingsBloc(initial: getIt<GetSettings>()(), saveSettings: getIt()));

  // ---- Auth ----
  getIt
    ..registerLazySingleton<AuthRemoteDataSource>(() => FirebaseAuthDataSource(getIt(), getIt()))
    ..registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(getIt()))
    ..registerLazySingleton(() => SignIn(getIt()))
    ..registerLazySingleton(() => RegisterUser(getIt()))
    ..registerLazySingleton(() => SendPasswordReset(getIt()))
    ..registerLazySingleton(() => SignOut(getIt()))
    ..registerLazySingleton(() => WatchAuthUser(getIt()))
    ..registerLazySingleton(() => SessionBloc(watchAuthUser: getIt(), signOut: getIt()))
    ..registerFactory(() => LoginBloc(getIt()))
    ..registerFactory(() => RegisterBloc(getIt()))
    ..registerFactory(() => ForgotPasswordBloc(getIt()));

  // ---- Profiles ----
  getIt
    ..registerLazySingleton(() => ProfilesRemoteDataSource(getIt()))
    ..registerLazySingleton<ProfilesRepository>(() => ProfilesRepositoryImpl(getIt()))
    ..registerLazySingleton(() => WatchProfiles(getIt()))
    ..registerLazySingleton(() => AddLocalProfile(getIt()))
    ..registerFactory(() => ProfilesBloc(watchProfiles: getIt(), addLocalProfile: getIt()));

  // ---- Medications ----
  getIt
    ..registerLazySingleton(() => MedicationsRemoteDataSource(getIt()))
    ..registerLazySingleton(() => MedicationsLocalDataSource(getIt(instanceName: _medsCacheStorage)))
    ..registerLazySingleton<MedicationsRepository>(() => MedicationsRepositoryImpl(getIt(), getIt()))
    ..registerLazySingleton(() => WatchMedications(getIt()))
    ..registerLazySingleton(() => GetMedication(getIt()))
    ..registerLazySingleton(() => SaveMedication(getIt()))
    ..registerLazySingleton(() => DeleteMedication(getIt()))
    ..registerLazySingleton(() => UpdateStock(getIt()))
    ..registerFactory(() => MedicationsBloc(watchMedications: getIt(), deleteMedication: getIt()));

  // ---- Doses ----
  getIt
    ..registerLazySingleton(() => DosesRemoteDataSource(getIt()))
    ..registerLazySingleton<DosesRepository>(() => DosesRepositoryImpl(getIt()))
    ..registerLazySingleton(() => WatchDoseLogs(getIt()))
    ..registerLazySingleton(() => ConfirmDose(getIt()))
    ..registerLazySingleton(() => EnsurePendingDoses(getIt()))
    ..registerFactory(() => DosesBloc(watchDoseLogs: getIt(), confirmDose: getIt()))
    ..registerFactory(() => HistoryBloc(watchDoseLogs: getIt()));

  // ---- Reminders ----
  getIt
    ..registerLazySingleton<ReminderScheduler>(() => LocalReminderScheduler(getIt()))
    ..registerFactory(() => ReminderSyncService(
        watchMedications: getIt(), ensurePending: getIt(), scheduler: getIt()))
    ..registerFactory(() =>
        ReminderBloc(getMedication: getIt(), confirmDose: getIt(), scheduler: getIt()));

  // ---- Care link ----
  getIt
    ..registerLazySingleton<CareLinkRepository>(() => CareLinkRepositoryImpl(getIt()))
    ..registerLazySingleton(() => WatchMyCaregiver(getIt()))
    ..registerLazySingleton(() => CreateLinkToken(getIt()))
    ..registerLazySingleton(() => RedeemLinkToken(getIt()))
    ..registerLazySingleton(() => UnlinkCaregiver(getIt()))
    ..registerFactory(() => CareLinkBloc(
        watchMyCaregiver: getIt(),
        createToken: getIt(),
        redeemToken: getIt(),
        unlink: getIt()));

  // ---- Inbox ----
  getIt
    ..registerLazySingleton<InboxRepository>(() => InboxRepositoryImpl(getIt()))
    ..registerFactory(() => InboxBloc(getIt()));

  // ---- Connectivity + router ----
  getIt
    ..registerLazySingleton(() => ConnectivityBloc(getIt()))
    ..registerLazySingleton(() => AppRouter(session: getIt(), settings: getIt()));
}
