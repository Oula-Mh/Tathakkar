part of 'care_link_bloc.dart';

sealed class CareLinkEvent extends Equatable {
  const CareLinkEvent();
  @override
  List<Object?> get props => [];
}

class CareLinkWatchStarted extends CareLinkEvent {
  const CareLinkWatchStarted({required this.uid, required this.name});
  final String uid;
  final String name;
  @override
  List<Object?> get props => [uid, name];
}

class CareLinkUpdated extends CareLinkEvent {
  const CareLinkUpdated(this.result);
  final Either<Failure, CareLink?> result;
  @override
  List<Object?> get props => [result];
}

class CareTokenRequested extends CareLinkEvent {
  const CareTokenRequested();
}

class CareQrScanned extends CareLinkEvent {
  const CareQrScanned(this.rawValue);
  final String rawValue;
  @override
  List<Object?> get props => [rawValue];
}

class CareUnlinkRequested extends CareLinkEvent {
  const CareUnlinkRequested();
}

/// Reset the one-shot result (when leaving the result screens).
class CareResultCleared extends CareLinkEvent {
  const CareResultCleared();
}
