import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/l10n_keys.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/switch_row.dart';
import '../../../auth/presentation/bloc/session/session_bloc.dart';
import '../../../care_link/presentation/bloc/care_link_bloc.dart';
import '../../../profiles/presentation/bloc/profiles_bloc.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionBloc>().state;
    final user = session is SessionAuthenticated ? session.user : null;
    final settings = context.watch<SettingsBloc>().state.settings;
    final caregiver = context.watch<CareLinkBloc>().state.caregiver;
    final familyCount = context.watch<ProfilesBloc>().state.profiles.length;

    return AppScaffold(
      title: context.tr(L.accountTitle),
      body: Column(children: [
        GlassCard(
          child: Row(children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.turquoise,
              child: Text(user?.initial ?? '?',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user?.name ?? '', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                Text(user?.email ?? '',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(color: context.inkSoftColor)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        _Section(title: context.tr(L.remindersAndNotifications), children: [
          _NavRow(
            icon: Icons.alarm_rounded,
            label: context.tr(L.reminderSettings),
            onTap: () => context.push(Routes.reminderSettings),
          ),
        ]),
        _Section(title: context.tr(L.careAndFamily), children: [
          _NavRow(
            icon: Icons.favorite_outline_rounded,
            label: context.tr(L.linkCaregiver),
            value: caregiver?.caregiverName ?? context.tr(L.none),
            onTap: () => context.push(Routes.care),
          ),
          _NavRow(
            icon: Icons.groups_rounded,
            label: context.tr(L.familyTitle),
            value: context.tr(L.membersCount, args: {'n': '$familyCount'}),
            onTap: () => context.push(Routes.family),
          ),
        ]),
        _Section(title: context.tr(L.appSettings), children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              Expanded(child: Text(context.tr(L.language), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 'ar', label: Text('العربية')),
                  ButtonSegment(value: 'en', label: Text('English')),
                ],
                selected: {settings.languageCode},
                onSelectionChanged: (s) => context.read<SettingsBloc>().add(LanguageChanged(s.first)),
              ),
            ]),
          ),
          SwitchRow(
            label: context.tr(L.darkMode),
            value: settings.darkMode,
            onChanged: (v) => context.read<SettingsBloc>().add(DarkModeChanged(v)),
          ),
        ]),
        const SizedBox(height: 8),
        AppButton(
          label: context.tr(L.logout),
          variant: AppButtonVariant.secondary,
          icon: Icons.logout_rounded,
          onPressed: () async {
            final bloc = context.read<SessionBloc>();
            final ok = await ConfirmDialog.show(
              context,
              title: context.tr(L.logout),
              message: context.tr(L.logoutConfirm),
              confirmLabel: context.tr(L.logout),
              destructive: true,
            );
            if (ok) bloc.add(const SessionLogoutRequested());
          },
        ),
      ]),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: context.inkSoftColor)),
          ),
          GlassCard(blur: 0, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), child: Column(children: children)),
        ]),
      );
}

class _NavRow extends StatelessWidget {
  const _NavRow({required this.icon, required this.label, required this.onTap, this.value});
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(children: [
            Icon(icon, color: context.primaryColor),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
            if (value != null) Text(value!, style: TextStyle(color: context.inkSoftColor)),
            Icon(Icons.chevron_right_rounded, color: context.inkSoftColor),
          ]),
        ),
      );
}
