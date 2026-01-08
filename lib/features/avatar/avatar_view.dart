import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:language_app/app/constants/app_constants.dart';
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
  late final WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? AvatarController();
    
    // ✅ Set avatar name in controller
    if (widget.avatarName != null) {
      _controller.setAvatarName(widget.avatarName!);
    }

    if (defaultTargetPlatform != TargetPlatform.iOS) {
      _initWebView();
    }
  }

  void _initWebView() {
    // ✅ Android / Web - Initialize WebView
    String modelPath = widget.avatarName?.toLowerCase() == 'clara'
        ? AppConstants.claraModel
        : AppConstants.karlModel;

    final String fullModelPath =
        "file:///android_asset/flutter_assets/$modelPath";

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            debugPrint('Avatar Web Page Finished');
            _controller.attachWeb(_webViewController);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Web Error: ${error.description}');
          },
        ),
      )
      ..loadHtmlString(_buildHtml(fullModelPath));
  }

  String _buildHtml(String modelUrl) {
    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <script type="module" src="https://ajax.googleapis.com/ajax/libs/model-viewer/3.4.0/model-viewer.min.js"></script>
        <style>
          body { margin: 0; padding: 0; overflow: hidden; background: transparent; }
          model-viewer { width: 100vw; height: 100vh; background: transparent; }
        </style>
      </head>
      <body>
        <model-viewer 
          id="avatar" 
          src="$modelUrl" 
          camera-controls 
          disable-zoom 
          auto-rotate 
          shadow-intensity="1" 
          camera-orbit="0deg 75deg 105%" 
          field-of-view="30deg">
        </model-viewer>

        <script>
          const modelViewer = document.querySelector('#avatar');
          
          window.playAnimation = (name, duration) => {
            if (modelViewer.availableAnimations && modelViewer.availableAnimations.includes(name)) {
              modelViewer.animationName = name;
              modelViewer.play();
              if (duration > 0) {
                 setTimeout(() => {
                   modelViewer.pause();
                   modelViewer.animationName = null;
                 }, duration * 1000);
              }
            } else {
              console.log('Animation not found: ' + name);
              console.log('Available animations:', modelViewer.availableAnimations);
            }
          };

          window.stopAnimation = () => {
            modelViewer.pause();
            modelViewer.animationName = null;
          };

          window.setMorphTarget = (target, value) => {
             if (!modelViewer.model) return;
             console.log('Setting morph: ' + target + ' to ' + value);
             // Note: Full morph target implementation requires Three.js scene access
          };

          window.playAvatarVisemes = (visemesJson) => {
             const visemes = JSON.parse(visemesJson);
             console.log('Playing ' + visemes.length + ' visemes');
             visemes.forEach((v, index) => {
                setTimeout(() => {
                   console.log('Viseme: ' + v.id);
                }, v.start * 1000);
             });
          };
          
          window.resetMorphs = () => {
             console.log('Reset morphs');
          };

          // ✅ Log available animations when model loads
          modelViewer.addEventListener('load', () => {
            console.log('Model loaded');
            console.log('Available animations:', modelViewer.availableAnimations);
          });
        </script>
      </body>
      </html>
    ''';
  }

  void _onPlatformViewCreated(int id) {
    _controller.attach(id);
    
    // ✅ Pass avatar name and animation path to native iOS
    if (widget.avatarName != null) {
      final animationPath = widget.avatarName?.toLowerCase() == 'clara'
          ? AppConstants.claraAnimationPath
          : AppConstants.karlAnimationPath;
      
      debugPrint('[FLUTTER] AvatarView attached $id with avatar: ${widget.avatarName}');
      debugPrint('[FLUTTER] Animation path: $animationPath');
    }
  }

  @override
  void dispose() {
    debugPrint('[FLUTTER] AvatarView.dispose()');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ iOS - Native UiKitView (USDZ)
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // Get animation path based on avatar name
      final animationPath = widget.avatarName?.toLowerCase() == 'clara'
          ? AppConstants.claraAnimationPath
          : AppConstants.karlAnimationPath;

      return SizedBox(
        height: widget.height ?? 220,
        child: UiKitView(
          viewType: 'AvatarView',
          onPlatformViewCreated: _onPlatformViewCreated,
          creationParams: {
            'backgroundImagePath': widget.backgroundImagePath,
            'borderRadius': widget.borderRadius,
            'avatarName': widget.avatarName,
            'animationPath': animationPath, // ✅ Pass animation path
          },
          creationParamsCodec: const StandardMessageCodec(),
        ),
      );
    }

    // ✅ Android - Custom WebView
    if (defaultTargetPlatform == TargetPlatform.android) {
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
          child: WebViewWidget(controller: _webViewController),
        ),
      );
    }

    // Fallback
    return const SizedBox();
  }
}