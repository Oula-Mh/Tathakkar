import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/l10n_keys.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/state_views.dart';
import '../bloc/care_link_bloc.dart';

/// Result of scanning a QR on the caregiver's phone (success / each error).
class CareResultPage extends StatelessWidget {
  const CareResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CareLinkBloc>();
    void done() {
      bloc.add(const CareResultCleared());
      context.go(Routes.home);
    }

    return BlocBuilder<CareLinkBloc, CareLinkState>(
      builder: (context, s) {
        if (s.redeemOp == CareOp.success) {
          return AppScaffold(
            scrollable: false,
            body: MessageView(
              icon: Icons.check_rounded,
              title: context.tr(L.linkSuccess),
              message: context.tr(L.linkSuccessSub, args: {'name': s.redeemedElderName ?? ''}),
              actionLabel: context.tr(L.openProfile, args: {'name': s.redeemedElderName ?? ''}),
              onAction: done,
            ),
          );
        }
        final (icon, titleKey, subKey, retry) = switch (s.failureKey) {
          'err_link_expired' => (Icons.priority_high_rounded, L.linkExpiredTitle, L.linkExpiredSub, true),
          'err_link_invalid' => (Icons.close_rounded, L.linkInvalidTitle, L.linkInvalidSub, true),
          'err_link_already_managed' =>
            (Icons.priority_high_rounded, L.linkAlreadyTitle, L.linkAlreadySub, false),
          'err_link_self' => (Icons.priority_high_rounded, L.linkSelfTitle, L.linkSelfSub, false),
          _ => (Icons.priority_high_rounded, L.linkFailedTitle, L.linkFailedSub, true),
        };
        return AppScaffold(
          scrollable: false,
          showBack: true,
          onBack: done,
          body: MessageView(
            icon: icon,
            iconColor: AppColors.turquoise,
            title: context.tr(titleKey),
            message: context.tr(subKey),
            actionLabel: retry ? context.tr(L.retry) : context.tr(L.backToHome),
            onAction: retry
                ? () {
                    bloc.add(const CareResultCleared());
                    context.pushReplacement(Routes.careScan);
                  }
                : done,
            secondaryLabel: retry ? context.tr(L.back) : null,
            onSecondary: done,
          ),
        );
      },
    );
  }
}

/// Elder's phone: shown right after the caregiver scanned the QR.
class CareLinkedElderPage extends StatelessWidget {
  const CareLinkedElderPage({super.key});

  @override
  Widget build(BuildContext context) => AppScaffold(
        scrollable: false,
        body: MessageView(
          icon: Icons.check_rounded,
          title: context.tr(L.linkSuccess),
          message: context.tr(L.linkSuccessElderSub),
          actionLabel: context.tr(L.backToHome),
          onAction: () => context.go(Routes.home),
        ),
      );
}

class CareUnlinkedPage extends StatelessWidget {
  const CareUnlinkedPage({super.key});

  @override
  Widget build(BuildContext context) => AppScaffold(
        scrollable: false,
        body: MessageView(
          icon: Icons.check_rounded,
          title: context.tr(L.unlinkedTitle),
          message: context.tr(L.unlinkedSub),
          actionLabel: context.tr(L.backToHome),
          onAction: () => context.go(Routes.home),
        ),
      );
}
