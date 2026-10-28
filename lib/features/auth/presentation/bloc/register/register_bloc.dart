import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';

import '../../../../../core/forms/form_inputs.dart';
import '../../../domain/usecases/auth_usecases.dart';

part 'register_event.dart';
part 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  RegisterBloc(this._register) : super(const RegisterState()) {
    on<RegisterNameChanged>((e, emit) =>
        emit(state.copyWith(name: NameInput.dirty(e.value), clearFailure: true)));
    on<RegisterEmailChanged>((e, emit) =>
        emit(state.copyWith(email: EmailInput.dirty(e.value), clearFailure: true)));
    on<RegisterPasswordChanged>(_onPassword);
    on<RegisterConfirmChanged>((e, emit) => emit(state.copyWith(
          confirm: ConfirmPasswordInput.dirty(password: state.password.value, value: e.value),
          clearFailure: true,
        )));
    on<RegisterTermsToggled>((e, emit) => emit(state.copyWith(acceptedTerms: e.accepted)));
    on<RegisterSubmitted>(_onSubmitted);
  }

  final RegisterUser _register;

  void _onPassword(RegisterPasswordChanged e, Emitter<RegisterState> emit) {
    final password = PasswordInput.dirty(e.value);
    // Re-validate confirmation against the new password if already typed.
    final confirm = state.confirm.isPure
        ? state.confirm
        : ConfirmPasswordInput.dirty(password: e.value, value: state.confirm.value);
    emit(state.copyWith(password: password, confirm: confirm, clearFailure: true));
  }

  Future<void> _onSubmitted(RegisterSubmitted event, Emitter<RegisterState> emit) async {
    if (state.isLoading) return;
    final name = NameInput.dirty(state.name.value);
    final email = EmailInput.dirty(state.email.value);
    final password = PasswordInput.dirty(state.password.value);
    final confirm =
        ConfirmPasswordInput.dirty(password: password.value, value: state.confirm.value);

    final valid = Formz.validate([name, email, password, confirm]) && state.acceptedTerms;
    if (!valid) {
      emit(state.copyWith(
          name: name, email: email, password: password, confirm: confirm, submitted: true));
      return;
    }
    emit(state.copyWith(
      name: name,
      email: email,
      password: password,
      confirm: confirm,
      submitted: true,
      status: FormzSubmissionStatus.inProgress,
      clearFailure: true,
    ));
    final result = await _register(
        RegisterParams(name: name.value, email: email.value, password: password.value));
    result.fold(
      (f) => emit(state.copyWith(status: FormzSubmissionStatus.failure, failureKey: f.messageKey)),
      (_) => emit(state.copyWith(status: FormzSubmissionStatus.success)),
    );
  }
}
