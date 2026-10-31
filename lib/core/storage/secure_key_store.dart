import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce/hive.dart';

import '../constants/app_constants.dart';

/// Keeps the AES key of the encrypted Hive box in the platform keystore
/// (Android Keystore / iOS Keychain), never next to the data.
class SecureKeyStore {
  SecureKeyStore()
    : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<HiveAesCipher> cipher() async {
    var encoded = await _storage.read(key: HiveKeys.secureKeyName);
    if (encoded == null) {
      encoded = base64UrlEncode(Hive.generateSecureKey());
      await _storage.write(key: HiveKeys.secureKeyName, value: encoded);
    }
    return HiveAesCipher(base64Url.decode(encoded));
  }

  Future<void> deleteKey() => _storage.delete(key: HiveKeys.secureKeyName);
}
