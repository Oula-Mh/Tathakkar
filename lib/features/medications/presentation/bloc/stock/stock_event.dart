part of 'stock_bloc.dart';

sealed class StockEvent extends Equatable {
  const StockEvent();
  @override
  List<Object?> get props => [];
}

class StockValuesChanged extends StockEvent {
  const StockValuesChanged({this.remaining, this.packSize, this.threshold});
  final int? remaining;
  final int? packSize;
  final int? threshold;
  @override
  List<Object?> get props => [remaining, packSize, threshold];
}

class StockSubmitted extends StockEvent {
  const StockSubmitted();
}
