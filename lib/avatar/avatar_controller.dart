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
}
