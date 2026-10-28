part of 'doses_bloc.dart';

class DosesState extends Equatable {
  const DosesState({
    this.logs = const [],
    this.loading = true,
    this.failureKey,
    this.actionFailureKey,
    this.confirming = false,
  });

  final List<DoseLog> logs;
  final bool loading;
  final String? failureKey;
  final String? actionFailureKey;
  final bool confirming;

  DosesState copyWith({
    List<DoseLog>? logs,
    bool? loading,
    String? failureKey,
    String? actionFailureKey,
    bool? confirming,
  }) =>
      DosesState(
        logs: logs ?? this.logs,
        loading: loading ?? this.loading,
        failureKey: failureKey,
        actionFailureKey: actionFailureKey,
        confirming: confirming ?? this.confirming,
      );

  @override
  List<Object?> get props => [logs, loading, failureKey, actionFailureKey, confirming];
}
