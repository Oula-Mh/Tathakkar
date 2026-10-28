import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../localization/app_localizations.dart';
import '../theme/app_theme.dart';
import 'circle_icon_button.dart';
import 'gradient_background.dart';
import 'responsive_body.dart';

/// Standard screen: gradient, safe area, responsive width, optional header.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.titleWidget,
    this.title,
    this.showBack = false,
    this.onBack,
    this.trailing,
    this.bottom,
    this.scrollable = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
    this.strongBackground = false,
    this.bottomBar,
  });

  final Widget body;
  final String? title;
  final Widget? titleWidget;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? trailing;

  /// Pinned action area (buttons) above the keyboard / bottom edge.
  final Widget? bottom;
  final bool scrollable;
  final EdgeInsetsGeometry padding;
  final bool strongBackground;

  /// Pinned bottom navigation bar.
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    final content = scrollable
        ? SingleChildScrollView(
            padding: padding.add(const EdgeInsets.only(bottom: 16)),
            child: body,
          )
        : Padding(padding: padding, child: body);

    final scaffold = Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ResponsiveBody(
          child: Column(
            children: [
              if (title != null || showBack || trailing != null)
                _Header(
                  title: title,
                  titleWidget: titleWidget,
                  showBack: showBack,
                  onBack: onBack,
                  trailing: trailing,
                ),
              Expanded(child: content),
              if (bottom != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: bottom,
                ),
              if (bottomBar != null) bottomBar!,
            ],
          ),
        ),
      ),
    );
    return BackgroundScope.exists(context)
        ? scaffold
        : GradientBackground(strong: strongBackground, child: scaffold);
  }
}

// class _Header extends StatelessWidget {
//   const _Header({this.title, required this.showBack, this.onBack, this.trailing});
//   final String? title;
//   final bool showBack;
//   final VoidCallback? onBack;
//   final Widget? trailing;

//   @override
//   Widget build(BuildContext context) {
//     final backButton = showBack
//         ? CircleIconButton(
//             icon: Icons.arrow_back_rounded,
//             tooltip: context.tr('back'),
//             onPressed: onBack ?? () => context.pop(),
//           )
//         : null;

//     return Padding(
//       padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
//       child: Row(
//         children: [
//           if (backButton != null) ...[
//             backButton,
//             const SizedBox(width: 10),
//           ],

//           if (title != null)
//             Expanded(
//               child: Text(
//                 title!,
//                 style: context.textStyles.headlineSmall?.copyWith(
//                   fontWeight: FontWeight.w700,
//                   color: context.inkColor,
//                 ),
//               ),
//             )
//           else
//             const Spacer(),

//           if (trailing != null) ...[
//             const SizedBox(width: 10),
//             trailing!,
//           ],
//         ],
//       ),
//     );
//   }
// }
class _Header extends StatelessWidget {
  const _Header({
    this.title,
    this.titleWidget, // 🔹
    required this.showBack,
    this.onBack,
    this.trailing,
  });

  final String? title;
  final Widget? titleWidget; // 🔹
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final backButton = showBack
        ? CircleIconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: context.tr('back'),
            onPressed: onBack ?? () => context.pop(),
          )
        : null;

    final titleContent =
        titleWidget ??
        (title != null
            ? Text(
                title!,
                style: context.textStyles.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.inkColor,
                ),
              )
            : const SizedBox.shrink());

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Row(
        children: [
          if (backButton != null) ...[backButton, const SizedBox(width: 10)],
          Expanded(child: titleContent),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ],
      ),
    );
  }
}
