import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/localization/l10n_keys.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../../../core/widgets/glass_card.dart';
import '../../../domain/entities/medication.dart';
import '../../bloc/form/medication_form_bloc.dart';

class StepInfo extends StatelessWidget {
  const StepInfo({super.key, required this.state});
  final MedicationFormState state;

  Future<void> _pickImage(BuildContext context) async {
    final bloc = context.read<MedicationFormBloc>();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(ctx.tr(L.camera)),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(ctx.tr(L.gallery)),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          if (state.draft.imagePath != null)
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(ctx.tr(L.removePhoto)),
              onTap: () {
                Navigator.pop(ctx);
                bloc.add(const MedImageChanged(null));
              },
            ),
        ]),
      ),
    );
    if (source == null) return;
    try {
      final file = await ImagePicker().pickImage(source: source, maxWidth: 1024, imageQuality: 80);
      if (file != null) bloc.add(MedImageChanged(file.path));
    } catch (_) {
      if (context.mounted) AppSnackbar.show(context, context.tr(L.errPickImage), error: true);
    }
  }

  Future<DateTime?> _pickDate(BuildContext context, DateTime initial, DateTime first) =>
      showDatePicker(
        context: context,
        initialDate: initial.isBefore(first) ? first : initial,
        firstDate: first,
        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      );

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<MedicationFormBloc>();
    final d = state.draft;
    final img = d.imagePath != null && File(d.imagePath!).existsSync() ? File(d.imagePath!) : null;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GlassCard(
        blur: 0,
        onTap: () => _pickImage(context),
        child: Row(children: [
          Container(
            width: 56,
            height: 56,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
                color: Colors.white70, borderRadius: BorderRadius.circular(16)),
            child: img != null
                ? Image.file(img, fit: BoxFit.cover)
                : Icon(Icons.photo_camera_outlined, color: context.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(context.tr(L.boxPhoto), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              Text(context.tr(L.optional), style: TextStyle(color: context.inkSoftColor, fontSize: 13)),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 14),
      GlassCard(
        blur: 0,
        child: AppTextField(
          label: context.tr(L.medicationName),
          hint: context.tr(L.medicationNameHint),
          initialValue: d.name,
          textInputAction: TextInputAction.done,
          errorText: state.nameError == null ? null : context.tr(state.nameError!),
          onChanged: (v) => bloc.add(MedNameChanged(v)),
        ),
      ),
      const SizedBox(height: 14),
      GlassCard(
        blur: 0,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(context.tr(L.treatmentType),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.inkSoftColor)),
          const SizedBox(height: 10),
          SegmentedButton<TreatmentType>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: TreatmentType.permanent, label: Text(context.tr(L.typePermanent))),
              ButtonSegment(value: TreatmentType.temporary, label: Text(context.tr(L.typeTemporary))),
            ],
            selected: {d.type},
            onSelectionChanged: (s) => bloc.add(MedTypeChanged(s.first)),
          ),
          const SizedBox(height: 14),
          _DateTile(
            label: context.tr(L.startDate),
            value: Fmt.date(context, d.startDate),
            onTap: () async {
              final p = await _pickDate(context, d.startDate, DateTime.now().subtract(const Duration(days: 365)));
              if (p != null) bloc.add(MedStartDateChanged(p));
            },
          ),
          if (d.type == TreatmentType.temporary) ...[
            const SizedBox(height: 10),
            _DateTile(
              label: context.tr(L.endDate),
              value: d.endDate == null ? context.tr(L.chooseDate) : Fmt.date(context, d.endDate!),
              error: state.endDateError == null ? null : context.tr(state.endDateError!),
              onTap: () async {
                final p = await _pickDate(context, d.endDate ?? d.startDate, d.startDate);
                if (p != null) bloc.add(MedEndDateChanged(p));
              },
            ),
          ],
        ]),
      ),
    ]);
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({required this.label, required this.value, required this.onTap, this.error});
  final String label;
  final String value;
  final String? error;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 13, color: context.inkSoftColor)),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: context.isDark ? 0.08 : 0.9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: error == null ? Colors.transparent : Colors.redAccent),
            ),
            child: Row(children: [
              Expanded(child: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
              Icon(Icons.calendar_today_outlined, size: 18, color: context.inkSoftColor),
            ]),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
          ),
      ]);
}
