import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AvatarProvider extends ChangeNotifier {
  static const String _selectedAvatarKey = 'selected_avatar';
  String _selectedAvatarName = "Clara"; // Default avatar
  bool _isInitialized = false;

  String get selectedAvatarName => _selectedAvatarName;
  bool get isInitialized => _isInitialized;

  AvatarProvider() {
    _loadSelectedAvatar();
  }

  // Load the saved avatar from SharedPreferences
  Future<void> _loadSelectedAvatar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedAvatarName = prefs.getString(_selectedAvatarKey) ?? "Clara";
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading avatar: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Set and save the selected avatar
  Future<void> setSelectedAvatar(String avatarName) async {
    if (_selectedAvatarName == avatarName) return;
    
    _selectedAvatarName = avatarName;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedAvatarKey, avatarName);
    } catch (e) {
      debugPrint('Error saving avatar: $e');
    }
  }

  // Reset to default avatar
  Future<void> resetAvatar() async {
    await setSelectedAvatar("Clara");
  }
}