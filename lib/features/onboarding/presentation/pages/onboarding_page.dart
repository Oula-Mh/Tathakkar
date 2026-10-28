import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/l10n_keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../bloc/onboarding_bloc.dart';
import '../widgets/onboarding_illustrations.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => OnboardingBloc(),
        child: const _OnboardingView(),
      );
}

class _OnboardingView extends StatefulWidget {
  const _OnboardingView();

  @override
  State<_OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<_OnboardingView> {
  final _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() => context.read<SettingsBloc>().add(const OnboardingCompleted());

  void _next(OnboardingState s) {
    if (s.isLast) {
      _finish();
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      (const OnboardingDosePreview(), L.onb1Title, L.onb1Sub),
      (const OnboardingListPreview(), L.onb2Title, L.onb2Sub),
      (const OnboardingFamilyPreview(), L.onb3Title, L.onb3Sub),
    ];

    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, s) => AppScaffold(
        scrollable: false,
        padding: EdgeInsets.zero,
        trailing: s.isLast
            ? null
            : TextButton(onPressed: _finish, child: Text(context.tr(L.skip))),
        title: '',
        bottom: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppButton(
              label: context.tr(s.isLast ? L.startNow : L.next),
              onPressed: () => _next(s),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (i) => context.read<OnboardingBloc>().add(OnboardingPageChanged(i)),
                itemBuilder: (context, i) {
                  final (illustration, title, sub) = pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Expanded(child: Center(child: illustration)),
                        Text(
                          context.tr(title),
                          textAlign: TextAlign.center,
                          style: context.textStyles.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          context.tr(sub),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15.5, height: 1.6, color: context.inkSoftColor),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
              ),
            ),
            SmoothPageIndicator(
              controller: _controller,
              count: pages.length,
              effect: ExpandingDotsEffect(
                dotHeight: 8,
                dotWidth: 8,
                expansionFactor: 3.5,
                activeDotColor: context.primaryColor,
                dotColor: AppColors.platinum,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
