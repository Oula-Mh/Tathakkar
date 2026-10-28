part of 'medication_form_bloc.dart';

enum MedFormStatus { editing, saving, saved, failure }

class MedicationFormState extends Equatable {
  const MedicationFormState({
    required this.draft,
    this.step = 0,
    this.status = MedFormStatus.editing,
    this.nameError,
    this.endDateError,
    this.timesError,
    this.stockError,
    this.failureKey,
    this.saved,
  });

  static const stepCount = 5;

  final Medication draft;
  final int step;
  final MedFormStatus status;
  final String? nameError;
  final String? endDateError;
  final String? timesError;
  final String? stockError;
  final String? failureKey;
  final Medication? saved;

  bool get isSaving => status == MedFormStatus.saving;
  bool get isLastStep => step == stepCount - 1;

  MedicationFormState copyWith({
    Medication? draft,
    int? step,
    MedFormStatus? status,
    String? nameError,
    String? endDateError,
    String? timesError,
    String? stockError,
    String? failureKey,
    Medication? saved,
    bool clearErrors = false,
  }) =>
      MedicationFormState(
        draft: draft ?? this.draft,
        step: step ?? this.step,
        status: status ?? this.status,
        nameError: clearErrors ? null : (nameError ?? this.nameError),
        endDateError: clearErrors ? null : (endDateError ?? this.endDateError),
        timesError: clearErrors ? null : (timesError ?? this.timesError),
        stockError: clearErrors ? null : (stockError ?? this.stockError),
        failureKey: failureKey,
        saved: saved ?? this.saved,
      );

  @override
  List<Object?> get props =>
      [draft, step, status, nameError, endDateError, timesError, stockError, failureKey, saved];
}
