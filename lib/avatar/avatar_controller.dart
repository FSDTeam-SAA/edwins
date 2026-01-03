import 'package:flutter/services.dart';
import 'package:language_app/helper/file_helper.dart';
import 'package:language_app/helper/viseme_helper.dart';

class AvatarController {
  MethodChannel? _channel;
  final FileHelper _fileHelper;
  final VisemeHelper _visemeHelper;

  AvatarController({
    FileHelper? fileHelper,
    VisemeHelper? visemeHelper,
  })  : _fileHelper = fileHelper ?? FileHelper(),
        _visemeHelper = visemeHelper ?? VisemeHelper();

  void attach(int viewId) {
    _channel = MethodChannel('AvatarView/$viewId');
  }

  bool get isAttached => _channel != null;

  Future<void> disposeView() async {
    try {
      await _channel?.invokeMethod('dispose');
    } catch (_) {}
    print("channel weg: ${_channel?.name}");
    _channel = null;
  }

  Future<void> playAudioViseme(
    String audioPath,
    List<Map<String, dynamic>> visemeEvents,
  ) async {
    final resolvedPath = await _fileHelper.ensureFileOnDisk(audioPath);
    await _channel?.invokeMethod('playAudioViseme', {
      'audioPath': resolvedPath,
      'visemes': visemeEvents,
    });
  }

  Future<void> stopAudioViseme() async {
    await _channel?.invokeMethod('stopAudioViseme');
  }

  Future<List<Map<String, dynamic>>> loadVisemesFromAsset(String assetPath) {
    return _visemeHelper.loadVisemesFromAsset(assetPath);
  }

  // ✅ NEW METHOD: Play viseme for text-based lip sync
  Future<void> playVisemeForText(String text, List<Map<String, dynamic>> visemeEvents) async {
    try {
      await _channel?.invokeMethod('playVisemeForText', {
        'text': text,
        'visemes': visemeEvents,
      });
    } catch (e) {
      print('Error playing viseme for text: $e');
    }
  }

  // ✅ NEW METHOD: Trigger single viseme
  Future<void> triggerViseme(String visemeName, {double duration = 0.1}) async {
    try {
      await _channel?.invokeMethod('triggerViseme', {
        'visemeName': visemeName,
        'duration': duration,
      });
    } catch (e) {
      print('Error triggering viseme: $e');
    }
  }

  // ✅ NEW METHOD: Reset avatar to neutral state
  Future<void> resetToNeutral() async {
    try {
      await _channel?.invokeMethod('resetToNeutral');
    } catch (e) {
      print('Error resetting avatar: $e');
    }
  }
}