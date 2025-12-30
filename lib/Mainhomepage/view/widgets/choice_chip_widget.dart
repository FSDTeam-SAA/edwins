import 'package:flutter/material.dart';
import '../../../../models/learning_models.dart';

class ChoiceChipWidget extends StatelessWidget {
  final Choice choice;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isLarge;

  const ChoiceChipWidget({
    super.key,
    required this.choice,
    required this.isSelected,
    required this.onTap,
    required this.isLarge,

  });

  @override
  Widget build(BuildContext context) {
    Color mainColor = _getColorForText(choice.text);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isLarge ? 143 : 75,
        height: isLarge ? 64 : 44,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? mainColor : mainColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: mainColor, width: 2),
        ),
        alignment: Alignment.center,
        child: Center(
          child: Text(
            choice.text,
            style: TextStyle(
              color: isSelected ? Colors.white : mainColor,
              fontSize: isLarge ? 20 : 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
  Color _getColorForText(String text) {
    // Replicates your custom color logic
    if (text == "Car" || text == "Katze") return const Color(0xFFFF6291);
    if (text == "Cap" || text == "Frisst") return const Color(0xFFFF8000);
    if (text == "Cat" || text == "Hähnchen") return const Color(0xFFFF3333);
    return const Color(0xFFFF33FC); // Default for "Can" / "Die"
  }
}