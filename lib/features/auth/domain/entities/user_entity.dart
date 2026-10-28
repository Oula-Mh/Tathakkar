import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  const UserEntity({required this.id, required this.name, required this.email});
  final String id;
  final String name;
  final String email;

  String get initial => name.trim().isEmpty ? '?' : String.fromCharCode(name.trim().runes.first);

  @override
  List<Object?> get props => [id, name, email];
}
