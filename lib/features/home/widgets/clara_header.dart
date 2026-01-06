import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:language_app/core/models/learning_models.dart';
import 'package:language_app/app/theme/app_style.dart';

class ClaraHeader extends StatelessWidget {
  final LessonStep step;
  final FlutterTts flutterTts;

  const ClaraHeader({super.key, required this.step, required this.flutterTts});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3E7),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Center(child: Image.asset("assets/avatar/avatar1.png", fit: BoxFit.contain)),
          Positioned(
            bottom: 15,
            right: 15,
            child: GestureDetector(
              onTap: () async {
                final correctChoice = step.choices?.firstWhere((c) => c.isCorrect);
                if (correctChoice != null) {
                  await flutterTts.setLanguage("de-DE");
                  await flutterTts.speak(correctChoice.text);
                }
              },
              child: const Icon(Icons.volume_up_rounded, color: AppColors.primaryOrange, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}