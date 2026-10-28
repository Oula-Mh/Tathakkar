import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formz/formz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tathakkar/core/errors/failures.dart';
import 'package:tathakkar/features/auth/domain/entities/user_entity.dart';
import 'package:tathakkar/features/auth/domain/usecases/auth_usecases.dart';
import 'package:tathakkar/features/auth/presentation/bloc/login/login_bloc.dart';

class MockSignIn extends Mock implements SignIn {}

void main() {
  late MockSignIn signIn;
  setUpAll(() => registerFallbackValue(const Credentials('a', 'b')));
  setUp(() => signIn = MockSignIn());

  blocTest<LoginBloc, LoginState>(
    'empty submit shows errors and does not call the use case',
    build: () => LoginBloc(signIn),
    act: (b) => b.add(const LoginSubmitted()),
    verify: (b) {
      expect(b.state.emailError, isNotNull);
      expect(b.state.passwordError, isNotNull);
      verifyNever(() => signIn(any()));
    },
  );

  blocTest<LoginBloc, LoginState>(
    'valid submit succeeds',
    build: () {
      when(() => signIn(any())).thenAnswer(
          (_) async => const Right(UserEntity(id: '1', name: 'Sara', email: 'sara@mail.com')));
      return LoginBloc(signIn);
    },
    act: (b) => b
      ..add(const LoginEmailChanged('sara@mail.com'))
      ..add(const LoginPasswordChanged('password1'))
      ..add(const LoginSubmitted()),
    verify: (b) => expect(b.state.status, FormzSubmissionStatus.success),
  );

  blocTest<LoginBloc, LoginState>(
    'wrong credentials expose a localized failure key',
    build: () {
      when(() => signIn(any()))
          .thenAnswer((_) async => const Left(AuthFailure('err_auth_invalid_credentials')));
      return LoginBloc(signIn);
    },
    act: (b) => b
      ..add(const LoginEmailChanged('sara@mail.com'))
      ..add(const LoginPasswordChanged('wrongpass'))
      ..add(const LoginSubmitted()),
    verify: (b) => expect(b.state.failureKey, 'err_auth_invalid_credentials'),
  );
}
