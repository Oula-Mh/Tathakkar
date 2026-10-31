import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/l10n_keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/register/register_bloc.dart';
import '../widgets/auth_layout.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<RegisterBloc>(),
    child: const _RegisterView(),
  );
}

class _RegisterView extends StatelessWidget {
  const _RegisterView();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<RegisterBloc>();
    String? err(String? key) => key == null ? null : context.tr(key);

    return BlocConsumer<RegisterBloc, RegisterState>(
      listenWhen: (p, c) =>
          p.failureKey != c.failureKey && c.failureKey != null,
      listener: (context, s) =>
          AppSnackbar.show(context, context.tr(s.failureKey!), error: true),
      builder: (context, s) => AuthLayout(
        // showBack: true,
        title: context.tr(L.createAccountTitle),
        subtitle: context.tr(L.createAccountSub),
        footer: AuthSwitchLink(
          prompt: context.tr(L.haveAccount),
          action: context.tr(L.loginButton),
          onTap: () => context.pop(),
        ),
        children: [
          AppTextField(
            label: context.tr(L.fullName),
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            errorText: err(s.nameError),
            onChanged: (v) => bloc.add(RegisterNameChanged(v)),
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: context.tr(L.email),
            hint: 'name@mail.com',
            forceLtr: true,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            errorText: err(s.emailError),
            onChanged: (v) => bloc.add(RegisterEmailChanged(v)),
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: context.tr(L.password),
            obscure: true,
            forceLtr: true,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            errorText: err(s.passwordError),
            onChanged: (v) => bloc.add(RegisterPasswordChanged(v)),
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: context.tr(L.confirmPassword),
            obscure: true,
            forceLtr: true,
            textInputAction: TextInputAction.done,
            errorText: err(s.confirmError),
            onChanged: (v) => bloc.add(RegisterConfirmChanged(v)),
            onSubmitted: (_) => bloc.add(const RegisterSubmitted()),
          ),
          const SizedBox(height: 10),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: s.acceptedTerms,
            onChanged: (v) => bloc.add(RegisterTermsToggled(v ?? false)),
            title: Text(
              context.tr(L.acceptTerms),
              style: const TextStyle(fontSize: 14.5),
            ),
            subtitle: s.termsError
                ? Text(
                    context.tr(L.errTermsRequired),
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 13,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 10),
          AppButton(
            label: context.tr(L.createAccount),
            isLoading: s.isLoading,
            onPressed: () => bloc.add(const RegisterSubmitted()),
          ),
        ],
      ),
    );
  }
}
