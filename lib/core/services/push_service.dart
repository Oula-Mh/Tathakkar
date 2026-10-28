import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../constants/app_constants.dart';
import '../utils/app_logger.dart';

/// Saves this device's FCM token so Cloud Functions can notify the caregiver.
class PushService {
  PushService(this._db);
  final FirebaseFirestore _db;

  Future<void> register(String uid) async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      Future<void> save(String? t) async {
        if (t == null) return;
        await _db.collection(FirestorePaths.users).doc(uid).set({
          'fcmTokens': FieldValue.arrayUnion([t]),
        }, SetOptions(merge: true));
      }

      await save(await messaging.getToken());
      messaging.onTokenRefresh.listen(save);
    } catch (e) {
      AppLogger.w('Push registration skipped: $e'); // never blocks the app
    }
  }
}
