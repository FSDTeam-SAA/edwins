import 'package:flutter/material.dart';
import 'package:language_app/Mainhomepage/view/vocabulary/vocabulary_lessons.dart';
import 'package:lottie/lottie.dart';
import 'package:language_app/utils/app_style.dart';
import 'package:language_app/widgets/radar_chart.dart';
import 'package:language_app/Mainhomepage/home_view.dart';

class LessonEndResultView extends StatelessWidget {
  final Map<String, int> skills;
  final int scorePercent;

  const LessonEndResultView({
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
              const Color(0xFFFFF8E1).withOpacity(0.5), // Very subtle warm tint at bottom
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const Spacer(flex: 1),

                // ------------------------------
                // 1. TOP: Congratulation & Animation
                // ------------------------------
                SizedBox(
                  height: 140, // Slightly larger for impact
                  child: Lottie.asset(
                    "assets/animations/Success.json",
                    repeat: false,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Congratulations! 🎯",
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.successGreenDark,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "You have completed the lesson successfully!",
                  style: textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const Spacer(flex: 2),

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
                      crossAxisAlignment: CrossAxisAlignment.baseline,
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
                      // Layer 1: The Glow (Replaces the hard border)
                      // This creates the "Infinity" blend effect
                      Container(
                        width: 320,
                        height: 320,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.primaryOrange.withOpacity(0.15), // Inner glow
                              AppColors.primaryOrange.withOpacity(0.02), // Outer fade
                              Colors.transparent, // Seamless blend
                            ],
                            stops: const [0.0, 0.7, 1.0],
                          ),
                        ),
                      ),
                      
                      // Layer 2: The Actual Chart
                      Padding(
                        padding: const EdgeInsets.all(20.0), // Padding to let the glow breathe
                        child: ProgressRadarChart(skills: displaySkills),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // ------------------------------
                // 3. BOTTOM: Action Buttons
                // ------------------------------
                _buildOutlineButton(
                  context,
                  "Back to Home",
                  onTap: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeView()),
                    (route) => false,
                  ),
                ),
                
                const SizedBox(height: 16),

