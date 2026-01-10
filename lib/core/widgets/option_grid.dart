import 'package:flutter/material.dart';

/// Reusable option button for vocabulary quizzes
class OptionButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final bool showError;
  final Color textColor;
  final Color bgColor;
  final Color borderColor;
  final VoidCallback onTap;
  final double height;

  const OptionButton({
    super.key,
    required this.text,
    required this.isSelected,
    this.showError = false,
    this.textColor = const Color(0xFFFF8000),
    this.bgColor = const Color(0xFFFFF6ED),
    this.borderColor = const Color(0xFFFF8000),
    required this.onTap,
    this.height = 80,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: height,
        decoration: BoxDecoration(
          color: isSelected ? borderColor.withValues(alpha: 0.2) : bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected ? borderColor : borderColor.withValues(alpha: 0.3),
            width: isSelected ? 3 : 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: borderColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? borderColor : textColor,
              fontSize: 18,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// Grid layout for multiple choice options
class OptionGrid extends StatelessWidget {
  final List<Map<String, dynamic>> options;
  final String? selectedOption;
  final bool showError;
  final Function(String) onOptionTap;

  const OptionGrid({
    super.key,
    required this.options,
    this.selectedOption,
    this.showError = false,
    required this.onOptionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: OptionButton(
                  text: options[0]['text'],
                  isSelected: selectedOption == options[0]['text'],
                  showError: showError,
                  textColor: options[0]['textColor'],
                  bgColor: options[0]['bgColor'],
                  borderColor: options[0]['borderColor'],
                  onTap: () => onOptionTap(options[0]['text']),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OptionButton(
                  text: options[1]['text'],
                  isSelected: selectedOption == options[1]['text'],
                  showError: showError,
                  textColor: options[1]['textColor'],
                  bgColor: options[1]['bgColor'],
                  borderColor: options[1]['borderColor'],
                  onTap: () => onOptionTap(options[1]['text']),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OptionButton(
                  text: options[2]['text'],
                  isSelected: selectedOption == options[2]['text'],
                  showError: showError,
                  textColor: options[2]['textColor'],
                  bgColor: options[2]['bgColor'],
                  borderColor: options[2]['borderColor'],
                  onTap: () => onOptionTap(options[2]['text']),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OptionButton(
                  text: options[3]['text'],
                  isSelected: selectedOption == options[3]['text'],
                  showError: showError,
                  textColor: options[3]['textColor'],
                  bgColor: options[3]['bgColor'],
                  borderColor: options[3]['borderColor'],
                  onTap: () => onOptionTap(options[3]['text']),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
