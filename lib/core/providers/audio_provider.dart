import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Centralized audio and TTS management provider
/// Manages a single FlutterTts instance, voice selection, and audio state
class AudioProvider extends ChangeNotifier {
  late FlutterTts _flutterTts;
  bool _isSpeaking = false;
  bool _isMuted = false;
  String _currentAvatarName = "Clara";

  bool get isSpeaking => _isSpeaking;
  bool get isMuted => _isMuted;
  String get currentAvatarName => _currentAvatarName;

  AudioProvider() {
    _flutterTts = FlutterTts();
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    if (Platform.isIOS) {
      await _flutterTts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.ambient,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
        ],
        IosTextToSpeechAudioMode.voicePrompt,
      );
      await _flutterTts.setSharedInstance(true);
    }

    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
      notifyListeners();
    });

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      notifyListeners();
    });

    _flutterTts.setErrorHandler((msg) {
      debugPrint('TTS Error: $msg');
      _isSpeaking = false;
      notifyListeners();
    });

    _flutterTts.setCancelHandler(() {
      _isSpeaking = false;
      notifyListeners();
    });
  }

  /// Set voice based on avatar name
  Future<void> setVoiceForAvatar(String avatarName) async {
    _currentAvatarName = avatarName;

    if (avatarName.toLowerCase() == 'karl') {
      if (Platform.isAndroid) {
        await _flutterTts.setVoice({
          "name": "en-us-x-tpd-local",
          "locale": "en-US",
        });
      } else if (Platform.isIOS) {
        await _flutterTts.setVoice({
          "name": "com.apple.ttsbundle.Daniel-compact",
          "locale": "en-US",
        });
      }
    } else {
      // Default / Clara
      if (Platform.isAndroid) {
        await _flutterTts.setVoice({
          "name": "en-us-x-tpf-local",
          "locale": "en-US",
        });
      } else if (Platform.isIOS) {
        await _flutterTts.setVoice({
          "name": "com.apple.ttsbundle.Samantha-compact",
          "locale": "en-US",
        });
      }
    }
    notifyListeners();
  }

  /// Speak text with TTS
  Future<void> speak(String text) async {
    if (!_isMuted && text.isNotEmpty) {
      await _flutterTts.stop();
      await Future.delayed(const Duration(milliseconds: 100));
      await _flutterTts.speak(text);
    }
  }

  /// Stop current speech
  Future<void> stop() async {
    await _flutterTts.stop();
    _isSpeaking = false;
    notifyListeners();
  }

  /// Toggle mute state
  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      stop();
    }
    notifyListeners();
  }

  /// Set mute state explicitly
  void setMuted(bool muted) {
    _isMuted = muted;
    if (_isMuted) {
      stop();
    }
    notifyListeners();
  }

  /// Set speech rate (0.0 to 1.0)
  Future<void> setSpeechRate(double rate) async {
    await _flutterTts.setSpeechRate(rate);
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    await _flutterTts.setVolume(volume);
  }

  /// Set pitch (0.5 to 2.0)
  Future<void> setPitch(double pitch) async {
    await _flutterTts.setPitch(pitch);
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
}
