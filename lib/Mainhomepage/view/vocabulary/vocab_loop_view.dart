import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:language_app/Mainhomepage/view/Result/result_view.dart';
import 'package:language_app/widgets/data/repository.dart';
// Your existing logic imports
import '../../../models/learning_models.dart';

// Updated widgets to match your new design
import '../widgets/clara_header.dart';
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
  
  String? selectedChoiceId;
  String? selectedChoiceText;
  bool showError = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<LessonStep>(
          future: repository.fetchNextStep(widget.lessonId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFFF8000)));
            }
            if (!snapshot.hasData) return const Center(child: Text("Step not found"));

            final step = snapshot.data!;
            final isSentenceType = step.type == "complete_mc";
            final correctChoice = step.choices!.firstWhere((c) => c.isCorrect);

            return Stack(
              children: [
                Column(
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 4),
                    
                    // Uses your high-quality character frame logic
                    ClaraHeader(step: step, flutterTts: flutterTts),
                    
                    const SizedBox(height: 24),

                    // Dynamic layout based on backend 'type'
                    isSentenceType 
                        ? _buildFillBlankLayout(step)
                        : _buildMultipleChoiceLayout(step),

                    const Spacer(),

                    // Action Button
                    _buildContinueButton(step),
                  ],
                ),

                // Error Dialog Overlay (Your new UI design)
                if (showError) _buildErrorDialog(correctChoice.text),
              ],
            );
          },
        ),
      ),
    );
  }

  // --- UI Components from your updated design ---

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFFF8000), size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'Clara',
            style: TextStyle(color: Color(0xFFFF8000), fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildMultipleChoiceLayout(LessonStep step) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFFF8000), width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
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
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.language, size: 22, color: Color(0xFFFF8000)),
              SizedBox(width: 16),
              Icon(Icons.volume_up, size: 22, color: Color(0xFFFF609D)),
            ],
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

  Widget _buildContinueButton(LessonStep step) {
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
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
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
      // Success: Move to next step via backend logic
      if (widget.lessonId == "lesson_1") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const VocabLoopView(lessonId: "lesson_2")),
        );
      } else {
        // Navigator.pushNamed(context, '/vocab-result');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ResultView(
          skills: {
            "Speaking": 80,
            "Listening": 65,
            "Grammar": 90,
            "Vocabulary": 70,
            "Writing": 55,
          },
        ),),
        );
      }
    } else {
      // Failure: Show the error overlay
      setState(() => showError = true);
    }
  }

  Widget _buildErrorDialog(String correctAnswer) {
    return Container(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: const Color(0xFFFF3333),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  "It's incorrect.",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: Column(
                  children: [
                    const Text('The right answer is', style: TextStyle(color: Color(0xFF757575), fontSize: 15)),
                    const SizedBox(height: 8),
                    Text(
                      correctAnswer,
                      style: const TextStyle(color: Color(0xFFFF6347), fontSize: 26, fontWeight: FontWeight.bold),
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
                          gradient: const LinearGradient(colors: [Color(0xFFFF609D), Color(0xFFFF7A06)]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Text('Continue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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