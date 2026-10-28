part of 'register_bloc.dart';

class RegisterState extends Equatable {
  const RegisterState({
    this.name = const NameInput.pure(),
    this.email = const EmailInput.pure(),
    this.password = const PasswordInput.pure(),
    this.confirm = const ConfirmPasswordInput.pure(),
    this.acceptedTerms = false,
    this.status = FormzSubmissionStatus.initial,
    this.submitted = false,
    this.failureKey,
  });

  final NameInput name;
  final EmailInput email;
  final PasswordInput password;
  final ConfirmPasswordInput confirm;
  final bool acceptedTerms;
  final FormzSubmissionStatus status;
  final bool submitted;
  final String? failureKey;

  bool get isLoading => status.isInProgress;

  String? get nameError => (submitted || !name.isPure) ? name.error : null;
  String? get emailError => (submitted || !email.isPure) ? email.error : null;
  String? get passwordError => (submitted || !password.isPure) ? password.error : null;
  String? get confirmError => (submitted || !confirm.isPure) ? confirm.error : null;
  bool get termsError => submitted && !acceptedTerms;

  RegisterState copyWith({
    NameInput? name,
    EmailInput? email,
    PasswordInput? password,
    ConfirmPasswordInput? confirm,
    bool? acceptedTerms,
    FormzSubmissionStatus? status,
    bool? submitted,
    String? failureKey,
    bool clearFailure = false,
  }) =>
      RegisterState(
        name: name ?? this.name,
        email: email ?? this.email,
        password: password ?? this.password,
        confirm: confirm ?? this.confirm,
        acceptedTerms: acceptedTerms ?? this.acceptedTerms,
        status: status ?? this.status,
        submitted: submitted ?? this.submitted,
        failureKey: clearFailure ? null : (failureKey ?? this.failureKey),
      );

  @override
  List<Object?> get props =>
      [name, email, password, confirm, acceptedTerms, status, submitted, failureKey];
}
