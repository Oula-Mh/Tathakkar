import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/l10n_keys.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/bloc/session/session_bloc.dart';
import '../../../../core/router/routes.dart';
import '../bloc/care_link_bloc.dart';

class CareQrPage extends StatefulWidget {
  const CareQrPage({super.key});

  @override
  State<CareQrPage> createState() => _CareQrPageState();
}

class _CareQrPageState extends State<CareQrPage> {
  Timer? _ticker;
  Duration _left = Duration.zero;

  @override
  void initState() {
    super.initState();
    context.read<CareLinkBloc>().add(const CareTokenRequested());
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final t = context.read<CareLinkBloc>().state.token;
      if (t == null || !mounted) return;
      setState(() => _left = t.expiresAt.difference(DateTime.now()));
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _mmss(Duration d) {
    final s = d.isNegative ? 0 : d.inSeconds;
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select((SessionBloc b) {
      final s = b.state;
      return s is SessionAuthenticated ? s.user : null;
    });
    return BlocConsumer<CareLinkBloc, CareLinkState>(
      // The elder's app sees the link appear once the caregiver scans.
      listenWhen: (p, c) => p.caregiver == null && c.caregiver != null,
      listener: (context, s) => context.pushReplacement(Routes.careLinkedElder),
      builder: (context, s) {
        final t = s.token;
        final expired = t != null && (t.isExpired || _left.isNegative);
        return AppScaffold(
          showBack: true,
          title: context.tr(L.linkCaregiver),
          bottom: AppButton(
            label: context.tr(L.newQr),
            variant: AppButtonVariant.secondary,
            onPressed: () => context.read<CareLinkBloc>().add(const CareTokenRequested()),
          ),
          body: switch (s.tokenOp) {
            CareOp.failure => SizedBox(
                height: 400,
                child: ErrorView(
                  messageKey: s.failureKey ?? 'err_unknown',
                  onRetry: () => context.read<CareLinkBloc>().add(const CareTokenRequested()),
                )),
            _ when t == null => const SizedBox(height: 300, child: LoadingView()),
            _ => Column(children: [
                Text(context.tr(L.qrIntro),
                    textAlign: TextAlign.center,
                    style: TextStyle(height: 1.6, color: context.inkSoftColor)),
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(children: [
                    Text(user?.name ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Opacity(
                        opacity: expired ? 0.15 : 1,
                        child: QrImageView(data: t.qrData, size: 220),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      expired
                          ? context.tr(L.qrExpired)
                          : context.tr(L.qrExpiresIn, args: {'t': _mmss(_left == Duration.zero ? t.expiresAt.difference(DateTime.now()) : _left)}),
                      style: TextStyle(color: expired ? Colors.redAccent : context.inkSoftColor),
                    ),
                    const SizedBox(height: 8),
                    Text(context.tr(L.qrOnce),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.5, color: context.inkSoftColor)),
                  ]),
                ),
              ]),
          },
        );
      },
    );
  }
}
