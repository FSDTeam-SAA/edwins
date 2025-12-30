import 'package:flutter/material.dart';
import '../../../../utils/app_style.dart';

class ChatMessage extends StatefulWidget {
  final String text;
  final bool isUser;
  final String? audioUrl;
  final bool showPlayButton;

  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
    this.audioUrl,
    this.showPlayButton = false,
  });

  @override
  State<ChatMessage> createState() => _ChatMessageState();
}

class _ChatMessageState extends State<ChatMessage>
    with SingleTickerProviderStateMixin {
  bool isPlaying = false;
  late AnimationController _playController;

  @override
  void initState() {
    super.initState();
    _playController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _playController.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      isPlaying = !isPlaying;
    });

    if (isPlaying) {
      _playController.forward();
      // Simulate audio playing for 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            isPlaying = false;
          });
          _playController.reverse();
        }
      });
    } else {
      _playController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            widget.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Audio Player (for messages with audio)
          if (widget.showPlayButton && widget.audioUrl != null)
            GestureDetector(
              onTap: _togglePlay,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryOrange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    // Animated Waveform
                    Flexible(
                      child: SizedBox(
                        height: 24,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(18, (index) {
                            final heights = [
                              12.0, 18.0, 14.0, 20.0, 16.0, 22.0, 
                              18.0, 24.0, 20.0, 24.0, 18.0, 22.0,
                              16.0, 20.0, 14.0, 18.0, 12.0, 16.0
                            ];
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 2.5,
                              height: isPlaying ? heights[index] : 12.0,
                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      '1:34',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Message Bubble
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: widget.isUser ? AppColors.primaryGradient : null,
              color: widget.isUser ? null : AppColors.avatarBubbleBg,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: widget.isUser ? const Radius.circular(20) : Radius.zero,
                bottomRight: widget.isUser ? Radius.zero : const Radius.circular(20),
              ),
              boxShadow: [
                if (widget.isUser)
                  BoxShadow(
                    color: AppColors.primaryOrange.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Text(
              widget.text,
              style: widget.isUser
                  ? AppTypography.chatBubbleUser
                  : AppTypography.chatBubbleAvatar,
            ),
          ),

          // Translation and audio icons (for avatar messages)
          if (!widget.isUser)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.language,
                    color: AppColors.suggestedWordBorder,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.volume_up,
                    color: AppColors.suggestedWordBorder,
                    size: 20,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}