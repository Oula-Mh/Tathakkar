import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/usecase/usecase.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/usecases/auth_usecases.dart';

part 'session_event.dart';
part 'session_state.dart';

/// Single source of truth for "who is signed in". The router listens to it.
class SessionBloc extends Bloc<SessionEvent, SessionState> {
  SessionBloc({required WatchAuthUser watchAuthUser, required SignOut signOut})
      : _watch = watchAuthUser,
        _signOut = signOut,
        super(const SessionUnknown()) {
    on<SessionStarted>(_onStarted);
    on<SessionLogoutRequested>((_, __) => _signOut(const NoParams()));
  }

  final WatchAuthUser _watch;
  final SignOut _signOut;

  Future<void> _onStarted(SessionStarted event, Emitter<SessionState> emit) {
    return emit.forEach<UserEntity?>(
      _watch(),
      onData: (u) => u == null ? const SessionUnauthenticated() : SessionAuthenticated(u),
      onError: (_, __) => const SessionUnauthenticated(),
    );
  }
}
