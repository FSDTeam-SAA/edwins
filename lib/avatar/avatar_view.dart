import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:language_app/helper/viseme_helper.dart';
import 'avatar_controller.dart';

class AvatarView extends StatefulWidget {
  final AvatarController? controller;

  const AvatarView({super.key, this.controller});

  @override
  State<AvatarView> createState() => _AvatarViewState();
}

class _AvatarViewState extends State<AvatarView> {
  late final AvatarController _controller;
  final _visemeHelper = VisemeHelper();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? AvatarController();
  }

  void _onPlatformViewCreated(int id) {
    _controller.attach(id);
    debugPrint('AvatarView channel ready: AvatarView/$id');
  }

  @override
  Widget build(BuildContext context) {
    // Nur auf iOS rendern – sonst Platzhalter
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Expanded(
          child: UiKitView(
            viewType: 'AvatarView',
            onPlatformViewCreated: _onPlatformViewCreated,
            creationParams: const <String, dynamic>{},
            creationParamsCodec: const StandardMessageCodec(),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            final visemes = await _visemeHelper
                .loadVisemesFromAsset('test/data/viseme.txt');
            await _controller.playAudioViseme(
              'test/test_assets/russian_sample.wav',
              visemes,
            );
          },
          child: const Text('Start Dummy'),
        ),
      ],
    );
  }
}



/*import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:language_app/helper/file_helper.dart';
import 'package:language_app/helper/viseme_helper.dart';

class AvatarView extends StatefulWidget {
  const AvatarView({super.key});

  @override
  State<AvatarView> createState() => _AvatarViewState();
}

class _AvatarViewState extends State<AvatarView> {
  MethodChannel? _channel;
  final FileHelper _fileHelper = FileHelper();
  final VisemeHelper _visemeHelper = VisemeHelper();

  void _onCreated(int id) {
    _channel = MethodChannel('AvatarView/$id');
    debugPrint('AvatarView channel ready: AvatarView/$id');
  }

  Future<void> playAudioViseme(
      String audioPath, List<Map<String, dynamic>> visemeEvents) async {
    final resolvedPath = await _fileHelper.ensureFileOnDisk(audioPath);
    await _channel?.invokeMethod('playAudioViseme', {
      'audioPath': resolvedPath,
      'visemes': visemeEvents,
    });
  }

  Future<void> stopAudioViseme() async {
    await _channel?.invokeMethod('stopAudioViseme');
  }

  Future<Map<String, dynamic>> testModelFile(
      {List<String> requiredNames = const []}) async {
    final res = await _channel?.invokeMethod('testModelFile', {
      'requiredNames': requiredNames,
    });
    return Map<String, dynamic>.from(res as Map);
  }

  @override
  Widget build(BuildContext context) {
    // Nur auf iOS rendern – auf anderen Plattformen leeren Platzhalter zeigen
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Expanded(
          child: UiKitView(
            viewType: 'AvatarView',
            onPlatformViewCreated: _onCreated,
          ),
        ),
        ElevatedButton(
            onPressed: () async {
              final visemes = await _visemeHelper
                  .loadVisemesFromAsset('test/data/viseme.txt');
              await playAudioViseme(
                  "test/test_assets/russian_sample.wav", visemes);
            },
            child: const Text('Start Dummy')),
      ],
    );
  }
}
*/