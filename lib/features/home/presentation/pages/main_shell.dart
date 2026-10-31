import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/l10n_keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bottom_nav.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/responsive_body.dart';
import '../../../connectivity/presentation/bloc/connectivity_bloc.dart';

/// Bottom navigation + offline banner around the four main tabs.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final items = [
      NavItem(Icons.home_outlined, context.tr(L.navHome)),
      NavItem(Icons.medication_outlined, context.tr(L.navMedications)),
      NavItem(Icons.history_rounded, context.tr(L.navHistory)),
      NavItem(Icons.person_outline_rounded, context.tr(L.navAccount)),
    ];
    return GradientBackground(
      strong: true,

      child: BackgroundScope(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              BlocBuilder<ConnectivityBloc, ConnectivityState>(
                builder: (context, s) => s.online
                    ? const SizedBox.shrink()
                    : SafeArea(
                        bottom: false,
                        child: Container(
                          width: double.infinity,
                          color: AppColors.warningBg,
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 16,
                          ),
                          child: Text(
                            context.tr(L.offlineBanner),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
              ),
              Expanded(
                child: MediaQuery.removePadding(
                  context: context,
                  removeBottom: true,
                  child: shell,
                ),
              ),
              SafeArea(
                top: false,
                child: ResponsiveBody(
                  child: GlassBottomNav(
                    items: items,
                    index: shell.currentIndex,
                    onTap: (i) => shell.goBranch(
                      i,
                      initialLocation: i == shell.currentIndex,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
