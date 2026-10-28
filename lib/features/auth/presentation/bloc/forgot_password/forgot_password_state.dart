part of 'forgot_password_bloc.dart';

class ForgotPasswordState extends Equatable {
  const ForgotPasswordState({
    this.email = const EmailInput.pure(),
    this.status = FormzSubmissionStatus.initial,
    this.submitted = false,
    this.failureKey,
  });

  final EmailInput email;
  final FormzSubmissionStatus status;
  final bool submitted;
  final String? failureKey;

  bool get isLoading => status.isInProgress;
  bool get isSent => status.isSuccess;
  String? get emailError => (submitted || !email.isPure) ? email.error : null;

  ForgotPasswordState copyWith({
    EmailInput? email,
    FormzSubmissionStatus? status,
    bool? submitted,
    String? failureKey,
    bool clearFailure = false,
  }) =>
      ForgotPasswordState(
        email: email ?? this.email,
        status: status ?? this.status,
        submitted: submitted ?? this.submitted,
        failureKey: clearFailure ? null : (failureKey ?? this.failureKey),
      );

  @override
  List<Object?> get props => [email, status, submitted, failureKey];
}
