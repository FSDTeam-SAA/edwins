import 'package:flutter/material.dart';
import 'package:language_app/app/theme/app_style.dart';

class VoiceInputButton extends StatelessWidget {
  final VoidCallback onTap;

  const VoiceInputButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: AppColors.micGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.micButtonOrange.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.mic,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}