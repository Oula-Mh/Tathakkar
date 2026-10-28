import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({required super.id, required super.name, required super.email});

  factory UserModel.fromFirebase(fb.User u) => UserModel(
        id: u.uid,
        name: (u.displayName ?? '').trim().isEmpty ? (u.email ?? '').split('@').first : u.displayName!,
        email: u.email ?? '',
      );
}
