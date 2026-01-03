import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ iOS এর জন্য - Native UiKitView (USDZ)
    if (defaultTargetPlatform == TargetPlatform.iOS) {
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

    // ✅ Android এর জন্য - ModelViewer (GLB)
    String modelPath = widget.avatarName?.toLowerCase() == 'clara'
        ? 'assets/models/clara.glb'
        : 'assets/models/karl.glb';

    return Container(
      height: widget.height ?? 220,
      decoration: widget.backgroundImagePath != null
          ? BoxDecoration(
              image: DecorationImage(
                image: AssetImage(widget.backgroundImagePath!),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(widget.borderRadius ?? 0),
            )
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius ?? 0),
        child: ModelViewer(
          backgroundColor: Colors.transparent,
          src: modelPath,
          alt: '${widget.avatarName ?? "Avatar"} 3D Model',
          ar: false,
          autoRotate: false,
          cameraControls: false,
          disableZoom: true,
          shadowIntensity: 1,
          shadowSoftness: 1,
          exposure: 1.0,
          loading: Loading.eager,
          reveal: Reveal.auto,
          cameraOrbit: '0deg 75deg 105%',
          minCameraOrbit: 'auto auto 105%',
          maxCameraOrbit: 'auto auto 105%',
          cameraTarget: 'auto auto auto',
          fieldOfView: '30deg',
          interpolationDecay: 200,
        ),
      ),
    );
  }
}