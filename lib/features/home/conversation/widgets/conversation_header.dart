import 'package:flutter/material.dart';
import 'package:language_app/core/providers/theme_provider.dart';
import 'package:language_app/features/home/home_view.dart';
import 'package:provider/provider.dart';

class ConversationHeader extends StatelessWidget
    implements PreferredSizeWidget {
  final int messageCount;
  final int maxMessages;
  final VoidCallback onNavigateToResults;

  const ConversationHeader({
    super.key,
    required this.messageCount,
    required this.maxMessages,
    required this.onNavigateToResults,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final themeColor = themeProvider.primaryColor;
    final bool showFinishButton = messageCount >= maxMessages;

    return AppBar(
      backgroundColor: themeProvider.appBarColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: themeColor),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const HomeView(initialHasStartedLearning: true),
          ),
        ),
      ),
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: themeColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, color: themeColor, size: 14),
            const SizedBox(width: 6),
            Text(
              '$messageCount/$maxMessages messages',
              style: TextStyle(
                color: themeColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      centerTitle: true,
      actions: [
        if (showFinishButton)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: onNavigateToResults,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events, color: themeColor, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Result',
                      style: TextStyle(
                        color: themeColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
