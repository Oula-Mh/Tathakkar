part of 'stock_bloc.dart';

enum StockStatus { editing, saving, saved, failure }

class StockState extends Equatable {
  const StockState({
    required this.remaining,
    required this.packSize,
    required this.threshold,
    this.status = StockStatus.editing,
    this.failureKey,
  });

  final int remaining;
  final int packSize;
  final int threshold;
  final StockStatus status;
  final String? failureKey;

  StockState copyWith({
    int? remaining,
    int? packSize,
    int? threshold,
    StockStatus? status,
    String? failureKey,
  }) =>
      StockState(
        remaining: remaining ?? this.remaining,
        packSize: packSize ?? this.packSize,
        threshold: threshold ?? this.threshold,
        status: status ?? this.status,
        failureKey: failureKey,
      );

  @override
  List<Object?> get props => [remaining, packSize, threshold, status, failureKey];
}
