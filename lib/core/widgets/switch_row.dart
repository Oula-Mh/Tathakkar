import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SwitchRow extends StatelessWidget {
  const SwitchRow({super.key, required this.label, required this.value, required this.onChanged, this.subtitle});
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  if (subtitle != null)
                    Text(subtitle!, style: TextStyle(fontSize: 13, color: context.inkSoftColor)),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      );
}
