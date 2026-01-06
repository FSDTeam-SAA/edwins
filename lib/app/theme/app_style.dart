import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryOrange = Color(0xFFFF7043);
  static const Color primaryPink = Color(0xFFFF5252);
  static const Color textGreen = Color(0xFF4CAF50);
  static const Color bgLight = Color(0xFFFFF9F9);
  static const Color cardBorder = Color(0xFFFFCCBC);
  static const Color primaryBlue = Color.fromRGBO(0, 157, 255, 1);
  static const Color textGrey = Color(0xFF757575);
  static const Color successGreenDark = Color(0xFF2E7D32);

  // Conversation Screen Colors
  static const Color conversationBg = Color(0xFFFFFBF5);
  static const Color avatarCardBg = Color(0xFFFFF4E6);
  static const Color suggestedWordBorder = Color(0xFFFF9D6E);
  static const Color suggestedWordText = Color(0xFFFF7A06);
  static const Color avatarBubbleBg = Color(0xFFFFF9F0);
  static const Color avatarBubbleText = Color(0xFF424242);
  static const Color micButtonOrange = Color(0xFFFF7A3D);
  static const Color micButtonPink = Color(0xFFFF5C7C);
  static const Color inputFieldBg = Colors.white;
  static const Color inputFieldBorder = Color(0xFFE0E0E0);

  // Gradient for buttons and active states
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF8A65), Color(0xFFFF5C7C)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Microphone button gradient
  static const LinearGradient micGradient = LinearGradient(
    colors: [Color(0xFFFF7A3D), Color(0xFFFF5C7C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Progress Card Background Gradient (10% Opacity)
  static const LinearGradient progressCardBgGradient = LinearGradient(
    colors: [
      Color.fromRGBO(255, 96, 157, 0.1),
      Color.fromRGBO(255, 122, 6, 0.1)
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Progress Card Border Gradient (50% Opacity)
  static const LinearGradient progressCardBorderGradient = LinearGradient(
    colors: [
      Color.fromRGBO(255, 96, 157, 0.5),
      Color.fromRGBO(255, 122, 6, 0.5)
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Chart specific colors
  static const Color chartFill = Color.fromRGBO(255, 122, 6, 0.2);
  static const Color chartBorder = Color(0xFFFF7A06);

  // Avatar Theme Colors
  static Color getAvatarTheme(String avatarName) {
    if (avatarName == "Clara") {
      return const Color(0xFF4CAF50).withOpacity(0.5); // Clara's green
    }
    return const Color(0xFF2E7D32).withOpacity(
        0.5); // Karl's blue (actually Dark Green in code, keeping existing logic)
  }
}

class AppTypography {
  static const TextStyle header = TextStyle(
      fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textGreen);

  static const TextStyle cardTitle = TextStyle(
      fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87);

  static const TextStyle cardSubtitle = TextStyle(
      fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textGrey);

  // Conversation screen typography
  static const TextStyle avatarName = TextStyle(
      fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFFFF7A06));

  static const TextStyle suggestedWord = TextStyle(
      fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFFFF7A06));

  static const TextStyle instructionText = TextStyle(
      fontSize: 16, fontWeight: FontWeight.w400, color: Color(0xFF212121));

  static const TextStyle chatBubbleUser =
      TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.white);

  static const TextStyle chatBubbleAvatar = TextStyle(
      fontSize: 16, fontWeight: FontWeight.w400, color: Color(0xFF424242));
}
// import 'package:flutter/material.dart';

// class AppColors {
//   static const Color primaryOrange = Color(0xFFFF7043);
//   static const Color primaryPink = Color(0xFFFF5252);
//   static const Color textGreen = Color(0xFF4CAF50);
//   static const Color bgLight = Color(0xFFFFF9F9);
//   static const Color cardBorder = Color(0xFFFFCCBC);
//   static const Color primaryBlue = Color.fromRGBO(0, 157, 255, 1);
//   static const Color textGrey = Color(0xFF757575); // Added for labels

//   // Gradient for buttons and active states
//   static const LinearGradient primaryGradient = LinearGradient(
//     colors: [Color(0xFFFF8A65), Color(0xFFFF5252)],
//     begin: Alignment.topCenter,
//     end: Alignment.bottomCenter,
//   );

//   // 1. Progress Card Background Gradient (10% Opacity)
//   static const LinearGradient progressCardBgGradient = LinearGradient(
//     colors: [
//       Color.fromRGBO(255, 96, 157, 0.1), 
//       Color.fromRGBO(255, 122, 6, 0.1)
//     ],
//     begin: Alignment.topCenter,
//     end: Alignment.bottomCenter,
//   );

//   // 2. Progress Card Border Gradient (50% Opacity)
//   static const LinearGradient progressCardBorderGradient = LinearGradient(
//     colors: [
//       Color.fromRGBO(255, 96, 157, 0.5), 
//       Color.fromRGBO(255, 122, 6, 0.5)
//     ],
//     begin: Alignment.topCenter,
//     end: Alignment.bottomCenter,
//   );
  
//   // 3. Chart specific colors
//   static const Color chartFill = Color.fromRGBO(255, 122, 6, 0.2); // Orange with opacity
//   static const Color chartBorder = Color(0xFFFF7A06); // Solid Orange
// }

// class AppTypography {
//   static const TextStyle header = TextStyle(
//       fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textGreen);

//   static const TextStyle cardTitle = TextStyle(
//       fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87); // Increased size slightly
      
//   static const TextStyle cardSubtitle = TextStyle(
//       fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textGrey);
// }