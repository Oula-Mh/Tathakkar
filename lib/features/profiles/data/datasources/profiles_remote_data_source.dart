import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/stream_utils.dart';
import '../../domain/entities/person_profile.dart';

class ProfilesRemoteDataSource {
  ProfilesRemoteDataSource(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _profiles(String uid) =>
      _db.collection(FirestorePaths.users).doc(uid).collection(FirestorePaths.profiles);

  /// Live list: own profiles (self + local) + elders linked to me,
  /// with the "managed by" flag read from careLinks/{myUid}.
  Stream<List<PersonProfile>> watch(String uid, String userName) {
    final own = _profiles(uid).orderBy('createdAt').snapshots();
    final myLink = _db.collection(FirestorePaths.careLinks).doc(uid).snapshots();
    final elders = _db
        .collection(FirestorePaths.careLinks)
        .where('caregiverUid', isEqualTo: uid)
        .snapshots();

    return combineLatest3(own, myLink, elders, (ownSnap, linkSnap, eldersSnap) {
      final managedBy = linkSnap.data()?['caregiverUid'] as String?;
      final list = <PersonProfile>[];

      var hasSelf = false;
      for (final d in ownSnap.docs) {
        final m = d.data();
        final isSelf = d.id == FirestorePaths.selfProfileId;
        hasSelf |= isSelf;
        list.add(PersonProfile(
          ownerUid: uid,
          profileId: d.id,
          name: (m['name'] as String?) ?? userName,
          kind: isSelf ? ProfileKind.self : ProfileKind.local,
          relation: m['relation'] as String?,
          managedByUid: isSelf ? managedBy : null,
        ));
      }
      if (!hasSelf) {
        list.insert(
          0,
          PersonProfile(
            ownerUid: uid,
            profileId: FirestorePaths.selfProfileId,
            name: userName,
            kind: ProfileKind.self,
            managedByUid: managedBy,
          ),
        );
      } else {
        list.sort((a, b) => a.isSelf ? -1 : (b.isSelf ? 1 : 0));
      }

      for (final d in eldersSnap.docs) {
        final m = d.data();
        list.add(PersonProfile(
          ownerUid: m['elderUid'] as String? ?? d.id,
          profileId: FirestorePaths.selfProfileId,
          name: (m['elderName'] as String?) ?? '',
          kind: ProfileKind.remote,
        ));
      }
      return list;
    });
  }

  Future<PersonProfile> addLocal(String uid, String name, String relation) async {
    final ref = _profiles(uid).doc();
    await ref.set({
      'name': name,
      'relation': relation,
      'kind': 'local',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return PersonProfile(
      ownerUid: uid,
      profileId: ref.id,
      name: name,
      kind: ProfileKind.local,
      relation: relation,
    );
  }

  /// Registration writes these docs in a batch AFTER the Auth account exists.
  /// If that batch failed (rules, network) the account would have no user doc,
  /// so this idempotent check repairs it on the next sign-in.
  Future<void> ensureSelf(String uid, String name, String email) async {
    final userRef = _db.collection(FirestorePaths.users).doc(uid);
    final selfRef = userRef.collection(FirestorePaths.profiles).doc(FirestorePaths.selfProfileId);
    final results = await Future.wait([userRef.get(), selfRef.get()]);
    final batch = _db.batch();
    var dirty = false;
    if (!results[0].exists) {
      batch.set(userRef, {'name': name, 'email': email, 'createdAt': FieldValue.serverTimestamp()});
      dirty = true;
    }
    if (!results[1].exists) {
      batch.set(selfRef, {'name': name, 'kind': 'self', 'createdAt': FieldValue.serverTimestamp()});
      dirty = true;
    }
    if (dirty) await batch.commit();
  }
}
