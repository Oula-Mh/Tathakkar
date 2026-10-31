part of 'profiles_bloc.dart';

sealed class ProfilesEvent extends Equatable {
  const ProfilesEvent();
  @override
  List<Object?> get props => [];
}

class ProfilesWatchRequested extends ProfilesEvent {
  const ProfilesWatchRequested({required this.uid, required this.userName});
  final String uid;
  final String userName;
  @override
  List<Object?> get props => [uid, userName];
}

class ProfileSelected extends ProfilesEvent {
  const ProfileSelected(this.key);
  final String key;
  @override
  List<Object?> get props => [key];
}

class LocalProfileAdded extends ProfilesEvent {
  const LocalProfileAdded({required this.name, required this.relation});
  final String name;
  final String relation;
  @override
  List<Object?> get props => [name, relation];
}

/// "Try again" after a failed/ended stream.
class ProfilesRetryRequested extends ProfilesEvent {
  const ProfilesRetryRequested();
}
