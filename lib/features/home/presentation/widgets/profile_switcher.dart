import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/l10n_keys.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../profiles/domain/entities/person_profile.dart';
import '../../../profiles/presentation/bloc/profiles_bloc.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.profile, this.size = 44});
  final PersonProfile profile;
  final double size;

  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: size / 2,
        backgroundColor: profile.isRemote ? AppColors.slateBlue : AppColors.turquoise,
        child: Text(profile.initial,
            style: TextStyle(color: Colors.white, fontSize: size * 0.42, fontWeight: FontWeight.w800)),
      );
}

String profileLabel(BuildContext c, PersonProfile p) =>
    p.isSelf ? '${p.name} (${c.tr(L.me)})' : p.name;

/// Header chip: shows the active person, tap to switch.
class ProfileSwitcher extends StatelessWidget {
  const ProfileSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProfilesBloc>().state;
    final p = state.selected;
    if (p == null) return const SizedBox.shrink();
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: state.profiles.length > 1 ? () => _open(context) : null,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        ProfileAvatar(profile: p),
        const SizedBox(width: 10),
        Flexible(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.tr(L.greetingMorning),
                style: TextStyle(fontSize: 12.5, color: context.inkSoftColor)),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Flexible(
                child: Text(profileLabel(context, p),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              if (state.profiles.length > 1) const Icon(Icons.keyboard_arrow_down_rounded),
            ]),
          ]),
        ),
      ]),
    );
  }

  void _open(BuildContext context) {
    final bloc = context.read<ProfilesBloc>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GlassCard(
            tint: ctx.isDark ? null : Colors.white.withValues(alpha: 0.95),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              for (final p in bloc.state.profiles)
                ListTile(
                  leading: ProfileAvatar(profile: p),
                  title: Text(profileLabel(ctx, p), style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: p.isRemote ? Text(ctx.tr(L.remoteCare)) : null,
                  trailing: p.key == bloc.state.selected?.key
                      ? const Icon(Icons.check_circle, color: AppColors.turquoise)
                      : null,
                  onTap: () {
                    bloc.add(ProfileSelected(p.key));
                    Navigator.pop(ctx);
                  },
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.groups_rounded),
                title: Text(ctx.tr(L.familyTitle)),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(Routes.family);
                },
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Small context chip shown under the header for remote / managed profiles.
class ProfileContextBanner extends StatelessWidget {
  const ProfileContextBanner({super.key, required this.profile});
  final PersonProfile profile;

  @override
  Widget build(BuildContext context) {
    if (profile.isRemote) {
      return StatusChip(label: context.tr(L.remoteCare), tone: ChipTone.info, icon: Icons.favorite_outline);
    }
    if (profile.isSelf && profile.managedByUid != null) {
      return StatusChip(label: context.tr(L.managedByCaregiver), tone: ChipTone.info, icon: Icons.lock_outline);
    }
    return const SizedBox.shrink();
  }
}
