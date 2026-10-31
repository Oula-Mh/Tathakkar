import 'package:hive_ce/hive.dart';

/// Thin wrapper around a Hive box. Data sources depend on this, not on Hive.
class LocalStorage {
  LocalStorage(this._box);
  final Box<dynamic> _box;

  T? read<T>(String key) {
    final v = _box.get(key);
    return v is T ? v : null;
  }

  Iterable<String> get keys => _box.keys.whereType<String>();

  Future<void> write(String key, dynamic value) => _box.put(key, value);
  Future<void> remove(String key) => _box.delete(key);

  /// Wipes the whole box (used on sign-out so health data never outlives the session).
  Future<void> clear() async {
    await _box.clear();
  }
}
