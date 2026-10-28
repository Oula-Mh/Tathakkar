import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/forms/form_inputs.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/l10n_keys.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/glass_card.dart';
import '../bloc/profiles_bloc.dart';

/// Choose how to add a person: local profile or link a remote account.
class AddFamilyPage extends StatelessWidget {
  const AddFamilyPage({super.key});

  @override
  Widget build(BuildContext context) => AppScaffold(
        showBack: true,
        title: context.tr(L.addFamilyMember),
        body: Column(children: [
          _OptionCard(
            title: context.tr(L.createLocalProfile),
            subtitle: context.tr(L.createLocalProfileSub),
            icon: Icons.phone_android_rounded,
            onTap: () => context.push(Routes.familyAddLocal),
          ),
          const SizedBox(height: 12),
          _OptionCard(
            title: context.tr(L.linkExistingAccount),
            subtitle: context.tr(L.linkExistingAccountSub),
            icon: Icons.qr_code_scanner_rounded,
            onTap: () => context.push(Routes.careScan),
          ),
        ]),
      );
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({required this.title, required this.subtitle, required this.icon, required this.onTap});
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GlassCard(
        onTap: onTap,
        child: Row(children: [
          Icon(icon, size: 32, color: context.primaryColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(height: 1.5, color: context.inkSoftColor)),
            ]),
          ),
        ]),
      );
}

class AddLocalProfilePage extends StatefulWidget {
  const AddLocalProfilePage({super.key});

  @override
  State<AddLocalProfilePage> createState() => _AddLocalProfilePageState();
}

class _AddLocalProfilePageState extends State<AddLocalProfilePage> {
  NameInput _name = const NameInput.pure();
  String _relation = L.relChild;
  bool _submitted = false;

  static const _relations = [L.relChild, L.relParent, L.relSpouse, L.relOther];

  void _submit() {
    final name = NameInput.dirty(_name.value);
    setState(() {
      _name = name;
      _submitted = true;
    });
    if (name.isNotValid) return;
    context.read<ProfilesBloc>().add(LocalProfileAdded(name: name.value, relation: _relation));
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<ProfilesBloc, ProfilesState>(
        listenWhen: (p, c) => p.addedCount != c.addedCount || p.addFailureKey != c.addFailureKey,
        listener: (context, s) {
          if (s.addFailureKey != null) {
            AppSnackbar.show(context, context.tr(s.addFailureKey!), error: true);
          } else {
            context.go(Routes.home);
          }
        },
        builder: (context, s) => AppScaffold(
          showBack: true,
          title: context.tr(L.createLocalProfile),
          bottom: AppButton(label: context.tr(L.save), isLoading: s.adding, onPressed: _submit),
          body: GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AppTextField(
                label: context.tr(L.fullName),
                textInputAction: TextInputAction.done,
                errorText: (_submitted || !_name.isPure) && _name.error != null ? context.tr(_name.error!) : null,
                onChanged: (v) => setState(() => _name = NameInput.dirty(v)),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 16),
              Text(context.tr(L.relation),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.inkSoftColor)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                for (final r in _relations)
                  ChoiceChip(
                    label: Text(context.tr(r)),
                    selected: _relation == r,
                    onSelected: (_) => setState(() => _relation = r),
                  ),
              ]),
            ]),
          ),
        ),
      );
}
