import 'dart:async';
import 'dart:math' as math;

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/formatters.dart';
import '../../../medications/domain/entities/medication.dart';
import '../../../profiles/domain/entities/person_profile.dart';
import '../../domain/entities/dose_log.dart';
import '../../domain/usecases/doses_usecases.dart';

part 'doses_event.dart';
part 'doses_state.dart';

class DosesBloc extends Bloc<DosesEvent, DosesState> {
  DosesBloc({required WatchDoseLogs watchDoseLogs, required ConfirmDose confirmDose})
      : _watch = watchDoseLogs,
        _confirm = confirmDose,
        super(const DosesState()) {
    on<DosesWatchRequested>(_onWatch);
    on<DosesUpdated>(_onUpdated);
    on<DoseConfirmRequested>(_onConfirm);
  }

  final WatchDoseLogs _watch;
  final ConfirmDose _confirm;
  PersonProfile? _profile;
  StreamSubscription<Either<Failure, List<DoseLog>>>? _sub;

  void _onWatch(DosesWatchRequested e, Emitter<DosesState> emit) {
    if (!e.force && _profile == e.profile) return;
    final same = _profile == e.profile;
    _profile = e.profile;
    _sub?.cancel();
    _retry?.cancel();
    emit(same ? state.copyWith(logs: state.logs, loading: state.logs.isEmpty) : const DosesState());
    final today = DateTime.now().dateOnly;
    // Yesterday..tomorrow covers late-night doses and day-boundary edges.
    _sub = _watch(
      e.profile,
      today.subtract(const Duration(days: 1)),
      today.add(const Duration(days: 2)),
    ).listen((r) => add(DosesUpdated(r)));
  }

  Timer? _retry;
  int _attempt = 0;

  void _onUpdated(DosesUpdated e, Emitter<DosesState> emit) => emit(e.result.fold(
        (f) {
          if (f is NetworkFailure || f is ServerFailure) {
            final p = _profile;
            if (p != null) {
              _retry?.cancel();
              _attempt = math.min(_attempt + 1, 6);
              _retry = Timer(Duration(seconds: math.min(2 << _attempt, 60)), () {
                if (!isClosed) add(DosesWatchRequested(p, force: true));
              });
            }
          }
          return state.copyWith(logs: state.logs, loading: false, failureKey: f.messageKey);
        },
        (logs) {
          _attempt = 0;
          return state.copyWith(logs: logs, loading: false);
        },
      ));

  Future<void> _onConfirm(DoseConfirmRequested e, Emitter<DosesState> emit) async {
    final profile = _profile;
    if (profile == null || state.confirming) return;
    emit(state.copyWith(confirming: true, logs: state.logs, loading: false));
    final r = await _confirm(ConfirmDoseParams(profile, e.medication, e.scheduledAt));
    emit(state.copyWith(
      confirming: false,
      logs: state.logs,
      loading: false,
      actionFailureKey: r.fold((f) => f.messageKey, (_) => null),
    ));
  }

  @override
  Future<void> close() {
    _retry?.cancel();
    _sub?.cancel();
    return super.close();
  }
}
