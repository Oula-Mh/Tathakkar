import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/l10n_keys.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/login/login_bloc.dart';
import '../widgets/auth_layout.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<LoginBloc>(),
    child: const _LoginView(),
  );
}

class _LoginView extends StatelessWidget {
  const _LoginView();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<LoginBloc>();
    return BlocConsumer<LoginBloc, LoginState>(
      listenWhen: (p, c) =>
          p.failureKey != c.failureKey && c.failureKey != null,
      listener: (context, s) =>
          AppSnackbar.show(context, context.tr(s.failureKey!), error: true),
      builder: (context, s) => AuthLayout(
        title: context.tr(L.welcomeBack),
        subtitle: context.tr(L.welcomeBackSub),
        footer: AuthSwitchLink(
          prompt: context.tr(L.noAccount),
          action: context.tr(L.createAccount),
          onTap: () => context.push(Routes.register),
        ),
        children: [
          AppTextField(
            label: context.tr(L.email),
            hint: 'name@mail.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            errorText: s.emailError == null ? null : context.tr(s.emailError!),
            onChanged: (v) => bloc.add(LoginEmailChanged(v)),
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: context.tr(L.password),
            obscure: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            errorText: s.passwordError == null
                ? null
                : context.tr(s.passwordError!),
            onChanged: (v) => bloc.add(LoginPasswordChanged(v)),
            onSubmitted: (_) => bloc.add(const LoginSubmitted()),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: () => context.push(Routes.forgotPassword),
              child: Text(context.tr(L.forgotPassword)),
            ),
          ),
          const SizedBox(height: 8),
          AppButton(
            label: context.tr(L.loginButton),
            isLoading: s.isLoading,
            onPressed: () => bloc.add(const LoginSubmitted()),
          ),
        ],
      ),
    );
  }
}
