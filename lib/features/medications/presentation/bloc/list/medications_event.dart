part of 'medications_bloc.dart';

sealed class MedicationsEvent extends Equatable {
  const MedicationsEvent();
  @override
  List<Object?> get props => [];
}

class MedicationsWatchRequested extends MedicationsEvent {
  const MedicationsWatchRequested(this.profile);
  final PersonProfile profile;
  @override
  List<Object?> get props => [profile];
}

/// Internal: emitted by the stream subscription.
class MedicationsUpdated extends MedicationsEvent {
  const MedicationsUpdated(this.result);
  final Either<Failure, List<Medication>> result;
  @override
  List<Object?> get props => [result];
}

class MedicationsSearchChanged extends MedicationsEvent {
  const MedicationsSearchChanged(this.query);
  final String query;
  @override
  List<Object?> get props => [query];
}

class MedicationDeleteRequested extends MedicationsEvent {
  const MedicationDeleteRequested(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}
