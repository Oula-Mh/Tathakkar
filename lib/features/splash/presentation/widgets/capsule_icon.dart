import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Two-tone capsule mark used by the splash logo and onboarding illustration.
class CapsuleIcon extends StatelessWidget {
  const CapsuleIcon({
    super.key,
    this.width = 64,
    this.height = 28,
    this.angle = -0.55,
    this.leftColor = AppColors.iceBlue,
    this.rightColor = AppColors.slateBlue,
  });

  final double width;
  final double height;
  final double angle;
  final Color leftColor;
  final Color rightColor;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(
            color: AppColors.ink.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: Row(
            children: <Widget>[
              Expanded(child: ColoredBox(color: leftColor)),
              Expanded(child: ColoredBox(color: rightColor)),
            ],
          ),
        ),
      ),
    );
  }
}