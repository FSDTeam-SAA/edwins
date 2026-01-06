import 'package:flutter/material.dart';
import 'package:language_app/app/constants/app_constants.dart';
import 'package:language_app/features/avatar/avatar_controller.dart';
import 'package:language_app/features/avatar/avatar_view.dart';
import 'package:language_app/core/widgets/progess_visual.dart';
import 'package:language_app/core/widgets/gradient_button.dart';
import 'package:language_app/features/debug/avatar_test_page.dart';

class AvatarDemoPage extends StatefulWidget {
  const AvatarDemoPage({super.key});

  @override
  State<AvatarDemoPage> createState() => _AvatarDemoPageState();
}

class _AvatarDemoPageState extends State<AvatarDemoPage> {
  final avatarController = AvatarController();

  Future<void> _openFull() async {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const AvatarTestPage(),
      fullscreenDialog: false,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.avatarDemoTitle)),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: ListView(
          //crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 290,
              decoration: BoxDecoration(
                border: Border.all(
                    color: const Color(
                      0xFFFF7B2E,
                    ),
                    width: 1.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: CustomPaint(
                  size: const Size(240, 240),
                  painter: PentagonPainter(
                    lineValues: [
                      LineValue(label: AppConstants.grammar, value: 0.4),
                      LineValue(label: AppConstants.pronunciation, value: 0.5),
                      LineValue(label: AppConstants.vocabulary, value: 0.9),
                      LineValue(label: AppConstants.listening, value: 0.5),
                      LineValue(label: AppConstants.speaking, value: 0.7),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 12,
            ),
            AvatarView(
              avatarName: AppConstants.avatarKarl,
              borderRadius: 20,
              controller: avatarController,
              backgroundImagePath: AppConstants.backgroundImage,
            ),
            const SizedBox(
              height: 8,
            ),
            GradientButton(
              onPressed: _openFull,
              text: AppConstants.startConversation,
              icon: Icons.chat_bubble_outline,
            )
          ],
        ),
      ),
    );
  }
}
