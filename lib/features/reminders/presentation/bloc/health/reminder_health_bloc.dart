import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/reminder_health.dart';
import '../../../domain/repositories/reminder_health_checker.dart';

part 'reminder_health_event.dart';
part 'reminder_health_state.dart';

/// Tells the user (and us) whether alarms can actually ring on time.
class ReminderHealthBloc extends Bloc<ReminderHealthEvent, ReminderHealthState> {
  ReminderHealthBloc(this._checker) : super(const ReminderHealthState()) {
    on<HealthRefreshed>(_onRefresh);
    on<HealthFixRequested>(_onFix);
    on<HealthTestScheduled>(_onTest);
    on<HealthTestShownNow>(_onTestNow);
  }

  final ReminderHealthChecker _checker;

  Future<void> _onRefresh(HealthRefreshed e, Emitter<ReminderHealthState> emit) async {
    try {
      emit(state.copyWith(health: await _checker.check(), loading: false));
    } catch (_) {
      emit(state.copyWith(loading: false));
    }
  }

  Future<void> _onFix(HealthFixRequested e, Emitter<ReminderHealthState> emit) async {
    try {
      await _checker.request(e.item);
    } catch (_) {}
    await _onRefresh(const HealthRefreshed(), emit);
  }

  Future<void> _onTest(HealthTestScheduled e, Emitter<ReminderHealthState> emit) async {
    try {
      await _checker.scheduleTest(seconds: e.seconds, languageCode: e.languageCode);
      emit(state.copyWith(messageKey: 'health_test_scheduled', messageSeq: state.messageSeq + 1));
    } catch (_) {
      emit(state.copyWith(messageKey: 'err_test_failed', messageSeq: state.messageSeq + 1));
    }
    await _onRefresh(const HealthRefreshed(), emit);
  }

  Future<void> _onTestNow(HealthTestShownNow e, Emitter<ReminderHealthState> emit) async {
    try {
      await _checker.showTestNow(languageCode: e.languageCode);
    } catch (_) {
      emit(state.copyWith(messageKey: 'err_test_failed', messageSeq: state.messageSeq + 1));
    }
  }
}
