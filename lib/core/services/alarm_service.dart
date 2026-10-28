import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../constants/app_constants.dart';
import '../utils/app_logger.dart';

/// Plays the alarm sound and speaks the medication name. Never throws.
class AlarmService {
  AlarmService() : _player = AudioPlayer(), _tts = FlutterTts();
  final AudioPlayer _player;
  final FlutterTts _tts;

  Future<void> startSound() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource(Assets.alarmSound));
    } catch (e) {
      AppLogger.w('Alarm sound unavailable: $e'); // missing asset must not crash
    }
  }

  Future<void> speak(String text, String languageCode) async {
    try {
      await _tts.setLanguage(languageCode == 'ar' ? 'ar-SA' : 'en-US');
      await _tts.setSpeechRate(0.45);
      await _tts.speak(text);
    } catch (e) {
      AppLogger.w('TTS unavailable: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
      await _tts.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await stop();
    await _player.dispose();
  }
}
