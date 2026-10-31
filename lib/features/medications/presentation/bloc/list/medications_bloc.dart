import 'dart:async';
import 'dart:math' as math;

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../profiles/domain/entities/person_profile.dart';
import '../../../domain/entities/medication.dart';
import '../../../domain/usecases/medications_usecases.dart';

part 'medications_event.dart';
part 'medications_state.dart';

class MedicationsBloc extends Bloc<MedicationsEvent, MedicationsState> {
  MedicationsBloc({
    required WatchMedications watchMedications,
    required DeleteMedication deleteMedication,
  })  : _watch = watchMedications,
        _delete = deleteMedication,
        super(const MedicationsState()) {
    on<MedicationsWatchRequested>(_onWatch);
    on<MedicationsUpdated>(_onUpdated);
    on<MedicationsSearchChanged>((e, emit) => emit(state.copyWith(
          query: e.query,
          failureKey: state.failureKey,
        )));
    on<MedicationDeleteRequested>(_onDelete);
  }

  final WatchMedications _watch;
  final DeleteMedication _delete;
  PersonProfile? _profile;
  StreamSubscription<Either<Failure, List<Medication>>>? _sub;

  Timer? _retry;
  int _attempt = 0;

  void _onWatch(MedicationsWatchRequested e, Emitter<MedicationsState> emit) {
    if (!e.force && _profile == e.profile) return;
    final sameProfile = _profile == e.profile;
    _profile = e.profile;
    _sub?.cancel();
    _retry?.cancel();
    // Keep the cached list visible while reconnecting to the same profile.
    emit(sameProfile ? state.copyWith(status: state.medications.isEmpty ? MedicationsStatus.loading : MedicationsStatus.ready) : const MedicationsState());
    _sub = _watch(e.profile).listen((r) => add(MedicationsUpdated(r)));
  }

  void _onUpdated(MedicationsUpdated e, Emitter<MedicationsState> emit) {
    emit(e.result.fold(
      // Keep showing cached data if the live stream fails.
      (f) {
        _scheduleRetry(f);
        return state.medications.isEmpty
            ? state.copyWith(status: MedicationsStatus.failure, failureKey: f.messageKey)
            : state.copyWith(status: MedicationsStatus.ready);
      },
      (list) {
        _attempt = 0;
        return state.copyWith(status: MedicationsStatus.ready, medications: list);
      },
    ));
  }

  /// A failed Firestore stream is finished: resubscribe on transient errors
  /// (network/server) with backoff. Permission errors are NOT retried blindly.
  void _scheduleRetry(Failure f) {
    if (f is! NetworkFailure && f is! ServerFailure) return;
    final p = _profile;
    if (p == null) return;
    _retry?.cancel();
    _attempt = math.min(_attempt + 1, 6);
    _retry = Timer(Duration(seconds: math.min(2 << _attempt, 60)), () {
      if (!isClosed) add(MedicationsWatchRequested(p, force: true));
    });
  }

  Future<void> _onDelete(MedicationDeleteRequested e, Emitter<MedicationsState> emit) async {
    final p = _profile;
    if (p == null) return;
    final r = await _delete(MedicationRef(p, e.id));
    emit(r.fold(
      (f) => state.copyWith(actionFailureKey: f.messageKey),
      (_) => state.copyWith(deletedCount: state.deletedCount + 1),
    ));
  }

  @override
  Future<void> close() {
    _retry?.cancel();
    _sub?.cancel();
    return super.close();
  }
}
