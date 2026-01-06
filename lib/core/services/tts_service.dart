import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  late FlutterTts _flutterTts;
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  // Callbacks for UI updates
  Function(bool)? onSpeakingStateChanged;

  TtsService() {
    _flutterTts = FlutterTts();
    _initTts();
  }

  Future<void> _initTts() async {
    // Default language, can be dynamic later
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
      onSpeakingStateChanged?.call(true);
    });

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      onSpeakingStateChanged?.call(false);
    });

    _flutterTts.setErrorHandler((msg) {
      print('TTS Error: $msg');
      _isSpeaking = false;
      onSpeakingStateChanged?.call(false);
    });

    _flutterTts.setCancelHandler(() {
      _isSpeaking = false;
      onSpeakingStateChanged?.call(false);
    });
  }

  Future<void> setVoiceForAvatar(String avatarName) async {
    if (avatarName.toLowerCase() == 'karl') {
      if (Platform.isAndroid) {
        await _flutterTts
            .setVoice({"name": "en-us-x-tpd-local", "locale": "en-US"});
      } else if (Platform.isIOS) {
        await _flutterTts.setVoice(
            {"name": "com.apple.ttsbundle.Daniel-compact", "locale": "en-US"});
      }
    } else {
      // Default / Clara
      if (Platform.isAndroid) {
        await _flutterTts
            .setVoice({"name": "en-us-x-tpf-local", "locale": "en-US"});
      } else if (Platform.isIOS) {
        await _flutterTts.setVoice({
          "name": "com.apple.ttsbundle.Samantha-compact",
          "locale": "en-US"
        });
      }
    }
  }

  Future<int> speak(String text) async {
    return await _flutterTts.speak(text);
  }

  Future<int> stop() async {
    return await _flutterTts.stop();
  }
}
