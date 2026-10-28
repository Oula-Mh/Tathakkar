part of 'session_bloc.dart';

sealed class SessionEvent extends Equatable {
  const SessionEvent();
  @override
  List<Object?> get props => [];
}

/// Start listening to Firebase auth changes (once, at app start).
class SessionStarted extends SessionEvent {
  const SessionStarted();
}

class SessionLogoutRequested extends SessionEvent {
  const SessionLogoutRequested();
}
