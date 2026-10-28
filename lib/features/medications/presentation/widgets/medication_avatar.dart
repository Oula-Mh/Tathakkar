import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Medication photo (local file) or a pill icon fallback.
class MedicationAvatar extends StatelessWidget {
  const MedicationAvatar({super.key, this.imagePath, this.size = 48});
  final String? imagePath;
  final double size;

  @override
  Widget build(BuildContext context) {
    final file = imagePath == null ? null : File(imagePath!);
    final hasImage = file != null && file.existsSync();
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.iceBlue,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: hasImage
          ? Image.file(file, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _icon())
          : _icon(),
    );
  }

  Widget _icon() => Icon(Icons.medication_rounded, size: size * 0.55, color: AppColors.turquoise);
}
