part of 'register_bloc.dart';

sealed class RegisterEvent extends Equatable {
  const RegisterEvent();
  @override
  List<Object?> get props => [];
}

class RegisterNameChanged extends RegisterEvent {
  const RegisterNameChanged(this.value);
  final String value;
  @override
  List<Object?> get props => [value];
}

class RegisterEmailChanged extends RegisterEvent {
  const RegisterEmailChanged(this.value);
  final String value;
  @override
  List<Object?> get props => [value];
}

class RegisterPasswordChanged extends RegisterEvent {
  const RegisterPasswordChanged(this.value);
  final String value;
  @override
  List<Object?> get props => [value];
}

class RegisterConfirmChanged extends RegisterEvent {
  const RegisterConfirmChanged(this.value);
  final String value;
  @override
  List<Object?> get props => [value];
}

class RegisterTermsToggled extends RegisterEvent {
  const RegisterTermsToggled(this.accepted);
  final bool accepted;
  @override
  List<Object?> get props => [accepted];
}

class RegisterSubmitted extends RegisterEvent {
  const RegisterSubmitted();
}
