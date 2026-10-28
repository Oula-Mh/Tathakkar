import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/formatters.dart';
import '../../../doses/domain/entities/dose_log.dart';
import '../../../doses/domain/usecases/doses_usecases.dart';
import '../../../profiles/domain/entities/person_profile.dart';

part 'history_event.dart';
part 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  HistoryBloc({required WatchDoseLogs watchDoseLogs})
      : _watch = watchDoseLogs,
        super(HistoryState(
          month: DateTime(DateTime.now().year, DateTime.now().month),
          selectedDay: DateTime.now().dateOnly,
        )) {
    on<HistoryProfileChanged>((e, emit) {
      _profile = e.profile;
      _subscribe(emit);
    });
    on<HistoryMonthShifted>((e, emit) {
      final m = DateTime(state.month.year, state.month.month + e.delta);
      emit(state.copyWith(month: m, selectedDay: DateTime(m.year, m.month, 1)));
      _subscribe(emit);
    });
    on<HistoryDaySelected>((e, emit) => emit(state.copyWith(selectedDay: e.day, logs: state.logs, loading: false)));
    on<HistoryUpdated>((e, emit) => emit(e.result.fold(
          (f) => state.copyWith(loading: false, failureKey: f.messageKey),
          (logs) => state.copyWith(logs: logs, loading: false),
        )));
  }

  final WatchDoseLogs _watch;
  PersonProfile? _profile;
  StreamSubscription<Either<Failure, List<DoseLog>>>? _sub;

  void _subscribe(Emitter<HistoryState> emit) {
    final p = _profile;
    if (p == null) return;
    _sub?.cancel();
    emit(state.copyWith(loading: true, logs: const []));
    final from = state.month;
    final to = DateTime(from.year, from.month + 1);
    _sub = _watch(p, from, to).listen((r) => add(HistoryUpdated(r)));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
