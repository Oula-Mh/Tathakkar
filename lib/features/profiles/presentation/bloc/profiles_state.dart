part of 'profiles_bloc.dart';

enum ProfilesStatus { loading, ready, failure }

class ProfilesState extends Equatable {
  const ProfilesState({
    this.status = ProfilesStatus.loading,
    this.profiles = const [],
    this.selectedKey,
    this.failureKey,
    this.adding = false,
    this.addedCount = 0,
    this.addFailureKey,
  });

  final ProfilesStatus status;
  final List<PersonProfile> profiles;
  final String? selectedKey;
  final String? failureKey;
  final bool adding;

  /// Incremented after each successful add so the UI can react once.
  final int addedCount;
  final String? addFailureKey;

  PersonProfile? get selected {
    if (profiles.isEmpty) return null;
    return profiles.firstWhere((p) => p.key == selectedKey, orElse: () => profiles.first);
  }

  ProfilesState copyWith({
    ProfilesStatus? status,
    List<PersonProfile>? profiles,
    String? selectedKey,
    String? failureKey,
    bool? adding,
    int? addedCount,
    String? addFailureKey,
    bool clearAddFailure = false,
  }) =>
      ProfilesState(
        status: status ?? this.status,
        profiles: profiles ?? this.profiles,
        selectedKey: selectedKey ?? this.selectedKey,
        failureKey: failureKey,
        adding: adding ?? this.adding,
        addedCount: addedCount ?? this.addedCount,
        addFailureKey: clearAddFailure ? null : (addFailureKey ?? this.addFailureKey),
      );

  @override
  List<Object?> get props =>
      [status, profiles, selectedKey, failureKey, adding, addedCount, addFailureKey];
}
