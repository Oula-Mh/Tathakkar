import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/glass_card.dart';

/// Shared frame for login / register / forgot password.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.showBack = false,
    this.footer,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool showBack;
  final Widget? footer;

  @override
  Widget build(BuildContext context) => AppScaffold(
        showBack: showBack,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              title,
              style: context.textStyles.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(fontSize: 15.5, height: 1.5, color: context.inkSoftColor)),
            const SizedBox(height: 24),
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: AutofillGroup(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
              ),
            ),
            if (footer != null) ...[const SizedBox(height: 20), Center(child: footer!)],
          ],
        ),
      );
}

class AuthSwitchLink extends StatelessWidget {
  const AuthSwitchLink({super.key, required this.prompt, required this.action, required this.onTap});
  final String prompt;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(prompt, style: TextStyle(color: context.inkSoftColor, fontSize: 15)),
          TextButton(
            onPressed: onTap,
            child: Text(action, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
          ),
        ],
      );
}
