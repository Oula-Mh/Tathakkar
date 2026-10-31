import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/usecase/usecase.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/repositories/session_cleaner.dart';
import '../../../domain/usecases/auth_usecases.dart';

part 'session_event.dart';
part 'session_state.dart';

/// Single source of truth for "who is signed in". The router listens to it.
class SessionBloc extends Bloc<SessionEvent, SessionState> {
  SessionBloc({
    required WatchAuthUser watchAuthUser,
    required SignOut signOut,
    required SessionCleaner cleaner,
  })  : _watch = watchAuthUser,
        _signOut = signOut,
        _cleaner = cleaner,
        super(const SessionUnknown()) {
    on<SessionStarted>(_onStarted);
    on<SessionLogoutRequested>(_onLogout);
  }

  final WatchAuthUser _watch;
  final SignOut _signOut;
  final SessionCleaner _cleaner;

  /// Order matters: cleanup first (it needs the signed-in user to unregister
  /// the push token), then sign out.
  Future<void> _onLogout(SessionLogoutRequested e, Emitter<SessionState> emit) async {
    final s = state;
    await _cleaner.clearForSignOut(s is SessionAuthenticated ? s.user.id : null);
    await _signOut(const NoParams());
  }

  Future<void> _onStarted(SessionStarted event, Emitter<SessionState> emit) {
    return emit.forEach<UserEntity?>(
      _watch(),
      onData: (u) => u == null ? const SessionUnauthenticated() : SessionAuthenticated(u),
      onError: (_, __) => const SessionUnauthenticated(),
    );
  }
}
