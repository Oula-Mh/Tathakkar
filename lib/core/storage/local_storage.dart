import 'package:hive_ce/hive.dart';

/// Thin wrapper around a Hive box. Data sources depend on this, not on Hive.
class LocalStorage {
  LocalStorage(this._box);
  final Box<dynamic> _box;

  T? read<T>(String key) {
    final v = _box.get(key);
    return v is T ? v : null;
  }

  Future<void> write(String key, dynamic value) => _box.put(key, value);
  Future<void> remove(String key) => _box.delete(key);
}
