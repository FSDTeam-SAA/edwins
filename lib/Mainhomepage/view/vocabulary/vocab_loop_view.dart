import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:language_app/providers/avatar_provider.dart';
import 'package:language_app/avatar/avatar_controller.dart';
import 'package:language_app/avatar/avatar_view.dart';
import 'package:language_app/Mainhomepage/view/Result/result_view.dart';
import 'package:language_app/widgets/data/repository.dart';
import '../../../models/learning_models.dart';
import '../widgets/choice_chip_widget.dart';
class VocabLoopView extends StatefulWidget {
  final String lessonId;
  const VocabLoopView({super.key, required this.lessonId});

  @override
  State<VocabLoopView> createState() => _VocabLoopViewState();
}

class _VocabLoopViewState extends State<VocabLoopView> {
  final FlutterTts flutterTts = FlutterTts();
  final ILearningRepository repository = MockLearningRepository();
  final AvatarController _avatarController = AvatarController();

  String? selectedChoiceId;
  String? selectedChoiceText;
  bool showError = false;

  @override
  void dispose() {
    _avatarController.disposeView();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get selected avatar from provider
    final selectedAvatarName =
        context.watch<AvatarProvider>().selectedAvatarName;
    final themeColor = _getThemeColor(selectedAvatarName);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<LessonStep>(
          future: repository.fetchNextStep(widget.lessonId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF8000)),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: Text("Step not found"));
            }

            final step = snapshot.data!;
            final isSentenceType = step.type == "complete_mc";
            final correctChoice = step.choices!.firstWhere((c) => c.isCorrect);

            return Stack(
              children: [
                Column(
                  children: [
                    // Avatar Header with Lesson Info
                    _buildAvatarHeader(
                      context,
                      selectedAvatarName,
                      themeColor,
                      step,
                    ),

                    const SizedBox(height: 24),

                    // Dynamic layout based on backend 'type'
                    isSentenceType
                        ? _buildFillBlankLayout(step)
                        : _buildMultipleChoiceLayout(step),

                    const Spacer(),

                    // Action Button
                    _buildContinueButton(step, themeColor),
                  ],
                ),

                // Error Dialog Overlay
                if (showError) _buildErrorDialog(correctChoice.text),
              ],
            );
          },
        ),
      ),
    );
  }

  // --- Get Theme Color Based on Avatar ---
  Color _getThemeColor(String avatarName) {
    switch (avatarName) {
      case "Clara":
        return const Color(0xFFFF609D); // Pink
      case "Karl":
        return const Color(0xFF4A90E2); // Blue
      default:
        return const Color(0xFFFF8000); // Orange default
    }
  }

  // --- Avatar Header Component ---
  Widget _buildAvatarHeader(
    BuildContext context,
    String avatarName,
    Color themeColor,
    LessonStep step,
  ) {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [themeColor, themeColor.withOpacity(0.7)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          // 3D Avatar View
          Positioned.fill(
            child: AvatarView(
              avatarName: avatarName,
              controller: _avatarController,
              height: 320,
              backgroundImagePath: "assets/images/background.png",
              borderRadius: 0,
            ),
          ),

          // Back Button
          Positioned(
            top: 8,
            left: 4,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Avatar Name Label
          Positioned(
            top: 8,
            left: 50,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                avatarName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Question Bubble at Bottom
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Speaker Icon
                  GestureDetector(
                    onTap: () => _speakQuestion(step.question ?? ''),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: themeColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.volume_up,
                        color: themeColor,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Question Text
                  Expanded(
                    child: Text(
                      step.question ?? 'Select the correct answer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Speak Question Method ---
  Future<void> _speakQuestion(String text) async {
    await flutterTts.setLanguage("en-US");

    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak(text);
  }

  // --- Multiple Choice Layout ---
  Widget _buildMultipleChoiceLayout(LessonStep step) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      // decoration: BoxDecoration(
      //   color: Colors.white,
      //   border: Border.all(color: const Color(0xFFFF8000), width: 2),
      //   borderRadius: BorderRadius.circular(16),
      // ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: step.choices!.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemBuilder: (context, index) {
          final choice = step.choices![index];
          return ChoiceChipWidget(
            choice: choice,
            isSelected: selectedChoiceId == choice.id,
            onTap: () => _onChoiceSelected(choice),
            isLarge: true,
          );
        },
      ),
    );
  }

  // --- Fill in the Blank Layout ---
  Widget _buildFillBlankLayout(LessonStep step) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFFF8000), width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            step.question ?? '',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: step.choices!.map((choice) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChipWidget(
                    choice: choice,
                    isSelected: selectedChoiceId == choice.id,
                    onTap: () => _onChoiceSelected(choice),
                    isLarge: false,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // --- Continue Button ---
  Widget _buildContinueButton(LessonStep step, Color themeColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: GestureDetector(
        onTap: () => _handleContinue(step),
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                    colors: [Color(0xFFFF609D), Color(0xFFFF7A06)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: const Text(
            'Continue',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // --- Logic Methods ---

  void _onChoiceSelected(Choice choice) {
    setState(() {
      selectedChoiceId = choice.id;
      selectedChoiceText = choice.text;
    });
  }

  void _handleContinue(LessonStep step) {
    if (selectedChoiceId == null) return;

    final correctChoice = step.choices!.firstWhere((c) => c.isCorrect);

    if (selectedChoiceId == correctChoice.id) {
      // Success: Move to next step
      if (widget.lessonId == "lesson_1") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const VocabLoopView(lessonId: "lesson_2"),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ResultView(
              skills: {
                "Speaking": 80,
                "Listening": 65,
                "Grammar": 90,
                "Vocabulary": 70,
                "Writing": 55,
              },
            ),
          ),
        );
      }
    } else {
      // Failure: Show error overlay
      setState(() => showError = true);
    }
  }

  // --- Error Dialog ---
  Widget _buildErrorDialog(String correctAnswer) {
    return Container(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors:[Color(0xFFFF8A65),Color(0xFFFF5C7C),],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight
            ),
            color: const Color.fromARGB(255, 230, 112, 112),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  "It's incorrect.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text(
                      'The right answer is',
                      style: TextStyle(color: Color(0xFF757575), fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      correctAnswer,
                      style: const TextStyle(
                        color: Color(0xFFFF6347),
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 18),
                    GestureDetector(
                      onTap: () => setState(() {
                        showError = false;
                        selectedChoiceId = null;
                      }),
                      child: Container(
                        width: double.infinity,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF609D), Color(0xFFFF7A06)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
