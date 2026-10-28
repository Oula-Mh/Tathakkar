import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/person_profile.dart';
import '../../domain/usecases/profiles_usecases.dart';

part 'profiles_event.dart';
part 'profiles_state.dart';

class ProfilesBloc extends Bloc<ProfilesEvent, ProfilesState> {
  ProfilesBloc({required WatchProfiles watchProfiles, required AddLocalProfile addLocalProfile})
      : _watch = watchProfiles,
        _add = addLocalProfile,
        super(const ProfilesState()) {
    on<ProfilesWatchRequested>(_onWatch);
    on<ProfileSelected>((e, emit) => emit(state.copyWith(selectedKey: e.key)));
    on<LocalProfileAdded>(_onAdd);
  }

  final WatchProfiles _watch;
  final AddLocalProfile _add;
  String? _uid;

  Future<void> _onWatch(ProfilesWatchRequested e, Emitter<ProfilesState> emit) {
    _uid = e.uid;
    return emit.forEach(
      _watch(e.uid, e.userName),
      onData: (result) => result.fold(
        (f) => state.copyWith(status: ProfilesStatus.failure, failureKey: f.messageKey),
        (profiles) {
          // Keep the selection if it still exists (a link may have been removed).
          final stillThere = profiles.any((p) => p.key == state.selectedKey);
          return state.copyWith(
            status: ProfilesStatus.ready,
            profiles: profiles,
            selectedKey: stillThere ? state.selectedKey : profiles.first.key,
          );
        },
      ),
      onError: (_, __) =>
          state.copyWith(status: ProfilesStatus.failure, failureKey: 'err_unknown'),
    );
  }

  Future<void> _onAdd(LocalProfileAdded e, Emitter<ProfilesState> emit) async {
    final uid = _uid;
    if (uid == null || state.adding) return;
    emit(state.copyWith(adding: true, clearAddFailure: true));
    final result = await _add(AddLocalProfileParams(uid: uid, name: e.name, relation: e.relation));
    result.fold(
      (f) => emit(state.copyWith(adding: false, addFailureKey: f.messageKey)),
      (p) => emit(state.copyWith(
        adding: false,
        selectedKey: p.key,
        addedCount: state.addedCount + 1,
      )),
    );
  }
}
