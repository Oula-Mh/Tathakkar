import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';

import '../../../../../core/forms/form_inputs.dart';
import '../../../domain/usecases/auth_usecases.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc(this._signIn) : super(const LoginState()) {
    on<LoginEmailChanged>((e, emit) =>
        emit(state.copyWith(email: EmailInput.dirty(e.value), clearFailure: true)));
    on<LoginPasswordChanged>((e, emit) =>
        emit(state.copyWith(password: LoginPasswordInput.dirty(e.value), clearFailure: true)));
    on<LoginSubmitted>(_onSubmitted);
  }

  final SignIn _signIn;

  Future<void> _onSubmitted(LoginSubmitted event, Emitter<LoginState> emit) async {
    if (state.isLoading) return;
    final email = EmailInput.dirty(state.email.value);
    final password = LoginPasswordInput.dirty(state.password.value);
    if (!Formz.validate([email, password])) {
      emit(state.copyWith(email: email, password: password, submitted: true));
      return;
    }
    emit(state.copyWith(
      email: email,
      password: password,
      submitted: true,
      status: FormzSubmissionStatus.inProgress,
      clearFailure: true,
    ));
    final result = await _signIn(Credentials(email.value, password.value));
    result.fold(
      (f) => emit(state.copyWith(status: FormzSubmissionStatus.failure, failureKey: f.messageKey)),
      (_) => emit(state.copyWith(status: FormzSubmissionStatus.success)),
    );
  }
}
