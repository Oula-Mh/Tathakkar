part of 'login_bloc.dart';

class LoginState extends Equatable {
  const LoginState({
    this.email = const EmailInput.pure(),
    this.password = const LoginPasswordInput.pure(),
    this.status = FormzSubmissionStatus.initial,
    this.submitted = false,
    this.failureKey,
  });

  final EmailInput email;
  final LoginPasswordInput password;
  final FormzSubmissionStatus status;
  final bool submitted;
  final String? failureKey;

  bool get isLoading => status.isInProgress;

  /// Errors are shown after the field was touched or after a submit attempt.
  String? get emailError => (submitted || !email.isPure) ? email.error : null;
  String? get passwordError => (submitted || !password.isPure) ? password.error : null;

  LoginState copyWith({
    EmailInput? email,
    LoginPasswordInput? password,
    FormzSubmissionStatus? status,
    bool? submitted,
    String? failureKey,
    bool clearFailure = false,
  }) =>
      LoginState(
        email: email ?? this.email,
        password: password ?? this.password,
        status: status ?? this.status,
        submitted: submitted ?? this.submitted,
        failureKey: clearFailure ? null : (failureKey ?? this.failureKey),
      );

  @override
  List<Object?> get props => [email, password, status, submitted, failureKey];
}
