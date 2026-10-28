import '../../../../core/storage/local_storage.dart';
import '../models/medication_model.dart';

/// Hive cache so the list shows instantly and works without internet.
class MedicationsLocalDataSource {
  const MedicationsLocalDataSource(this._storage);
  final LocalStorage _storage;

  List<MedicationModel>? read(String profileKey) {
    try {
      final raw = _storage.read<List>(profileKey);
      if (raw == null) return null;
      return raw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .map((m) => MedicationModel.fromMap(m['id'] as String? ?? '', m))
          .toList();
    } catch (_) {
      return null; // corrupted cache is ignored, remote will refill it
    }
  }

  Future<void> write(String profileKey, List<MedicationModel> list) =>
      _storage.write(profileKey, list.map((m) => m.toCacheMap()).toList());
}
