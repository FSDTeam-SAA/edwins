import 'dart:ffi';

import 'package:flutter/foundation.dart';
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
      'visemes': visemeEvents, // aktuell auf iOS noch ungenutzt
    });
  }

  Future<void> stopAudioViseme() async {}

  Future<void> testModelfile(String filePath) async {}

  // Future<void> _startDummy() async {
  //   try {
  //     await _channel?.invokeMethod('startDummy');
  //   } catch (e) {
  //     debugPrint('startDummy error: $e');
  //     if (mounted) {
  //       ScaffoldMessenger.of(context)
  //           .showSnackBar(SnackBar(content: Text('startDummy: $e')));
  //     }
  //   }
  // }

  // Future<void> _stopDummy() async {
  //   await _channel?.invokeMethod('stopDummy');
  // }

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
