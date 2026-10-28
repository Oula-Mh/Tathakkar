import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/user_model.dart';

abstract interface class AuthRemoteDataSource {
  Stream<UserModel?> watchUser();
  Future<UserModel> signIn(String email, String password);
  Future<UserModel> register(String name, String email, String password);
  Future<void> sendPasswordReset(String email);
  Future<void> signOut();
}

class FirebaseAuthDataSource implements AuthRemoteDataSource {
  FirebaseAuthDataSource(this._auth, this._db);
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  @override
  Stream<UserModel?> watchUser() =>
      _auth.userChanges().map((u) => u == null ? null : UserModel.fromFirebase(u));

  @override
  Future<UserModel> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return UserModel.fromFirebase(cred.user!);
  }

  @override
  Future<UserModel> register(String name, String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final user = cred.user!;
    await user.updateDisplayName(name);

    // User doc + the "self" profile every account starts with.
    final userRef = _db.collection(FirestorePaths.users).doc(user.uid);
    final batch = _db.batch()
      ..set(userRef, {
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      })
      ..set(userRef.collection(FirestorePaths.profiles).doc(FirestorePaths.selfProfileId), {
        'name': name,
        'kind': 'self',
        'createdAt': FieldValue.serverTimestamp(),
      });
    await batch.commit();
    await user.reload();
    return UserModel.fromFirebase(_auth.currentUser ?? user);
  }

  @override
  Future<void> sendPasswordReset(String email) => _auth.sendPasswordResetEmail(email: email);

  @override
  Future<void> signOut() => _auth.signOut();
}
