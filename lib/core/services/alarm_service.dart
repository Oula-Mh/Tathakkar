import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../constants/app_constants.dart';
import '../utils/app_logger.dart';

/// Alarm tone (looping) + spoken medication name, played TOGETHER.
///
/// Why they used to cancel each other: the audio player asked for exclusive
/// audio focus, so the moment the voice started the tone was paused and never
/// resumed. Now the tone plays on the ALARM stream without taking focus, and
/// is only lowered (ducked) while the voice speaks. The voice repeats a few
/// times so an older person who didn't hear it the first time gets another go.
/// Nothing here ever throws: a missing file or TTS engine must not crash.
class AlarmService {
  AlarmService() : _player = AudioPlayer(), _tts = FlutterTts();
  final AudioPlayer _player;
  final FlutterTts _tts;

  static const _maxSpeeches = 6;
  static const _speechInterval = Duration(seconds: 14);
  static const _duckedVolume = 0.01;

  Timer? _voiceTimer;
  bool _active = false;
  bool _speaking = false;
  int _spoken = 0;

  Future<void> startSound() async {
    _active = true;
    try {
      await _player.setAudioContext(AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: true,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.alarm,
          audioFocus: AndroidAudioFocus.none, // never fight the voice for focus
        ),
        iOS: AudioContextIOS(category: AVAudioSessionCategory.playback),
      ));
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(1.0);
    } catch (e) {
      AppLogger.w('Alarm audio setup failed: $e');
    }
    // Try every supported extension: the user may have added .wav, .mp3 or .ogg.
    for (final path in Assets.alarmSounds) {
      try {
        await _player.play(AssetSource(path));
        return;
      } catch (_) {
        AppLogger.d('No alarm asset at $path');
      }
    }
    AppLogger.w('No alarm sound asset found (assets/sounds/alarm.wav|mp3|ogg)');
  }

  /// Speaks [text] now and again every 14 seconds (max 6 times).
  Future<void> startVoice(String text, String languageCode) async {
    _active = true;
    _voiceTimer?.cancel();
    _spoken = 0;
    try {
      await _tts.setLanguage(languageCode == 'ar' ? 'ar-SA' : 'en-US');
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
    } catch (e) {
      AppLogger.w('TTS setup failed: $e');
    }

    Future<void> once() async {
      if (!_active || _speaking || _spoken >= _maxSpeeches) return;
      _speaking = true;
      _spoken++;
      try {
        await _player.setVolume(_duckedVolume); // lower the tone, don't stop it
        await _tts.speak(text);
      } catch (e) {
        AppLogger.w('TTS failed: $e');
      } finally {
        _speaking = false;
        if (_active) {
          try {
            await _player.setVolume(1.0);
          } catch (_) {}
        }
      }
    }

    unawaited(once());
    _voiceTimer = Timer.periodic(_speechInterval, (_) => unawaited(once()));
  }

  Future<void> stop() async {
    _active = false;
    _voiceTimer?.cancel();
    try {
      await _player.stop();
      await _player.setVolume(1.0);
      await _tts.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await stop();
    await _player.dispose();
  }
}
