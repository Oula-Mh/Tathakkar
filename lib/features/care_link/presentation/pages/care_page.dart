import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/l10n_keys.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/status_chip.dart';
import '../bloc/care_link_bloc.dart';

/// "Link a caregiver" (elder side) + "scan to care for someone" (caregiver side).
class CarePage extends StatelessWidget {
  const CarePage({super.key});

  @override
  Widget build(BuildContext context) => BlocConsumer<CareLinkBloc, CareLinkState>(
        listenWhen: (p, c) => p.unlinkOp != c.unlinkOp,
        listener: (context, s) {
          if (s.unlinkOp == CareOp.success) {
            context.read<CareLinkBloc>().add(const CareResultCleared());
            context.pushReplacement(Routes.careUnlinked);
          } else if (s.unlinkOp == CareOp.failure) {
            AppSnackbar.show(context, context.tr(s.failureKey ?? 'err_unknown'), error: true);
          }
        },
        builder: (context, s) {
          final cg = s.caregiver;
          return AppScaffold(
            showBack: true,
            title: context.tr(L.linkCaregiver),
            body: Column(children: [
              if (cg != null) ...[
                GlassCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(context.tr(L.currentCaregiver),
                              style: TextStyle(fontSize: 13, color: context.inkSoftColor)),
                          Text(cg.caregiverName,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                        ]),
                      ),
                      StatusChip(label: context.tr(L.linked), tone: ChipTone.success),
                    ]),
                  ]),
                ),
                const SizedBox(height: 12),
                GlassCard(
                  blur: 0,
                  child: Text(context.tr(L.caregiverCanManage),
                      style: TextStyle(fontSize: 14.5, height: 1.6, color: context.inkSoftColor)),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: context.tr(L.unlinkCaregiver),
                  variant: AppButtonVariant.danger,
                  isLoading: s.unlinkOp == CareOp.working,
                  onPressed: () async {
                    final bloc = context.read<CareLinkBloc>();
                    final ok = await ConfirmDialog.show(
                      context,
                      title: context.tr(L.unlinkTitle, args: {'name': cg.caregiverName}),
                      message: context.tr(L.unlinkMessage),
                      confirmLabel: context.tr(L.unlinkConfirm),
                      destructive: true,
                    );
                    if (ok) bloc.add(const CareUnlinkRequested());
                  },
                ),
              ] else ...[
                GlassCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(context.tr(L.noCaregiver),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(context.tr(L.oneCaregiverNote),
                        style: TextStyle(height: 1.6, color: context.inkSoftColor)),
                    const SizedBox(height: 16),
                    AppButton(
                      label: context.tr(L.showQr),
                      icon: Icons.qr_code_2_rounded,
                      onPressed: () => context.push(Routes.careQr),
                    ),
                  ]),
                ),
              ],
              const SizedBox(height: 16),
              GlassCard(
                blur: 0,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(context.tr(L.iAmCaregiver),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(context.tr(L.iAmCaregiverSub),
                      style: TextStyle(height: 1.6, color: context.inkSoftColor)),
                  const SizedBox(height: 16),
                  AppButton(
                    label: context.tr(L.scanQr),
                    icon: Icons.qr_code_scanner_rounded,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => context.push(Routes.careScan),
                  ),
                ]),
              ),
            ]),
          );
        },
      );
}
