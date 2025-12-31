import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:language_app/helper/viseme_helper.dart';
import 'avatar_controller.dart';

class AvatarView extends StatefulWidget {
  final AvatarController? controller;
  final String? backgroundImagePath;
  final double? borderRadius;
  final double? height;
  final String? avatarName;

  const AvatarView({
    super.key,
    this.controller,
    this.height,
    this.backgroundImagePath,
    this.borderRadius,
    this.avatarName,
  });

  @override
  State<AvatarView> createState() => _AvatarViewState();
}

class _AvatarViewState extends State<AvatarView> {
  // final _visemeHelper = VisemeHelper();
  late final AvatarController _controller;

  @override
  void initState() {
    super.initState();

    _controller = widget.controller ?? AvatarController();
  }

  void _onPlatformViewCreated(int id) {
    _controller.attach(id);
    debugPrint('[FLUTTER] AvatarView attached $id');
  }

  @override
  void dispose() {
    debugPrint('[FLUTTER] AvatarView.dispose()');
    // Entsorge nur, wenn wir wirklich attached waren

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: widget.height ?? 220,
      child: UiKitView(
        viewType: 'AvatarView',
        onPlatformViewCreated: _onPlatformViewCreated,
        creationParams: {
          'backgroundImagePath': widget.backgroundImagePath,
          'borderRadius': widget.borderRadius,
          'avatarName': widget.avatarName,
        },
        creationParamsCodec: const StandardMessageCodec(),
      ),
    );
  }
}


   // ElevatedButton(
        //   onPressed: () async {
        //     final visemes = await _visemeHelper
        //         .loadVisemesFromAsset('test/data/viseme.txt');
        //     await _controller.playAudioViseme(
        //       'test/test_assets/russian_sample.wav',
        //       visemes,
        //     );
        //   },
        //   child: const Text('Start Dummy'),
        // ),