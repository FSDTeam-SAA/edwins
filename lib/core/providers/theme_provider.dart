import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  // Base App Colors
  Color _primaryColor = const Color(0xFFFF8000); // Default Orange
  final Color _backgroundColor = Colors.white;
  final Color _scaffoldBackgroundColor = Colors.white;

  // Getters
  Color get primaryColor => _primaryColor;
  Color get backgroundColor => _backgroundColor;
  Color get scaffoldBackgroundColor => _scaffoldBackgroundColor;

  // Avatar Specific Themes
  Color getAvatarTheme(String avatarName) {
    if (avatarName.toLowerCase() == "clara") {
      return const Color.fromARGB(
        255,
        69,
        130,
        71,
      ).withValues(alpha: 0.5); // Clara's green
    }
    // Default / Karl's theme
    return const Color(0xFFFF8000).withValues(alpha: 0.5);
  }

  // Header / AppBar Theme
  Color get appBarColor => Colors.white;
  Color get appBarIconColor => _primaryColor;

  // Update Methods (for future use)
  void updatePrimaryColor(Color newColor) {
    _primaryColor = newColor;
    notifyListeners();
  }
}
