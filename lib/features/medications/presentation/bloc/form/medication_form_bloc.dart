import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/localization/l10n_keys.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../profiles/domain/entities/person_profile.dart';
import '../../../domain/entities/medication.dart';
import '../../../domain/usecases/medications_usecases.dart';

part 'medication_form_event.dart';
part 'medication_form_state.dart';

/// 5-step add/edit wizard: info -> dose -> stock -> reminders -> review.
class MedicationFormBloc extends Bloc<MedicationFormEvent, MedicationFormState> {
  MedicationFormBloc({
    required SaveMedication saveMedication,
    required this.profile,
    required Medication initial,
  })  : _save = saveMedication,
        super(MedicationFormState(draft: initial)) {
    on<MedNameChanged>((e, emit) => _edit(emit, state.draft.copyWith(name: e.value)));
    on<MedImageChanged>((e, emit) => _edit(
        emit, e.path == null ? state.draft.copyWith(clearImage: true) : state.draft.copyWith(imagePath: e.path)));
    on<MedTypeChanged>((e, emit) => _edit(
          emit,
          e.type == TreatmentType.permanent
              ? state.draft.copyWith(type: e.type, clearEndDate: true)
              : state.draft.copyWith(type: e.type),
        ));
    on<MedStartDateChanged>((e, emit) => _edit(emit, state.draft.copyWith(startDate: e.date)));
    on<MedEndDateChanged>((e, emit) => _edit(emit, state.draft.copyWith(endDate: e.date)));
    on<MedDoseAmountChanged>(
        (e, emit) => _edit(emit, state.draft.copyWith(dosePerTake: e.value.clamp(1, 99))));
    on<MedTimesCountChanged>(_onTimesCount);
    on<MedTimeChanged>(_onTimeChanged);
    on<MedMealChanged>((e, emit) => _edit(emit, state.draft.copyWith(meal: e.meal)));
    on<MedNoteAdded>((e, emit) {
      final n = e.note.trim();
      if (n.isEmpty || state.draft.notes.contains(n)) return;
      _edit(emit, state.draft.copyWith(notes: [...state.draft.notes, n]));
    });
    on<MedNoteRemoved>((e, emit) => _edit(
        emit, state.draft.copyWith(notes: state.draft.notes.where((n) => n != e.note).toList())));
    on<MedStockChanged>((e, emit) => _edit(
          emit,
          state.draft.copyWith(
            packSize: e.packSize,
            remaining: e.remaining,
            alertThreshold: e.threshold,
            unit: e.unit,
          ),
        ));
    on<MedReminderPrefsChanged>((e, emit) => _edit(
          emit,
          state.draft.copyWith(
            remindersEnabled: e.remindersEnabled,
            soundEnabled: e.soundEnabled,
            speakEnabled: e.speakEnabled,
            showImage: e.showImage,
            fullScreen: e.fullScreen,
            snoozeMinutes: e.snoozeMinutes,
          ),
        ));
    on<MedNextStep>(_onNext);
    on<MedPreviousStep>((e, emit) {
      if (state.step > 0) emit(state.copyWith(step: state.step - 1, clearErrors: true));
    });
    on<MedGoToStep>((e, emit) => emit(state.copyWith(step: e.step.clamp(0, 4), clearErrors: true)));
    on<MedSubmitted>(_onSubmit);
  }

  final PersonProfile profile;
  final SaveMedication _save;

  void _edit(Emitter<MedicationFormState> emit, Medication draft) =>
      emit(state.copyWith(draft: draft, clearErrors: true));

  void _onTimesCount(MedTimesCountChanged e, Emitter<MedicationFormState> emit) {
    final count = e.count.clamp(1, 8);
    final times = [...state.draft.times];
    while (times.length < count) {
      // New slot: 4 hours after the last one (wraps within the day).
      times.add(((times.isEmpty ? 8 * 60 : times.last) + 240) % (24 * 60));
    }
    while (times.length > count) {
      times.removeLast();
    }
    _edit(emit, state.draft.copyWith(times: times));
  }

  void _onTimeChanged(MedTimeChanged e, Emitter<MedicationFormState> emit) {
    final times = [...state.draft.times];
    if (e.index < 0 || e.index >= times.length) return;
    times[e.index] = e.minutes;
    _edit(emit, state.draft.copyWith(times: times));
  }

  /// Returns the first invalid step (or null) for the whole draft.
  MedicationFormState _validate(int step) {
    final d = state.draft;
    switch (step) {
      case 0:
        String? name;
        String? end;
        if (d.name.trim().isEmpty) name = L.errMedNameRequired;
        if (d.type == TreatmentType.temporary) {
          if (d.endDate == null) {
            end = L.errEndDateRequired;
          } else if (d.endDate!.dateOnly.isBefore(d.startDate.dateOnly)) {
            end = L.errEndBeforeStart;
          }
        }
        return state.copyWith(nameError: name, endDateError: end);
      case 1:
        final unique = d.times.toSet().length == d.times.length;
        return state.copyWith(timesError: unique ? null : L.errDuplicateTimes);
      case 2:
        return state.copyWith(
            stockError: (d.remaining < 0 || d.packSize < 0 || d.alertThreshold < 0)
                ? L.errInvalidStock
                : null);
      default:
        return state;
    }
  }

  bool _hasError(MedicationFormState s) =>
      s.nameError != null || s.endDateError != null || s.timesError != null || s.stockError != null;

  void _onNext(MedNextStep e, Emitter<MedicationFormState> emit) {
    final checked = _validate(state.step);
    if (_hasError(checked)) {
      emit(checked);
      return;
    }
    if (state.step < MedicationFormState.stepCount - 1) {
      emit(state.copyWith(step: state.step + 1, clearErrors: true));
    }
  }

  Future<void> _onSubmit(MedSubmitted e, Emitter<MedicationFormState> emit) async {
    if (state.isSaving) return;
    // Re-check every step so a skipped/edited step can't save bad data.
    for (final s in [0, 1, 2]) {
      final checked = _validate(s);
      if (_hasError(checked)) {
        emit(checked.copyWith(step: s));
        return;
      }
    }
    emit(state.copyWith(status: MedFormStatus.saving, clearErrors: true));
    final times = [...state.draft.times]..sort();
    final draft = state.draft.copyWith(name: state.draft.name.trim(), times: times);
    final r = await _save(SaveMedicationParams(profile, draft));
    emit(r.fold(
      (f) => state.copyWith(status: MedFormStatus.failure, failureKey: f.messageKey),
      (m) => state.copyWith(status: MedFormStatus.saved, saved: m),
    ));
  }
}
