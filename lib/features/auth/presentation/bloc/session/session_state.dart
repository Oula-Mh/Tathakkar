part of 'session_bloc.dart';

sealed class SessionState extends Equatable {
  const SessionState();
  @override
  List<Object?> get props => [];
}

/// Auth state not resolved yet (splash is still visible).
class SessionUnknown extends SessionState {
  const SessionUnknown();
}

class SessionAuthenticated extends SessionState {
  const SessionAuthenticated(this.user);
  final UserEntity user;
  @override
  List<Object?> get props => [user];
}

class SessionUnauthenticated extends SessionState {
  const SessionUnauthenticated();
}
