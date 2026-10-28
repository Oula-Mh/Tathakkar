part of 'login_bloc.dart';

sealed class LoginEvent extends Equatable {
  const LoginEvent();
  @override
  List<Object?> get props => [];
}

class LoginEmailChanged extends LoginEvent {
  const LoginEmailChanged(this.value);
  final String value;
  @override
  List<Object?> get props => [value];
}

class LoginPasswordChanged extends LoginEvent {
  const LoginPasswordChanged(this.value);
  final String value;
  @override
  List<Object?> get props => [value];
}

class LoginSubmitted extends LoginEvent {
  const LoginSubmitted();
}
