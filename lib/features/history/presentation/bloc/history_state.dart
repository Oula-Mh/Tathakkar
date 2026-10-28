part of 'history_bloc.dart';

class HistoryState extends Equatable {
  const HistoryState({
    required this.month,
    required this.selectedDay,
    this.logs = const [],
    this.loading = true,
    this.failureKey,
  });

  final DateTime month; // first day of month
  final DateTime selectedDay;
  final List<DoseLog> logs;
  final bool loading;
  final String? failureKey;

  List<DoseLog> get logsOfSelectedDay =>
      logs.where((l) => l.scheduledAt.isSameDay(selectedDay)).toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  List<DoseLog> logsOf(DateTime day) => logs.where((l) => l.scheduledAt.isSameDay(day)).toList();

  HistoryState copyWith({
    DateTime? month,
    DateTime? selectedDay,
    List<DoseLog>? logs,
    bool? loading,
    String? failureKey,
  }) =>
      HistoryState(
        month: month ?? this.month,
        selectedDay: selectedDay ?? this.selectedDay,
        logs: logs ?? this.logs,
        loading: loading ?? this.loading,
        failureKey: failureKey,
      );

  @override
  List<Object?> get props => [month, selectedDay, logs, loading, failureKey];
}
