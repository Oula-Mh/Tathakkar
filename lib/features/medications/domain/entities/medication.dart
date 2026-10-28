import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';

enum TreatmentType { permanent, temporary }

enum MealRelation { before, after, withMeal, anytime }

class Medication extends Equatable {
  const Medication({
    this.id = '',
    required this.name,
    this.imagePath,
    this.type = TreatmentType.permanent,
    required this.startDate,
    this.endDate,
    this.dosePerTake = 1,
    this.times = const [8 * 60],
    this.meal = MealRelation.anytime,
    this.notes = const [],
    this.packSize = 0,
    this.remaining = 0,
    this.alertThreshold = BusinessRules.defaultAlertThreshold,
    this.unit = 'pill',
    this.remindersEnabled = true,
    this.soundEnabled = true,
    this.speakEnabled = true,
    this.showImage = true,
    this.fullScreen = true,
    this.snoozeMinutes = BusinessRules.defaultSnoozeMinutes,
  });

  final String id;
  final String name;

  /// Local file path on this device (images are not synced between phones).
  final String? imagePath;
  final TreatmentType type;
  final DateTime startDate;
  final DateTime? endDate;

  /// Units taken per dose; this is what is deducted from stock on confirm.
  final int dosePerTake;

  /// Dose times as minutes since midnight, sorted ascending.
  final List<int> times;
  final MealRelation meal;
  final List<String> notes;

  final int packSize;
  final int remaining;
  final int alertThreshold;
  final String unit;

  final bool remindersEnabled;
  final bool soundEnabled;
  final bool speakEnabled;
  final bool showImage;
  final bool fullScreen;
  final int snoozeMinutes;

  bool get isNew => id.isEmpty;

  // Stock and treatment course are tracked independently.
  bool get isOutOfStock => remaining <= 0;
  bool get isLowStock => remaining > 0 && remaining <= alertThreshold;

  bool isCourseEnded(DateTime now) =>
      type == TreatmentType.temporary &&
      endDate != null &&
      now.dateOnly.isAfter(endDate!.dateOnly);

  bool isActiveOn(DateTime day) {
    final d = day.dateOnly;
    if (d.isBefore(startDate.dateOnly)) return false;
    if (type == TreatmentType.temporary && endDate != null && d.isAfter(endDate!.dateOnly)) {
      return false;
    }
    return true;
  }

  /// How many days of treatment the remaining stock covers.
  int get daysOfStockLeft =>
      times.isEmpty || dosePerTake <= 0 ? 0 : remaining ~/ (dosePerTake * times.length);

  Medication copyWith({
    String? id,
    String? name,
    String? imagePath,
    bool clearImage = false,
    TreatmentType? type,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
    int? dosePerTake,
    List<int>? times,
    MealRelation? meal,
    List<String>? notes,
    int? packSize,
    int? remaining,
    int? alertThreshold,
    String? unit,
    bool? remindersEnabled,
    bool? soundEnabled,
    bool? speakEnabled,
    bool? showImage,
    bool? fullScreen,
    int? snoozeMinutes,
  }) =>
      Medication(
        id: id ?? this.id,
        name: name ?? this.name,
        imagePath: clearImage ? null : (imagePath ?? this.imagePath),
        type: type ?? this.type,
        startDate: startDate ?? this.startDate,
        endDate: clearEndDate ? null : (endDate ?? this.endDate),
        dosePerTake: dosePerTake ?? this.dosePerTake,
        times: times ?? this.times,
        meal: meal ?? this.meal,
        notes: notes ?? this.notes,
        packSize: packSize ?? this.packSize,
        remaining: remaining ?? this.remaining,
        alertThreshold: alertThreshold ?? this.alertThreshold,
        unit: unit ?? this.unit,
        remindersEnabled: remindersEnabled ?? this.remindersEnabled,
        soundEnabled: soundEnabled ?? this.soundEnabled,
        speakEnabled: speakEnabled ?? this.speakEnabled,
        showImage: showImage ?? this.showImage,
        fullScreen: fullScreen ?? this.fullScreen,
        snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      );

  @override
  List<Object?> get props => [
        id, name, imagePath, type, startDate, endDate, dosePerTake, times, meal, notes,
        packSize, remaining, alertThreshold, unit, remindersEnabled, soundEnabled,
        speakEnabled, showImage, fullScreen, snoozeMinutes,
      ];
}
