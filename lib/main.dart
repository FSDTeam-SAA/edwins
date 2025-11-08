import 'package:flutter/material.dart';
import 'package:language_app/avatar/avatar_controller.dart';
import 'package:language_app/avatar/avatar_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Talknizr',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: AvatarDemoPage());
  }
}

class AvatarDemoPage extends StatelessWidget {
  AvatarDemoPage({super.key});
  final avatarController = AvatarController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Avatar Demo')),
      body: AspectRatio(
        aspectRatio: 1,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AvatarView(
                20,
                controller: avatarController,
                backgroundImagePath: "assets/images/background.png",
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// bundle exec pod repo update
// bundle exec pod deintegrate
// rm -rf Pods Podfile.lock
// bundle exec pod install
