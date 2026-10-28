part of 'inbox_bloc.dart';

sealed class InboxEvent extends Equatable {
  const InboxEvent();
  @override
  List<Object?> get props => [];
}

class InboxWatchRequested extends InboxEvent {
  const InboxWatchRequested(this.uid);
  final String uid;
  @override
  List<Object?> get props => [uid];
}

class InboxUpdated extends InboxEvent {
  const InboxUpdated(this.result);
  final Either<Failure, List<InboxItem>> result;
  @override
  List<Object?> get props => [result];
}
