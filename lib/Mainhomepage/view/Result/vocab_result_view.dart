import 'package:flutter/material.dart';
import 'package:language_app/Mainhomepage/view/Result/Congratulation_screen.dart';
import '../../../utils/app_style.dart';
import '../../../widgets/radar_chart.dart';

class VocabResultView extends StatelessWidget {
  final Map<String, int> skills;
  final int scorePercent;

  const VocabResultView({
    super.key,
    required this.skills,
    this.scorePercent = 75,
  });

  @override
  Widget build(BuildContext context) {
    // Extracting arguments if passed via Navigator
    final Map<String, int>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, int>?;
    final displaySkills = args ?? skills;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.primaryOrange,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),

            // 1. Header Section
            const Text(
              "Your Vocabulary Score",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "$scorePercent%",
              style: const TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: Color(0xFFFF7B7B), // Matching the reddish-orange in UI
              ),
            ),

            const Spacer(),

            // 2. Radar Chart Section
            // In your image, the chart is contained within a soft yellow circle
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFFDE7), // Light yellow background
                      border: Border.all(
                        color: const Color(0xFFFFF9C4),
                        width: 2,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 340, // Slightly larger to accommodate labels
                    width: 340,
                    child: ProgressRadarChart(skills: displaySkills),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 2),

            // 3. Bottom Action Button
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Container(
                width: double.infinity,
                height: 58,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LessonCompletionView(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    "Continue",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
