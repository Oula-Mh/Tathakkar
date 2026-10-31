import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/l10n_keys.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../home/presentation/widgets/profile_switcher.dart';
import '../bloc/profiles_bloc.dart';

class FamilyPage extends StatelessWidget {
  const FamilyPage({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<ProfilesBloc, ProfilesState>(
        builder: (context, s) => AppScaffold(
          showBack: true,
          title: context.tr(L.familyTitle),
          bottom: AppButton(
            label: context.tr(L.addFamilyMember),
            onPressed: () => context.push(Routes.familyAdd),
          ),
          body: s.status == ProfilesStatus.failure
              ? SizedBox(
                  height: 300,
                  child: ErrorView(
                    messageKey: s.failureKey ?? 'err_unknown',
                    onRetry: () => context.read<ProfilesBloc>().add(const ProfilesRetryRequested()),
                  ))
              : Column(children: [
                  for (final p in s.profiles)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        blur: 0,
                        borderColor: p.key == s.selected?.key ? AppColors.turquoise : null,
                        onTap: () {
                          context.read<ProfilesBloc>().add(ProfileSelected(p.key));
                          context.go(Routes.home);
                        },
                        child: Row(children: [
                          ProfileAvatar(profile: p, size: 48),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(profileLabel(context, p),
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                              Text(
                                p.isSelf
                                    ? context.tr(L.personalProfile)
                                    : p.isRemote
                                        ? context.tr(L.remoteCare)
                                        : context.tr(L.onThisDevice),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ]),
                          ),
                          if (p.key == s.selected?.key)
                            StatusChip(label: context.tr(L.activeProfile), tone: ChipTone.success),
                        ]),
                      ),
                    ),
                ]),
        ),
      );
}
