import 'package:language_app/core/utils/file_helper.dart';
import 'package:language_app/core/utils/viseme_helper.dart';
import 'package:language_app/app/constants/app_constants.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:language_app/core/services/tts_service.dart';

class VisemeData {
  final String name;
  final double startTime;
  final double endTime;

  VisemeData(this.name, this.startTime, this.endTime);
}

class AvatarController {
  MethodChannel? _channel;
  WebViewController? _webViewController;
  final FileHelper _fileHelper;
  final VisemeHelper _visemeHelper;

  // Viseme Data
  final Map<String, List<VisemeData>> _visemeMap = {};
  bool _visemesLoaded = false;

  // Helper Service
  TtsService? _ttsService;

  // Avatar tracking
  String? _currentAvatarName;

  AvatarController({FileHelper? fileHelper, VisemeHelper? visemeHelper})
    : _fileHelper = fileHelper ?? FileHelper(),
      _visemeHelper = visemeHelper ?? VisemeHelper();

  // ✅ Set current avatar name
  void setAvatarName(String avatarName) {
    _currentAvatarName = avatarName;
  }

  // ✅ Get animation path for current avatar
  String _getAnimationPath() {
    if (_currentAvatarName?.toLowerCase() == 'clara') {
      return AppConstants.claraAnimationPath;
    }
    return AppConstants.karlAnimationPath;
  }

  // ✅ Attach Native Channel (iOS)
  void attach(int viewId) {
    _channel = MethodChannel('AvatarView/$viewId');
  }

  // ✅ Attach Web Controller (Android)
  void attachWeb(WebViewController controller) {
    _webViewController = controller;
  }

  bool get isAttached => _channel != null || _webViewController != null;

  Future<void> disposeView() async {
    try {
      await _channel?.invokeMethod('dispose');
    } catch (_) {}
    _channel = null;
    _webViewController = null;
    _currentAvatarName = null;
  }

  Future<void> playAudioViseme(
    String audioPath,
    List<Map<String, dynamic>> visemeEvents,
  ) async {
    final resolvedPath = await _fileHelper.ensureFileOnDisk(audioPath);

    if (_channel != null) {
      // iOS Implementation
      await _channel?.invokeMethod('playAudioViseme', {
        'audioPath': resolvedPath,
        'visemes': visemeEvents,
      });
    } else if (_webViewController != null) {
      // Android Implementation
      final visemesJson = jsonEncode(visemeEvents);
      _webViewController?.runJavaScript(
        "window.playAvatarVisemes('$visemesJson');",
      );
    }
  }

  Future<void> stopAudioViseme() async {
    if (_channel != null) {
      await _channel?.invokeMethod('stopAudioViseme');
    } else {
      _webViewController?.runJavaScript("window.stopAvatar();");
    }
  }

  Future<List<Map<String, dynamic>>> loadVisemesFromAsset(String assetPath) {
    return _visemeHelper.loadVisemesFromAsset(assetPath);
  }

  // ✅ Play viseme for text-based lip sync
  Future<void> playVisemeForText(
    String text,
    List<Map<String, dynamic>> visemeEvents,
  ) async {
    try {
      if (_channel != null) {
        await _channel?.invokeMethod('playVisemeForText', {
          'text': text,
          'visemes': visemeEvents,
        });
      } else {
        final visemesJson = jsonEncode(visemeEvents);
        _webViewController?.runJavaScript(
          "window.playAvatarVisemes('$visemesJson');",
        );
      }
    } catch (e) {
      print('Error playing viseme for text: $e');
    }
  }

  // ✅ Trigger single viseme
  Future<void> triggerViseme(String visemeName, {double duration = 0.1}) async {
    try {
      if (_channel != null) {
        await _channel?.invokeMethod('triggerViseme', {
          'visemeName': visemeName,
          'duration': duration,
        });
      } else {
        _webViewController?.runJavaScript(
          "window.setMorphTarget('$visemeName', 1.0); setTimeout(() => window.setMorphTarget('$visemeName', 0.0), ${duration * 1000});",
        );
      }
    } catch (e) {
      print('Error triggering viseme: $e');
    }
  }

  // ✅ Reset avatar to neutral state
  Future<void> resetToNeutral() async {
    try {
      if (_channel != null) {
        await _channel?.invokeMethod('resetToNeutral');
      } else {
        _webViewController?.runJavaScript("window.resetMorphs();");
      }
    } catch (e) {
      print('Error resetting avatar: $e');
    }
  }

