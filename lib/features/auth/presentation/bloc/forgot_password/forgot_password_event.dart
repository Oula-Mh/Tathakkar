part of 'forgot_password_bloc.dart';

sealed class ForgotPasswordEvent extends Equatable {
  const ForgotPasswordEvent();
  @override
  List<Object?> get props => [];
}

class ForgotEmailChanged extends ForgotPasswordEvent {
  const ForgotEmailChanged(this.value);
  final String value;
  @override
  List<Object?> get props => [value];
}

class ForgotSubmitted extends ForgotPasswordEvent {
  const ForgotSubmitted();
}
