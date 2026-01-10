import 'package:flutter/material.dart';
import 'package:language_app/features/avatar/avatar_controller.dart';
import 'package:language_app/features/avatar/avatar_view.dart';
import 'package:language_app/app/constants/app_constants.dart';

/// Reusable avatar card widget with controls
/// Used in conversation and vocabulary screens
class AvatarCard extends StatelessWidget {
  final String avatarName;
  final AvatarController controller;
  final Color themeColor;
  final bool isMaximized;
  final bool isMuted;
  final bool isSpeaking;
  final bool isKeyboardOpen;
  final VoidCallback onToggleSize;
  final VoidCallback onToggleMute;
  final VoidCallback onRepeat;

  const AvatarCard({
    super.key,
    required this.avatarName,
    required this.controller,
    required this.themeColor,
    required this.isMaximized,
    required this.isMuted,
    required this.isSpeaking,
    this.isKeyboardOpen = false,
    required this.onToggleSize,
    required this.onToggleMute,
    required this.onRepeat,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      height: isKeyboardOpen ? 140 : (isMaximized ? 500 : 340),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [themeColor, themeColor.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Avatar View
            AvatarView(
              avatarName: avatarName,
              controller: controller,
              height: isKeyboardOpen ? 180 : (isMaximized ? 540 : 380),
              backgroundImagePath: AppConstants.backgroundImage,
              borderRadius: 24,
            ),

            // Controls (only show when keyboard is closed)
            if (!isKeyboardOpen)
              Positioned(
                bottom: 20,
                child: _buildControls(),
              ),

            // Speaking indicator (only show when maximized and speaking)
            if (isMaximized && isSpeaking && !isKeyboardOpen)
              Positioned(
                top: 10,
                left: 10,
                child: _buildSpeakingIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(
            avatarName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              _buildCircleAction(
                icon: Icons.repeat,
                onTap: onRepeat,
              ),
              const SizedBox(width: 8),
              _buildCircleAction(
                icon: isMuted ? Icons.volume_off : Icons.volume_up,
                onTap: onToggleMute,
              ),
              const SizedBox(width: 8),
              _buildCircleAction(
                icon: isMaximized ? Icons.fullscreen_exit : Icons.fullscreen,
                onTap: onToggleSize,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpeakingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.volume_up,
            color: Colors.white,
            size: 16,
          ),
          SizedBox(width: 4),
          Text(
            'Speaking...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleAction({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: Colors.white24,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}