  // ✅ UPDATED METHOD: Trigger hand wave animation with proper animation path
  Future<void> triggerHandWave({double duration = 0.25}) async {
    try {
      print('👋 Triggering hand wave for ${duration}s');
      if (_channel != null) {
        // iOS Implementation - Pass animation path
        final animationPath = _getAnimationPath();
        await _channel?.invokeMethod('triggerHandWave', {
          'duration': duration,
          'animationPath': animationPath,
        });
      } else {
        // Android / Web
        _webViewController?.runJavaScript(
          "window.playAnimation('Wave', $duration);",
        );
      }
    } catch (e) {
      print('Error triggering hand wave: $e');
    }
  }

  // ✅ Play animation with custom path (direct from AppConstants)
  Future<void> triggerHandWaveWithPath(
    String animationPath, {
    double duration = 0.25,
  }) async {
    try {
      print(
        '👋 Triggering hand wave with path: $animationPath for ${duration}s',
      );
      if (_channel != null) {
        await _channel?.invokeMethod('triggerHandWave', {
          'duration': duration,
          'animationPath': animationPath,
        });
      } else {
        _webViewController?.runJavaScript(
          "window.playAnimation('Wave', $duration);",
        );
      }
    } catch (e) {
      print('Error triggering hand wave: $e');
    }
  }

  // ✅ Stop hand wave animation
  Future<void> stopHandWave() async {
    try {
      if (_channel != null) {
        await _channel?.invokeMethod('stopHandWave');
      } else {
        _webViewController?.runJavaScript("window.stopAnimation();");
      }
    } catch (e) {
      print('Error stopping hand wave: $e');
    }
  }

  // ✅ NEW METHOD: Play custom animation by name
  Future<void> playAnimation(
    String animationName, {
    double duration = 2.0,
  }) async {
    try {
      print('🎬 Playing animation: $animationName for ${duration}s');
      if (_channel != null) {
        // iOS Implementation
        final animationPath = _getAnimationPath();
        await _channel?.invokeMethod('playAnimation', {
          'animationName': animationName,
          'duration': duration,
          'animationPath': animationPath,
        });
      } else {
        // Android / Web
        _webViewController?.runJavaScript(
          "window.playAnimation('$animationName', $duration);",
        );
      }
    } catch (e) {
      print('Error playing animation: $e');
    }
  }

  // ✅ NEW METHOD: Stop any playing animation
  Future<void> stopAnimation() async {
    try {
      if (_channel != null) {
        await _channel?.invokeMethod('stopAnimation');
      } else {
        _webViewController?.runJavaScript("window.stopAnimation();");
      }
    } catch (e) {
      print('Error stopping animation: $e');
    }
  }

  // --- Viseme & Lip Sync Logic ---

  Future<void> loadVisemeData() async {
    if (_visemesLoaded) return;
    try {
      final String data = await rootBundle.loadString('test/data/viseme.txt');
      _parseVisemeData(data);
      _visemesLoaded = true;
    } catch (e) {
      print('Error loading viseme data: $e');
    }
  }

  void _parseVisemeData(String data) {
    final lines = data.split('\n');
    String? currentWord;
    List<VisemeData> currentVisemes = [];

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      if (!line.startsWith('(')) {
        if (currentWord != null && currentVisemes.isNotEmpty) {
          _visemeMap[currentWord.toLowerCase()] = List.from(currentVisemes);
        }
        currentWord = line;
        currentVisemes.clear();
      } else {
        final regex = RegExp(r"\('([^']+)',\s*([\d.]+),\s*([\d.]+)\)");
        final match = regex.firstMatch(line);
        if (match != null) {
          final visemeName = match.group(1)!;
          final startTime = double.parse(match.group(2)!);
          final endTime = double.parse(match.group(3)!);
          currentVisemes.add(VisemeData(visemeName, startTime, endTime));
        }
      }
    }

    if (currentWord != null && currentVisemes.isNotEmpty) {
      _visemeMap[currentWord.toLowerCase()] = currentVisemes;
    }
  }

  void speakWithLipSync(String text) {
    playAudioViseme(text, []); // Simplified placeholder call

    final words = text.toLowerCase().split(' ');

    for (var word in words) {
      word = word.replaceAll(RegExp(r'[^\wäöüß\s]', unicode: true), '').trim();

      if (word.isEmpty) continue;

      String? lookupWord = word;

      if (!_visemeMap.containsKey(lookupWord)) {
        lookupWord = word
            .replaceAll('ä', 'a')
            .replaceAll('ö', 'o')
            .replaceAll('ü', 'u')
            .replaceAll('ß', 'ss');
      }

      if (_visemeMap.containsKey(lookupWord)) {
        final visemes = _visemeMap[lookupWord]!;

        for (var viseme in visemes) {
          final delay = (viseme.startTime * 1000).toInt();
          final duration = (viseme.endTime - viseme.startTime);

          Future.delayed(Duration(milliseconds: delay), () {
            triggerViseme(viseme.name, duration: duration);
          });
        }
      }
    }
  }
}
