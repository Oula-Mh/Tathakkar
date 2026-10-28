part of 'history_bloc.dart';

sealed class HistoryEvent extends Equatable {
  const HistoryEvent();
  @override
  List<Object?> get props => [];
}

class HistoryProfileChanged extends HistoryEvent {
  const HistoryProfileChanged(this.profile);
  final PersonProfile profile;
  @override
  List<Object?> get props => [profile];
}

class HistoryMonthShifted extends HistoryEvent {
  const HistoryMonthShifted(this.delta);
  final int delta;
  @override
  List<Object?> get props => [delta];
}

class HistoryDaySelected extends HistoryEvent {
  const HistoryDaySelected(this.day);
  final DateTime day;
  @override
  List<Object?> get props => [day];
}

class HistoryUpdated extends HistoryEvent {
  const HistoryUpdated(this.result);
  final Either<Failure, List<DoseLog>> result;
  @override
  List<Object?> get props => [result];
}
