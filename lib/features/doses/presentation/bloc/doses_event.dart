part of 'doses_bloc.dart';

sealed class DosesEvent extends Equatable {
  const DosesEvent();
  @override
  List<Object?> get props => [];
}

/// Watch today's logs for a profile (cancels the previous subscription).
class DosesWatchRequested extends DosesEvent {
  const DosesWatchRequested(this.profile);
  final PersonProfile profile;
  @override
  List<Object?> get props => [profile];
}

/// Internal: emitted by the stream subscription.
class DosesUpdated extends DosesEvent {
  const DosesUpdated(this.result);
  final Either<Failure, List<DoseLog>> result;
  @override
  List<Object?> get props => [result];
}

class DoseConfirmRequested extends DosesEvent {
  const DoseConfirmRequested(this.medication, this.scheduledAt);
  final Medication medication;
  final DateTime scheduledAt;
  @override
  List<Object?> get props => [medication, scheduledAt];
}
