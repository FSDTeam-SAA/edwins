import 'package:flutter/material.dart';
import 'package:language_app/Mainhomepage/home_view.dart';
import 'package:language_app/Mainhomepage/view/conversation/conversation_chat.dart';
import 'package:language_app/Mainhomepage/view/vocabulary/vocab_loop_view.dart';
import 'package:language_app/utils/app_style.dart';
import 'package:lottie/lottie.dart';

class LessonCompletionView extends StatelessWidget {
  const LessonCompletionView({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.primaryOrange.withOpacity(0.3),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryOrange.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// 🎉 Animation
                SizedBox(
                  height: 130,
                  child: Lottie.asset(
                    "assets/animations/Success.json",
                    repeat: false,
                  ),
                ),

                const SizedBox(height: 10),
                Text(
                  "Congratulations! 🎯",
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.successGreenDark,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 10),
                Text(
                  "You have completed lesson 2 successfully!",
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryOrange,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 30),

                /// Buttons
                _buildOutlineButton(
                  context,
                  "⬅ Back Home",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeView()),
                  ),
                ),

                const SizedBox(height: 15),
                _buildGradientButton(
                  context,
                  "🔁 Repeat Vocabulary",
                  gradient: AppColors.primaryGradient,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const VocabLoopView(lessonId: "lesson_1"),
                    ),
                  ),
                ),

                const SizedBox(height: 15),
                _buildGradientButton(
                  context,
                  "🗣 Conversation Lesson",
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF087F23)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ConversationChat(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🟠 Outlined Button
  Widget _buildOutlineButton(BuildContext context, String text,
      {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primaryOrange),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: AppColors.primaryOrange,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  /// 🟢 Gradient Filled Buttons
  Widget _buildGradientButton(
    BuildContext context,
    String text, {
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:language_app/Mainhomepage/home_view.dart';
// import 'package:language_app/Mainhomepage/view/conversation/conversation_chat.dart';
// import 'package:language_app/Mainhomepage/view/vocabulary/vocab_loop_view.dart';
// import '../../../../utils/app_style.dart';

// class LessonCompletionView extends StatelessWidget {
//   const LessonCompletionView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24.0),
//           child: Container(
//             padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(15),
//               border: Border.all(
//                 color: AppColors.primaryOrange.withOpacity(0.5),
//                 width: 1.5,
//               ),
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // 1. Congratulation Header
//                 const Text(
//                   "Congratulation!",
//                   style: TextStyle(
//                     fontSize: 28,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFF4CAF50), // Vibrant Green from UI
//                   ),
//                 ),
//                 const SizedBox(height: 15),
//                 const Text(
//                   "You have completed lesson 2.",
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                     color: AppColors.primaryOrange,
//                   ),
//                 ),
//                 const SizedBox(height: 40),

//                 // 2. Action Buttons
//                 _buildOutlineButton(
//                   context, 
//                   "Back Home", 
//                   onTap: () =>   Navigator.push(context,
//                     MaterialPageRoute(builder: (context) => const HomeView()),
//                   )
//                 ),
//                 const SizedBox(height: 15),
//                 _buildGradientButton(
//                   context, 
//                   "Repeat Vocabulary Lesson", 
//                   gradient: AppColors.primaryGradient,
//                   onTap: () {
//                     // Logic to repeat
//                     Navigator.push(context, MaterialPageRoute(builder: (context) => const VocabLoopView(lessonId: "lesson_1")));
//                   },
//                 ),
//                 const SizedBox(height: 15),
//                 _buildGradientButton(
//                   context, 
//                   "Conversational Lesson", 
//                   gradient: const LinearGradient(
//                     colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
//                     begin: Alignment.topCenter,
//                     end: Alignment.bottomCenter,
//                   ),
//                   onTap: () {
//                     // Logic for next lesson
//                     Navigator.push(context, MaterialPageRoute(builder: (context) => const ConversationChat()));
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // White button with Orange Border
//   Widget _buildOutlineButton(BuildContext context, String text, {required VoidCallback onTap}) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: double.infinity,
//         height: 55,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: const Color(0xFFFF8A65)), // Light orange border
//         ),
//         child: Center(
//           child: Text(
//             text,
//             style: const TextStyle(
//               color: Color(0xFFFF7043),
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // Gradient Filled Buttons
//   Widget _buildGradientButton(BuildContext context, String text, {required Gradient gradient, required VoidCallback onTap}) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: double.infinity,
//         height: 55,
//         decoration: BoxDecoration(
//           gradient: gradient,
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               blurRadius: 4,
//               offset: const Offset(0, 4),
//             )
//           ],
//         ),
//         child: Center(
//           child: Text(
//             text,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }