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
  final Function(String word, String contextWord)? onHighlightTap;

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

    List<InlineSpan> spans = [];

    // 2. Parse text using Regex for **word**
    rawText.splitMapJoin(
      RegExp(r'\*\*(.*?)\*\*'), // Matches **text**
      onMatch: (Match match) {
        final String word = match.group(1) ?? "";

        // Extract context word from the part before the match
        final String textBefore = rawText.substring(0, match.start);
        final String contextWord = _extractContextWord(textBefore);

        final TextStyle underlineStyle = TextStyle(
          fontSize: 16,
          color: Colors.orange[500],
          decoration: TextDecoration.underline,
        );
        spans.add(
          TextSpan(
            text: word,
            style: underlineStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                // Trigger the callback if it exists
                if (widget.onHighlightTap != null) {
                  widget.onHighlightTap!(word, contextWord);
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

  String _extractContextWord(String text) {
    if (text.isEmpty) return "";

    // Common words to ignore as "context" (prepositions, articles, etc.)
    const stopWords = {
      'to',
      'the',
      'a',
      'an',
      'in',
      'on',
      'at',
      'by',
      'for',
      'with',
      'about',
      'of',
      'into',
      'and',
      'or',
      'but',
      'is',
      'am',
      'are',
      'was',
      'were',
      'be',
      'been',
      'being',
      'from',
      'as'
    };

    // Remove markdown bold markers if any trailing
    String cleaned =
        text.replaceAll(RegExp(r'\*\?'), ' ').trim(); // Replace bold markers
    if (cleaned.isEmpty) return "";

    // Split by non-word characters and get list of words
    // Includes German characters
    final parts = cleaned.split(RegExp(r'[^a-zA-Z0-9\u00C0-\u017F]+'));
    final filteredParts =
        parts.where((p) => p.isNotEmpty).toList().reversed.toList();

    if (filteredParts.isEmpty) return "";

    // Find the first word that is not a stop word
    String? foundWord;
    for (final word in filteredParts) {
      if (!stopWords.contains(word.toLowerCase())) {
        foundWord = word;
        break;
      }
    }

    // Default to the last word if everything else is a stop word
    foundWord ??= filteredParts.first;

    // Capitalize first letter for better display (e.g. "excited" -> "Excited")
    if (foundWord.length > 1) {
      return foundWord[0].toUpperCase() + foundWord.substring(1).toLowerCase();
    }
    return foundWord.toUpperCase();
  }
}
