import 'dart:async';

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

  void _onWatch(MedicationsWatchRequested e, Emitter<MedicationsState> emit) {
    if (_profile == e.profile) return;
    _profile = e.profile;
    _sub?.cancel();
    emit(const MedicationsState());
    _sub = _watch(e.profile).listen((r) => add(MedicationsUpdated(r)));
  }

  void _onUpdated(MedicationsUpdated e, Emitter<MedicationsState> emit) {
    emit(e.result.fold(
      // Keep showing cached data if the live stream fails.
      (f) => state.medications.isEmpty
          ? state.copyWith(status: MedicationsStatus.failure, failureKey: f.messageKey)
          : state.copyWith(status: MedicationsStatus.ready),
      (list) => state.copyWith(status: MedicationsStatus.ready, medications: list),
    ));
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
    _sub?.cancel();
    return super.close();
  }
}
