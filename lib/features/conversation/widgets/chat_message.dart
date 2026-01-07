import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; // Required for TapGestureRecognizer
// import 'package:flutter_markdown/flutter_markdown.dart'; // No longer needed
import 'package:language_app/app/theme/app_style.dart';

class ChatMessage extends StatefulWidget {
  final String text;
  final bool isUser;
  final String? audioUrl;
  final bool showPlayButton;
  final String? translation;
  // NEW: Callback for tapping highlighted words
  final Function(String word)? onHighlightTap;

  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
    this.audioUrl,
    this.showPlayButton = false,
    this.translation,
    this.onHighlightTap,
  });

  @override
  State<ChatMessage> createState() => _ChatMessageState();
}

class _ChatMessageState extends State<ChatMessage>
    with SingleTickerProviderStateMixin {
  bool isPlaying = false;
  bool showTranslation = false;
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
    final bool shouldShowWaveform =
        widget.showPlayButton && widget.audioUrl != null;

    // Determine which text to show
    final String currentText = (showTranslation && widget.translation != null)
        ? widget.translation!
        : widget.text;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            widget.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // --- AUDIO WAVEFORM PLAYER ---
          if (shouldShowWaveform)
            GestureDetector(
              onTap: _togglePlay,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                    Icon(isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Flexible(
                      child: SizedBox(
                        height: 24,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(18, (index) {
                            final heights = [
                              12.0,
                              18.0,
                              14.0,
                              20.0,
                              16.0,
                              22.0,
                              18.0,
                              24.0,
                              20.0,
                              24.0,
                              18.0,
                              22.0,
                              16.0,
                              20.0,
                              14.0,
                              18.0,
                              12.0,
                              16.0
                            ];
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 2.5,
                              height: isPlaying ? heights[index] : 12.0,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 1.5),
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
                    const Text('1:34',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),

          // --- MESSAGE BUBBLE ---
          if (currentText.isNotEmpty) ...[
            //Add a Small spacer if we have both audio and text
            if (shouldShowWaveform) const SizedBox(height: 8),

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
                  bottomLeft:
                      widget.isUser ? const Radius.circular(20) : Radius.zero,
                  bottomRight:
                      widget.isUser ? Radius.zero : const Radius.circular(20),
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
              // REPLACED MarkdownBody WITH _buildRichText
              child: _buildRichText(context, currentText),
            ),
          ],

          // --- TRANSLATION & AUDIO TOOLS (Avatar Only) ---
          if (!widget.isUser)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (widget.translation != null) {
                        setState(() {
                          showTranslation = !showTranslation;
                        });
                      }
                    },
                    child: Icon(
                      Icons.language,
                      color: showTranslation
                          ? Colors.orange
                          : AppColors.suggestedWordBorder,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _togglePlay,
                    child: Icon(
                      Icons.volume_up,
                      color: isPlaying
                          ? Colors.orange
                          : AppColors.suggestedWordBorder,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // --- NEW HELPER METHOD TO PARSE **BOLD** TEXT ---
  Widget _buildRichText(BuildContext context, String rawText) {
    // 1. Define Styles
    final baseStyle = widget.isUser
        ? AppTypography.chatBubbleUser
        : AppTypography.chatBubbleAvatar;

    final highlightStyle = baseStyle.copyWith(
      fontWeight: FontWeight.bold,
      // Add background color similar to your Markdown config
      backgroundColor: widget.isUser
          ? Colors.white.withOpacity(0.2)
          : Colors.orange.withOpacity(0.15),
      // Optional: Add underline or color to indicate clickability
      decoration: TextDecoration.underline,
      decorationColor: widget.isUser ? Colors.white70 : Colors.orange,
    );

    List<InlineSpan> spans = [];

    // 2. Parse text using Regex for **word**
    rawText.splitMapJoin(
      RegExp(r'\*\*(.*?)\*\*'), // Matches **text**
      onMatch: (Match match) {
        final String word = match.group(1) ?? "";
        final TextStyle underlineStyle = TextStyle(
          fontSize: 16,
          color: Colors.orange[500],
          decoration: TextDecoration.underline, // This creates the line
        );
        spans.add(
          TextSpan(
            text: word,
            style: underlineStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                // Trigger the callback if it exists
                if (widget.onHighlightTap != null) {
                  widget.onHighlightTap!(word);
                }
              },
          ),
        );
        return "";
      },
      onNonMatch: (String text) {
        spans.add(TextSpan(text: text, style: baseStyle));
        return "";
      },
    );

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}