                _buildGradientButton(
                  context,
                  "Next Vocabulary Lesson",
                  gradient: AppColors.primaryGradient,
                  onTap: () {
                     Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const VocabLoopView(lessonId: "lesson_2"), 
                      ),
                    );
                  },
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildOutlineButton(BuildContext context, String text,
      {required VoidCallback onTap}) {
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
            border: Border.all(color: AppColors.primaryOrange.withOpacity(0.5), width: 1.5),
            color: Colors.white.withOpacity(0.8),
          ),
          child: Center(
            child: Text(
              text,
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
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20)
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:lottie/lottie.dart';
// // Ensure these imports match your project structure
// import 'package:language_app/utils/app_style.dart';
// import 'package:language_app/widgets/radar_chart.dart';
// import 'package:language_app/Mainhomepage/home_view.dart';
// import 'package:language_app/Mainhomepage/view/vocabulary/vocabulary_lessons.dart';

// class LessonEndResultView extends StatelessWidget {
//   final Map<String, int> skills;
//   final int scorePercent;

//   const LessonEndResultView({
//     super.key,
//     required this.skills,
//     this.scorePercent = 75,
//   });

//   @override
//   Widget build(BuildContext context) {
//     // Extracting arguments if passed via Navigator
//     final Map<String, int>? args =
//         ModalRoute.of(context)?.settings.arguments as Map<String, int>?;
//     final displaySkills = args ?? skills;
//     final textTheme = Theme.of(context).textTheme;

//     return Scaffold(
//       backgroundColor: Colors.white,
//       // appBar: AppBar(
//       //   backgroundColor: Colors.white,
//       //   elevation: 0,
//       //   leading: IconButton(
//       //     icon: const Icon(
//       //       Icons.arrow_back_ios,
//       //       color: AppColors.primaryOrange,
//       //     ),
//       //     onPressed: () => Navigator.pop(context),
//       //   ),
//       // ),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24.0),
//           child: Column(
//             children: [
//               const SizedBox(height: 10),

//               // ------------------------------
//               // 1. TOP: Congratulation Text & Animation
//               // ------------------------------
//               SizedBox(
//                 height: 120,
//                 child: Lottie.asset(
//                   "assets/animations/Success.json",
//                   repeat: false,
//                 ),
//               ),
//               const SizedBox(height: 10),
//               Text(
//                 "Congratulations! 🎯",
//                 style: textTheme.headlineSmall?.copyWith(
//                   fontWeight: FontWeight.w800,
//                   color: AppColors.successGreenDark,
//                   letterSpacing: 0.5,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 "You have completed the lesson successfully!",
//                 style: textTheme.titleMedium?.copyWith(
//                   fontWeight: FontWeight.w600,
//                   color: AppColors.primaryOrange,
//                   fontSize: 14,
//                 ),
//                 textAlign: TextAlign.center,
//               ),

//               const Spacer(),

//               // ------------------------------
//               // 2. MIDDLE: Radar Chart & Score
//               // ------------------------------
//               Text(
//                 "Your Session Score",
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.grey[700],
//                 ),
//               ),
//               Text(
//                 "$scorePercent%",
//                 style: const TextStyle(
//                   fontSize: 42,
//                   fontWeight: FontWeight.w900,
//                   color: Color(0xFFFF7B7B), // Reddish-orange
//                 ),
//               ),
//               const SizedBox(height: 10),
              
//               // Radar Chart Stack
//               SizedBox(
//                 height: 300, 
//                 width: 300,
//                 child: Stack(
//                   alignment: Alignment.center,
//                   children: [
//                     // Background Yellow Circle
//                     Container(
//                       width: 280,
//                       height: 280,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: const Color(0xFFFFFDE7), // Light yellow background
//                         border: Border.all(
//                           color: const Color(0xFFFFF9C4),
//                           width: 2,
//                         ),
//                       ),
//                     ),
//                     // The Actual Chart
//                     Padding(
//                       padding: const EdgeInsets.all(10.0),
//                       child: ProgressRadarChart(skills: displaySkills),
//                     ),
//                   ],
//                 ),
//               ),

//               const Spacer(),

//               // ------------------------------
//               // 3. BOTTOM: Buttons
//               // ------------------------------
              
//               // Button 1: Back to Home
//               _buildOutlineButton(
//                 context,
//                 "Back to Home",
//                 onTap: () => Navigator.pushAndRemoveUntil(
//                   context,
//                   MaterialPageRoute(builder: (_) => const HomeView()),
//                   (route) => false, // Remove back stack
//                 ),
//               ),
              
//               const SizedBox(height: 15),

//               // Button 2: Next Lesson
//               _buildGradientButton(
//                 context,
//                 "Next Vocabulary Lesson",
//                 gradient: AppColors.primaryGradient,
//                 onTap: () {
//                    // Logic for next lesson (e.g., increment lesson ID)
//                    Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) =>
//                           const VocabLoopView(lessonId: "lesson_2"), 
//                     ),
//                   );
//                 },
//               ),

//               const SizedBox(height: 30),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // --- Helper Widgets ---

//   /// Outlined Button (Used for Back to Home)
//   Widget _buildOutlineButton(BuildContext context, String text,
//       {required VoidCallback onTap}) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: double.infinity,
//         height: 55,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(color: AppColors.primaryOrange, width: 2),
//           color: Colors.white,
//         ),
//         child: Center(
//           child: Text(
//             text,
//             style: const TextStyle(
//               color: AppColors.primaryOrange,
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   /// Gradient Filled Button (Used for Next Lesson)
//   Widget _buildGradientButton(
//     BuildContext context,
//     String text, {
//     required Gradient gradient,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: double.infinity,
//         height: 55,
//         decoration: BoxDecoration(
//           gradient: gradient,
//           borderRadius: BorderRadius.circular(14),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.orange.withOpacity(0.3),
//               blurRadius: 10,
//               offset: const Offset(0, 5),
//             ),
//           ],
//         ),
//         child: Center(
//           child: Text(
//             text,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 16,
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }