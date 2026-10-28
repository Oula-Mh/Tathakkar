part of 'medication_form_bloc.dart';

sealed class MedicationFormEvent extends Equatable {
  const MedicationFormEvent();
  @override
  List<Object?> get props => [];
}

class MedNameChanged extends MedicationFormEvent {
  const MedNameChanged(this.value);
  final String value;
  @override
  List<Object?> get props => [value];
}

class MedImageChanged extends MedicationFormEvent {
  const MedImageChanged(this.path);
  final String? path;
  @override
  List<Object?> get props => [path];
}

class MedTypeChanged extends MedicationFormEvent {
  const MedTypeChanged(this.type);
  final TreatmentType type;
  @override
  List<Object?> get props => [type];
}

class MedStartDateChanged extends MedicationFormEvent {
  const MedStartDateChanged(this.date);
  final DateTime date;
  @override
  List<Object?> get props => [date];
}

class MedEndDateChanged extends MedicationFormEvent {
  const MedEndDateChanged(this.date);
  final DateTime date;
  @override
  List<Object?> get props => [date];
}

class MedDoseAmountChanged extends MedicationFormEvent {
  const MedDoseAmountChanged(this.value);
  final int value;
  @override
  List<Object?> get props => [value];
}

class MedTimesCountChanged extends MedicationFormEvent {
  const MedTimesCountChanged(this.count);
  final int count;
  @override
  List<Object?> get props => [count];
}

class MedTimeChanged extends MedicationFormEvent {
  const MedTimeChanged(this.index, this.minutes);
  final int index;
  final int minutes;
  @override
  List<Object?> get props => [index, minutes];
}

class MedMealChanged extends MedicationFormEvent {
  const MedMealChanged(this.meal);
  final MealRelation meal;
  @override
  List<Object?> get props => [meal];
}

class MedNoteAdded extends MedicationFormEvent {
  const MedNoteAdded(this.note);
  final String note;
  @override
  List<Object?> get props => [note];
}

class MedNoteRemoved extends MedicationFormEvent {
  const MedNoteRemoved(this.note);
  final String note;
  @override
  List<Object?> get props => [note];
}

class MedStockChanged extends MedicationFormEvent {
  const MedStockChanged({this.packSize, this.remaining, this.threshold, this.unit});
  final int? packSize;
  final int? remaining;
  final int? threshold;
  final String? unit;
  @override
  List<Object?> get props => [packSize, remaining, threshold, unit];
}

class MedReminderPrefsChanged extends MedicationFormEvent {
  const MedReminderPrefsChanged({
    this.remindersEnabled,
    this.soundEnabled,
    this.speakEnabled,
    this.showImage,
    this.fullScreen,
    this.snoozeMinutes,
  });
  final bool? remindersEnabled;
  final bool? soundEnabled;
  final bool? speakEnabled;
  final bool? showImage;
  final bool? fullScreen;
  final int? snoozeMinutes;
  @override
  List<Object?> get props =>
      [remindersEnabled, soundEnabled, speakEnabled, showImage, fullScreen, snoozeMinutes];
}

class MedNextStep extends MedicationFormEvent {
  const MedNextStep();
}

class MedPreviousStep extends MedicationFormEvent {
  const MedPreviousStep();
}

class MedGoToStep extends MedicationFormEvent {
  const MedGoToStep(this.step);
  final int step;
  @override
  List<Object?> get props => [step];
}

class MedSubmitted extends MedicationFormEvent {
  const MedSubmitted();
}
