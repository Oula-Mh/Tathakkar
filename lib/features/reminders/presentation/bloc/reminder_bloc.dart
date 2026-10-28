import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../doses/domain/usecases/doses_usecases.dart';
import '../../../medications/domain/entities/medication.dart';
import '../../../medications/domain/usecases/medications_usecases.dart';
import '../../../profiles/domain/entities/person_profile.dart';
import '../../domain/entities/reminder_payload.dart';
import '../../domain/repositories/reminder_scheduler.dart';

part 'reminder_event.dart';
part 'reminder_state.dart';

class ReminderBloc extends Bloc<ReminderEvent, ReminderState> {
  ReminderBloc({
    required GetMedication getMedication,
    required ConfirmDose confirmDose,
    required ReminderScheduler scheduler,
  })  : _get = getMedication,
        _confirm = confirmDose,
        _scheduler = scheduler,
        super(const ReminderState()) {
    on<ReminderOpened>(_onOpened);
    on<ReminderTakenPressed>(_onTaken);
    on<ReminderSnoozePressed>(_onSnooze);
  }

  final GetMedication _get;
  final ConfirmDose _confirm;
  final ReminderScheduler _scheduler;
  PersonProfile? _profile;
  String _lang = 'ar';
  String _profileName = '';

  PersonProfile _profileFor(ReminderPayload p) => PersonProfile(
        ownerUid: p.ownerUid,
        profileId: p.profileId,
        name: _profileName,
        kind: p.profileId == FirestorePaths.selfProfileId ? ProfileKind.self : ProfileKind.local,
      );

  Future<void> _onOpened(ReminderOpened e, Emitter<ReminderState> emit) async {
    _lang = e.languageCode;
    _profileName = e.profileName;
    _profile = _profileFor(e.payload);
    emit(ReminderState(payload: e.payload));
    final r = await _get(MedicationRef(_profile!, e.payload.medicationId));
    emit(r.fold(
      (f) => ReminderState(
          status: ReminderStatus.failure, payload: e.payload, failureKey: f.messageKey),
      (m) => ReminderState(status: ReminderStatus.ready, medication: m, payload: e.payload),
    ));
  }

  Future<void> _onTaken(ReminderTakenPressed e, Emitter<ReminderState> emit) async {
    final m = state.medication, p = state.payload, profile = _profile;
    if (m == null || p == null || profile == null || state.status == ReminderStatus.working) return;
    emit(state.copyWith(status: ReminderStatus.working));
    final r = await _confirm(ConfirmDoseParams(profile, m, p.originalTime(DateTime.now())));
    await r.fold(
      (f) async => emit(state.copyWith(status: ReminderStatus.ready, actionFailureKey: f.messageKey)),
      (_) async {
        await _scheduler.cancelSnooze(p);
        emit(state.copyWith(status: ReminderStatus.taken));
      },
    );
  }

  Future<void> _onSnooze(ReminderSnoozePressed e, Emitter<ReminderState> emit) async {
    final m = state.medication, p = state.payload;
    if (m == null || p == null || !state.canSnooze || state.status == ReminderStatus.working) return;
    emit(state.copyWith(status: ReminderStatus.working));
    // Snoozing is NOT a confirmation: no stock change, no log.
    await _scheduler.snooze(p, m, profileName: _profileName, languageCode: _lang);
    emit(state.copyWith(status: ReminderStatus.snoozed));
  }
}
