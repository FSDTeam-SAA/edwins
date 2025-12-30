import 'package:flutter/material.dart';
import 'package:language_app/utils/app_style.dart';

class AvatarModel {
  final String id;
  final String name;
  final String modelPath;
  final String iosModelPath; // For .usdz files
  final String description;
  final Color accentColor;

  const AvatarModel({
    required this.id,
    required this.name,
    required this.modelPath,
    required this.iosModelPath,
    required this.description,
    required this.accentColor,
  });

  static const clara = AvatarModel(
    id: 'clara',
    name: 'Clara',
    modelPath: 'assets/avatar/ClaraIdle.dae',
    iosModelPath: 'assets/avatar/ClaraAvatar.usdz',
    description: 'Friendly and energetic companion',
    // accentColor: Color(0xFFFF6B9D), // Pink
    accentColor: AppColors.primaryOrange,
  );

  static const karl = AvatarModel(
    id: 'karl',
    name: 'Karl',
    modelPath: 'assets/avatar/KarlIdle.dae',
    iosModelPath: 'assets/avatar/KarlAvatar.usdz',
    description: 'Calm and thoughtful companion',
    // accentColor: Color(0xFF4A90E2), // Blue
    accentColor: AppColors.primaryPink,
  );

  static List<AvatarModel> get all => [clara, karl];
}