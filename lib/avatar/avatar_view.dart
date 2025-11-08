import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:language_app/helper/viseme_helper.dart';
import 'avatar_controller.dart';

class AvatarView extends StatefulWidget {
  final AvatarController? controller;
  final String? backgroundImagePath;

  const AvatarView({super.key, this.controller, this.backgroundImagePath});

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
            creationParams: {
              'backgroundImagePath': widget.backgroundImagePath,
              'avatar': const {
                'name': 'Clara',
                'avatarPath': 'assets/avatar/clara/ClaraAvatar.usdz',
                'animations': {'Idle': 'assets/avatar/clara/Idle.dae'}
              },
            },
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
