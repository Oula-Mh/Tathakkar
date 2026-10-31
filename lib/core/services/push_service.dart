import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../constants/app_constants.dart';
import '../utils/app_logger.dart';
import 'notification_service.dart';

/// FCM: stores this device's token (so Cloud Functions can reach the caregiver),
/// shows pushes that arrive while the app is open, and reports taps.
class PushService {
  PushService(this._db, this._notifications);
  final FirebaseFirestore _db;
  final NotificationService _notifications;

  final _opens = StreamController<void>.broadcast();
  final _subs = <StreamSubscription<dynamic>>[];
  String? _token;

  /// Fires when the user taps a push (open the inbox).
  Stream<void> get opens => _opens.stream;

  Future<void> register(String uid, {required String languageCode}) async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      await messaging.setForegroundNotificationPresentationOptions(
          alert: true, badge: true, sound: true);

      Future<void> save(String? t) async {
        if (t == null) return;
        _token = t;
        await _db.collection(FirestorePaths.users).doc(uid).set({
          'fcmTokens': FieldValue.arrayUnion([t]),
        }, SetOptions(merge: true));
      }

      await save(await messaging.getToken());
      for (final s in _subs) {
        await s.cancel();
      }
      _subs
        ..clear()
        ..add(messaging.onTokenRefresh.listen(save))
        // Android shows pushes only when the app is closed/background: show it ourselves when open.
        ..add(FirebaseMessaging.onMessage.listen((m) => _showForeground(m, languageCode)))
        ..add(FirebaseMessaging.onMessageOpenedApp.listen((_) => _opens.add(null)));

      final initial = await messaging.getInitialMessage();
      if (initial != null) _opens.add(null);
    } catch (e) {
      AppLogger.w('Push registration skipped: $e'); // never blocks the app
    }
  }

  Future<void> _showForeground(RemoteMessage m, String languageCode) async {
    final n = m.notification;
    if (n == null) return;
    try {
      await _notifications.showSimple(
        id: m.messageId.hashCode & 0x7FFFFFFF,
        title: n.title ?? '',
        body: n.body ?? '',
        channelId: NotificationIds.caregiverChannel,
        channelName: languageCode == 'ar' ? 'إشعارات مقدّم الرعاية' : 'Caregiver alerts',
        payload: 'i', // inbox
      );
    } catch (e) {
      AppLogger.w('foreground push failed: $e');
    }
  }

  /// Sign-out: this phone must stop receiving the previous account's pushes.
  Future<void> unregister(String uid) async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    final messaging = FirebaseMessaging.instance;
    final token = _token ?? await messaging.getToken();
    if (token != null) {
      await _db.collection(FirestorePaths.users).doc(uid).set({
        'fcmTokens': FieldValue.arrayRemove([token]),
      }, SetOptions(merge: true));
    }
    await messaging.deleteToken();
    _token = null;
  }
}
