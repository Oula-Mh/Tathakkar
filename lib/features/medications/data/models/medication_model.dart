import '../../domain/entities/medication.dart';

/// Serialization lives here so the entity stays pure Dart.
/// The same map format is used for Firestore and the Hive cache.
class MedicationModel extends Medication {
  const MedicationModel({
    super.id,
    required super.name,
    super.imagePath,
    super.type,
    required super.startDate,
    super.endDate,
    super.dosePerTake,
    super.times,
    super.meal,
    super.notes,
    super.packSize,
    super.remaining,
    super.alertThreshold,
    super.unit,
    super.remindersEnabled,
    super.soundEnabled,
    super.speakEnabled,
    super.showImage,
    super.fullScreen,
    super.snoozeMinutes,
  });

  factory MedicationModel.fromEntity(Medication m) => MedicationModel(
        id: m.id,
        name: m.name,
        imagePath: m.imagePath,
        type: m.type,
        startDate: m.startDate,
        endDate: m.endDate,
        dosePerTake: m.dosePerTake,
        times: m.times,
        meal: m.meal,
        notes: m.notes,
        packSize: m.packSize,
        remaining: m.remaining,
        alertThreshold: m.alertThreshold,
        unit: m.unit,
        remindersEnabled: m.remindersEnabled,
        soundEnabled: m.soundEnabled,
        speakEnabled: m.speakEnabled,
        showImage: m.showImage,
        fullScreen: m.fullScreen,
        snoozeMinutes: m.snoozeMinutes,
      );

  factory MedicationModel.fromMap(String id, Map<String, dynamic> m) {
    T pick<T>(String k, T fallback) => m[k] is T ? m[k] as T : fallback;
    final times = (m['times'] as List?)?.map((e) => (e as num).toInt()).toList() ?? [480];
    times.sort();
    return MedicationModel(
      id: id,
      name: pick('name', ''),
      imagePath: m['imagePath'] as String?,
      type: pick('type', 'permanent') == 'temporary'
          ? TreatmentType.temporary
          : TreatmentType.permanent,
      startDate: DateTime.fromMillisecondsSinceEpoch(pick<int>('startDate', 0)),
      endDate: m['endDate'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch((m['endDate'] as num).toInt()),
      dosePerTake: (m['dosePerTake'] as num?)?.toInt() ?? 1,
      times: times,
      meal: MealRelation.values.firstWhere(
        (e) => e.name == m['meal'],
        orElse: () => MealRelation.anytime,
      ),
      notes: (m['notes'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      packSize: (m['packSize'] as num?)?.toInt() ?? 0,
      remaining: (m['remaining'] as num?)?.toInt() ?? 0,
      alertThreshold: (m['alertThreshold'] as num?)?.toInt() ?? 5,
      unit: pick('unit', 'pill'),
      remindersEnabled: pick('remindersEnabled', true),
      soundEnabled: pick('soundEnabled', true),
      speakEnabled: pick('speakEnabled', true),
      showImage: pick('showImage', true),
      fullScreen: pick('fullScreen', true),
      snoozeMinutes: (m['snoozeMinutes'] as num?)?.toInt() ?? 10,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'imagePath': imagePath,
        'type': type.name,
        'startDate': startDate.millisecondsSinceEpoch,
        'endDate': endDate?.millisecondsSinceEpoch,
        'dosePerTake': dosePerTake,
        'times': times,
        'meal': meal.name,
        'notes': notes,
        'packSize': packSize,
        'remaining': remaining,
        'alertThreshold': alertThreshold,
        'unit': unit,
        'remindersEnabled': remindersEnabled,
        'soundEnabled': soundEnabled,
        'speakEnabled': speakEnabled,
        'showImage': showImage,
        'fullScreen': fullScreen,
        'snoozeMinutes': snoozeMinutes,
      };

  /// Cache format also stores the id.
  Map<String, dynamic> toCacheMap() => {...toMap(), 'id': id};
}
