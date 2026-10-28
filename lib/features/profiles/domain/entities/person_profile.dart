import 'package:equatable/equatable.dart';

enum ProfileKind { self, local, remote }

/// A person whose medications are tracked.
/// - self:   the signed-in user
/// - local:  a family member managed on this phone (e.g. a child)
/// - remote: a linked person (elder) managed from another account
class PersonProfile extends Equatable {
  const PersonProfile({
    required this.ownerUid,
    required this.profileId,
    required this.name,
    required this.kind,
    this.relation,
    this.managedByUid,
  });

  /// Firestore owner: data lives under users/{ownerUid}/profiles/{profileId}.
  final String ownerUid;
  final String profileId;
  final String name;
  final ProfileKind kind;
  final String? relation;

  /// Set on the elder's own profile while a caregiver manages it.
  final String? managedByUid;

  String get key => '$ownerUid/$profileId';
  bool get isSelf => kind == ProfileKind.self;
  bool get isRemote => kind == ProfileKind.remote;

  /// Permission rule: an elder under care can view and confirm, not edit.
  bool get canManageMedications => !(isSelf && managedByUid != null);

  /// Reminders ring on this phone for self/local profiles only.
  bool get remindsOnThisDevice => kind != ProfileKind.remote;

  String get initial => name.trim().isEmpty ? '?' : String.fromCharCode(name.trim().runes.first);

  @override
  List<Object?> get props => [ownerUid, profileId, name, kind, relation, managedByUid];
}
