import 'package:flutter/foundation.dart';
import '../models/avatar_model.dart';

class AvatarProvider extends ChangeNotifier {
  AvatarModel _selectedAvatar = AvatarModel.clara;

  AvatarModel get selectedAvatar => _selectedAvatar;

  void selectAvatar(AvatarModel avatar) {
    _selectedAvatar = avatar;
    notifyListeners();
  }

  void resetToDefault() {
    _selectedAvatar = AvatarModel.clara;
    notifyListeners();
  }
}