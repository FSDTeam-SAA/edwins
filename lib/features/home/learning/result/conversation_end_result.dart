import 'package:flutter/material.dart';
import 'package:language_app/core/providers/avatar_provider.dart';
import 'package:language_app/features/home/conversation/conversation_chat.dart';
import 'package:language_app/features/home/vocabulary/vocabulary_lessons.dart';
import 'package:lottie/lottie.dart';
import 'package:language_app/app/theme/app_style.dart';
import 'package:language_app/core/widgets/radar_chart.dart';
import 'package:language_app/features/home/home_view.dart';
import 'package:provider/provider.dart';

class ConversationEndResultView extends StatelessWidget {
  final Map<String, int> skills;
  final int scorePercent;

  const ConversationEndResultView({
    super.key,
    required this.skills,
    this.scorePercent = 75,
  });

  @override
  Widget build(BuildContext context) {
    // Extracting arguments
    final Map<String, int>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, int>?;
    final displaySkills = args ?? skills;
    final textTheme = Theme.of(context).textTheme;
    final avatarProvider = Provider.of<AvatarProvider>(context, listen: false);

    return Scaffold(
      // UX Improvement: Subtle background gradient prevents the "flat" look
      // and helps the chart blend into the bottom of the screen.
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              const Color(
                0xFFFFF8E1,
              ).withOpacity(0.5), // Very subtle warm tint at bottom
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            // const SizedBox(height: 5),
                            // ------------------------------
                            // 1. TOP: Congratulation & Animation
                            // ------------------------------
                            SizedBox(
                              height: 100,
                              child: Lottie.asset(
                                "assets/animations/Success.json",
                                repeat: false,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "Congratulations! 🎯",
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppColors.successGreenDark,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "You have completed lesson 1 successfully!",
                              style: textTheme.bodyLarge?.copyWith(
                                color: Colors.grey[600],
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 5),

                            // ------------------------------
                            // 2. MIDDLE: Infinity Blended Chart
                            // ------------------------------
                            Column(
                              children: [
                                Text(
                                  "SESSION SCORE",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      "$scorePercent",
                                      style: const TextStyle(
                                        fontSize: 56,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.primaryOrange,
                                        height: 1.0,
                                      ),
                                    ),
                                    const Text(
                                      "%",
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryOrange,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // The "Infinity" Blended Chart Area
                            SizedBox(
                              height: 320,
                              width: double.infinity,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 320,
                                    height: 320,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          AppColors.primaryOrange.withOpacity(
                                            0.15,
                                          ),
                                          AppColors.primaryOrange.withOpacity(
                                            0.02,
                                          ),
                                          Colors.transparent,
                                        ],
                                        stops: const [0.0, 0.7, 1.0],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: ProgressRadarChart(
                                      skills: displaySkills,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // ------------------------------
                        // 3. BOTTOM: Action Buttons
                        // ------------------------------
                        Column(
                          children: [
                            const SizedBox(height: 20),
                            _buildGradientButton(
                              context,
                              "Continue to the Conversation Lesson",
                              gradient: AppColors.greenGradient,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ConversationChat(
                                      selectedAvatarName:
                                          avatarProvider.selectedAvatarName,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildGradientButton(
                              context,
                              "Repeat Vocabulary",
                              gradient: AppColors.primaryGradient,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => VocabularyLessons(
                                      selectedAvatarName:
                                          avatarProvider.selectedAvatarName,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildOutlineButton(
                              context,
                              "Back to Home",
                              onTap: () => Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const HomeView(
                                    initialHasStartedLearning: true,
                                  ),
                                ),
                                (route) => false,
                              ),
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildOutlineButton(
    BuildContext context,
    String text, {
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primaryOrange.withOpacity(0.5),
              width: 1.5,
            ),
            color: Colors.white.withOpacity(0.8),
          ),
          child: Center(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.primaryOrange,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientButton(
    BuildContext context,
    String text, {
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
