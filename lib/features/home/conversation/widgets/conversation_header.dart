import 'package:flutter/material.dart';
import 'package:language_app/features/home/home_view.dart';

class ConversationHeader extends StatelessWidget
    implements PreferredSizeWidget {
  final int messageCount;
  final int maxMessages;
  final VoidCallback onNavigateToResults;
  final Color themeColor;

  const ConversationHeader({
    super.key,
    required this.messageCount,
    required this.maxMessages,
    required this.onNavigateToResults,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool showFinishButton = messageCount >= maxMessages;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 10,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const HomeView(
                      initialHasStartedLearning: true,
                    ))),
      ),
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.chat_bubble_outline,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              '$messageCount/$maxMessages messages',
              style: const TextStyle(
                color: Colors.white,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Result',
                      style: TextStyle(
                        color: Colors.white,
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
