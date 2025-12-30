import 'package:flutter/material.dart';
import 'package:language_app/utils/app_style.dart';

class SuggestedVocabChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const SuggestedVocabChip({
    super.key,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.suggestedWordBorder,
            width: 1.5,
          ),
        ),
        child: Text(
          text,
          style: AppTypography.suggestedWord,
        ),
      ),
    );
  }
}