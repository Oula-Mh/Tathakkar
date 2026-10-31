import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Labelled input with inline error. Fully controlled by the BLoC state:
/// pass [errorText] (already localized) when the field is invalid.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.controller,
    this.keyboardType,
    this.textInputAction,
    this.obscure = false,
    this.prefixIcon,
    this.forceLtr = false,
    this.enabled = true,
    this.maxLines = 1,
    this.inputFormatters,
    this.autofillHints,
    this.initialValue,
  });

  final String label;
  final String? hint;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscure;
  final IconData? prefixIcon;
  final bool forceLtr;
  final bool enabled;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final String? initialValue;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    final dark = context.isDark;
    final radius = BorderRadius.circular(16);
    OutlineInputBorder border(Color c, [double w = 1.2]) =>
        OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: c, width: w));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.inkSoftColor,
            ),
          ),
        ),
        TextFormField(
          controller: widget.controller,
          initialValue: widget.controller == null ? widget.initialValue : null,
          enabled: widget.enabled,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          obscureText: _hidden,
          maxLines: widget.obscure ? 1 : widget.maxLines,
          inputFormatters: widget.inputFormatters,
          autofillHints: widget.autofillHints,
          textDirection: widget.forceLtr ? TextDirection.ltr : null,
          style: TextStyle(fontSize: 16.5, color: context.inkColor),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(color: context.inkSoftColor.withValues(alpha: 0.6)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: dark ? 0.08 : 0.9),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            prefixIcon: widget.prefixIcon == null
                ? null
                : Icon(widget.prefixIcon, color: context.inkSoftColor),
            suffixIcon: widget.obscure
                ? IconButton(
                    icon: Icon(
                      _hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: context.inkSoftColor,
                    ),
                    onPressed: () => setState(() => _hidden = !_hidden),
                  )
                : null,
            enabledBorder: border(hasError ? AppColors.danger : Colors.white.withValues(alpha: 0.9)),
            disabledBorder: border(AppColors.platinum),
            focusedBorder: border(hasError ? AppColors.danger : context.primaryColor, 1.8),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          child: hasError
              ? Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 16, color: AppColors.danger),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.errorText!,
                          style: const TextStyle(fontSize: 13, color: AppColors.danger),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
