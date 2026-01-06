import 'package:flutter/material.dart';

import 'package:language_app/app/theme/app_style.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatBubble({
    super.key, 
    required this.text, 
    required this.isUser
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          // Gradient for User, Solid Light Color for System
          gradient: isUser ? AppColors.primaryGradient : null,
          color: isUser ? null : const Color(0xFFFFF9E5), // Light Yellow
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(20),
          ),
          boxShadow: [
            if(isUser) 
              BoxShadow(
                color: AppColors.primaryOrange.withOpacity(0.3), 
                blurRadius: 8, 
                offset: const Offset(0, 4)
              )
          ]
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}