import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:language_app/avatar/avatar_controller.dart';

// TODO Message abstract -> User and Avatar. User does not need translation etc.
class Message {
  final String text;
  final String translation;
  final List<String> highlightedWordsTranslation;
  final bool isUser;
  final List<String> highlightedWords;
  final String timeStamp;
  final String audioPath;
  final List<Map<String, dynamic>> visemes;

  Message({
    required this.text,
    required this.isUser,
    this.highlightedWords = const [],
    required this.timeStamp,
    required this.audioPath,
    required this.visemes,
    required this.translation,
    required this.highlightedWordsTranslation,
  });
}

class MessageBubble extends StatefulWidget {
  const MessageBubble(
      {super.key, required this.message, required this.avatarController});
  final Message message;
  final AvatarController avatarController;

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool showTranslation = false;

  Widget _buildRichMessageText(String msg, List<String> highlightedWords) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
          wordSpacing: 1.2,
          height: 1.4,
        ),
        children: _buildTextSpansForMessage(msg, highlightedWords),
      ),
    );
  }

  List<TextSpan> _buildTextSpansForMessage(
      String msg, List<String> highlightedWords) {
    final words = msg.split(' ');

    return words.map((word) {
      // Wort ohne Satzzeichen zum Vergleichen
      final cleanWord = word.replaceAll(RegExp(r'[^\w]'), '');

      final isHighlighted = highlightedWords.contains(cleanWord);

      if (!isHighlighted) {
        return TextSpan(text: '$word ');
      }

      return TextSpan(
        text: '$word ',
        style: const TextStyle(
          color: Colors.orange,
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            // TODO: hier machst du deine Action
            debugPrint('Tapped on $cleanWord');
          },
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final Message msg = widget.message;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        showTranslation
            ? _buildRichMessageText(
                msg.translation, msg.highlightedWordsTranslation)
            : _buildRichMessageText(msg.text, msg.highlightedWords),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              msg.timeStamp,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      showTranslation = !showTranslation;
                      setState(() {});
                    },
                    child: const Icon(
                      Icons.translate,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    await widget.avatarController.playAudioViseme(
                      msg.audioPath,
                      msg.visemes,
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.volume_up_outlined,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            )
          ],
        )
      ],
    );
  }
}
