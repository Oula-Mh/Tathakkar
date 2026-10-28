import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/l10n_keys.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/state_views.dart';
import '../bloc/care_link_bloc.dart';

class CareScanPage extends StatefulWidget {
  const CareScanPage({super.key});

  @override
  State<CareScanPage> createState() => _CareScanPageState();
}

class _CareScanPageState extends State<CareScanPage> with WidgetsBindingObserver {
  final _controller = MobileScannerController(formats: const [BarcodeFormat.qrCode]);
  PermissionStatus? _permission;
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Returning from system settings: re-check the permission.
    if (state == AppLifecycleState.resumed) _checkPermission();
  }

  Future<void> _checkPermission() async {
    final s = await Permission.camera.status;
    if (mounted) setState(() => _permission = s);
  }

  Future<void> _request() async {
    final s = await Permission.camera.request();
    if (!mounted) return;
    setState(() => _permission = s);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final raw = capture.barcodes.map((b) => b.rawValue).whereType<String>().firstOrNull;
    if (raw == null) return;
    _handled = true; // one scan only; avoids double redeem
    _controller.stop();
    context.read<CareLinkBloc>().add(CareQrScanned(raw));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CareLinkBloc, CareLinkState>(
      listenWhen: (p, c) => p.redeemOp != c.redeemOp,
      listener: (context, s) {
        if (s.redeemOp == CareOp.success || s.redeemOp == CareOp.failure) {
          context.pushReplacement(Routes.careResult);
        }
      },
      child: AppScaffold(
        showBack: true,
        scrollable: false,
        title: context.tr(L.scanQrTitle),
        bottom: AppButton(
          label: context.tr(L.cancel),
          variant: AppButtonVariant.secondary,
          onPressed: () => context.pop(),
        ),
        body: _permission == null
            ? const LoadingView()
            : !_permission!.isGranted
                ? MessageView(
                    icon: Icons.photo_camera_outlined,
                    title: context.tr(L.cameraPermissionTitle),
                    message: context.tr(L.cameraPermissionSub),
                    actionLabel: _permission!.isPermanentlyDenied
                        ? context.tr(L.openSettings)
                        : context.tr(L.allow),
                    onAction: _permission!.isPermanentlyDenied ? openAppSettings : _request,
                    secondaryLabel: context.tr(L.notNow),
                    onSecondary: () => context.pop(),
                  )
                : BlocBuilder<CareLinkBloc, CareLinkState>(
                    buildWhen: (p, c) => p.redeemOp != c.redeemOp,
                    builder: (context, s) => s.redeemOp == CareOp.working
                        ? MessageView(
                            icon: Icons.more_horiz_rounded,
                            title: context.tr(L.linking),
                            message: context.tr(L.linkingSub))
                        : Column(children: [
                            Text(context.tr(L.scanQrHint),
                                textAlign: TextAlign.center,
                                style: TextStyle(color: context.inkSoftColor)),
                            const SizedBox(height: 16),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: Stack(fit: StackFit.expand, children: [
                                  MobileScanner(
                                    controller: _controller,
                                    onDetect: _onDetect,
                                    errorBuilder: (context, error) => MessageView(
                                      icon: Icons.error_outline_rounded,
                                      title: context.tr(L.cameraError),
                                    ),
                                  ),
                                  IgnorePointer(
                                    child: Center(
                                      child: Container(
                                        width: 230,
                                        height: 230,
                                        decoration: BoxDecoration(
                                          border: Border.all(color: AppColors.turquoise, width: 3),
                                          borderRadius: BorderRadius.circular(28),
                                        ),
                                      ),
                                    ),
                                  ),
                                ]),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ]),
                  ),
      ),
    );
  }
}
