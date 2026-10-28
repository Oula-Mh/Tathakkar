import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../profiles/domain/entities/person_profile.dart';
import '../../../domain/entities/medication.dart';
import '../../../domain/usecases/medications_usecases.dart';

part 'stock_event.dart';
part 'stock_state.dart';

/// Dedicated stock screen (separate from medication details).
class StockBloc extends Bloc<StockEvent, StockState> {
  StockBloc({required UpdateStock updateStock, required this.profile, required this.medication})
      : _update = updateStock,
        super(StockState(
          remaining: medication.remaining,
          packSize: medication.packSize,
          threshold: medication.alertThreshold,
        )) {
    on<StockValuesChanged>((e, emit) => emit(state.copyWith(
          remaining: e.remaining,
          packSize: e.packSize,
          threshold: e.threshold,
          status: StockStatus.editing,
        )));
    on<StockSubmitted>(_onSubmit);
  }

  final PersonProfile profile;
  final Medication medication;
  final UpdateStock _update;

  Future<void> _onSubmit(StockSubmitted e, Emitter<StockState> emit) async {
    if (state.status == StockStatus.saving) return;
    emit(state.copyWith(status: StockStatus.saving));
    final r = await _update(UpdateStockParams(
      profile: profile,
      medication: medication,
      remaining: state.remaining,
      packSize: state.packSize,
      alertThreshold: state.threshold,
    ));
    emit(r.fold(
      (f) => state.copyWith(status: StockStatus.failure, failureKey: f.messageKey),
      (_) => state.copyWith(status: StockStatus.saved),
    ));
  }
}
