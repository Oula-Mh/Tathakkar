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
import '../bloc/forgot_password/forgot_password_bloc.dart';
import '../widgets/auth_layout.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => getIt<ForgotPasswordBloc>(),
        child: const _ForgotView(),
      );
}

class _ForgotView extends StatelessWidget {
  const _ForgotView();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ForgotPasswordBloc>();
    return BlocConsumer<ForgotPasswordBloc, ForgotPasswordState>(
      listenWhen: (p, c) => p.failureKey != c.failureKey && c.failureKey != null,
      listener: (context, s) => AppSnackbar.show(context, context.tr(s.failureKey!), error: true),
      builder: (context, s) => AuthLayout(
        showBack: true,
        title: context.tr(L.resetTitle),
        subtitle: context.tr(L.resetSub),
        footer: TextButton(
          onPressed: () => context.pop(),
          child: Text(context.tr(L.backToLogin)),
        ),
        children: [
          AppTextField(
            label: context.tr(L.email),
            hint: 'name@mail.com',
            forceLtr: true,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            errorText: s.emailError == null ? null : context.tr(s.emailError!),
            onChanged: (v) => bloc.add(ForgotEmailChanged(v)),
            onSubmitted: (_) => bloc.add(const ForgotSubmitted()),
          ),
          if (s.isSent) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(context.tr(L.resetSent),
                        style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          AppButton(
            label: context.tr(s.isSent ? L.resend : L.send),
            isLoading: s.isLoading,
            onPressed: () => bloc.add(const ForgotSubmitted()),
          ),
        ],
      ),
    );
  }
}
