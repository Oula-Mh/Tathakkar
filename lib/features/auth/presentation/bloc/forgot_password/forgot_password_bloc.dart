import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';

import '../../../../../core/forms/form_inputs.dart';
import '../../../domain/usecases/auth_usecases.dart';

part 'forgot_password_event.dart';
part 'forgot_password_state.dart';

class ForgotPasswordBloc extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  ForgotPasswordBloc(this._send) : super(const ForgotPasswordState()) {
    on<ForgotEmailChanged>((e, emit) => emit(state.copyWith(
          email: EmailInput.dirty(e.value),
          status: FormzSubmissionStatus.initial,
          clearFailure: true,
        )));
    on<ForgotSubmitted>(_onSubmitted);
  }

  final SendPasswordReset _send;

  Future<void> _onSubmitted(ForgotSubmitted event, Emitter<ForgotPasswordState> emit) async {
    if (state.isLoading) return;
    final email = EmailInput.dirty(state.email.value);
    if (email.isNotValid) {
      emit(state.copyWith(email: email, submitted: true));
      return;
    }
    emit(state.copyWith(
        email: email, submitted: true, status: FormzSubmissionStatus.inProgress, clearFailure: true));
    final result = await _send(email.value);
    result.fold(
      (f) => emit(state.copyWith(status: FormzSubmissionStatus.failure, failureKey: f.messageKey)),
      (_) => emit(state.copyWith(status: FormzSubmissionStatus.success)),
    );
  }
}
