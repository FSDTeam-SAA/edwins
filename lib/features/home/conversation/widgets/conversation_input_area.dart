import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:language_app/features/home/conversation/widgets/voice_input_button.dart';
import 'package:language_app/app/theme/app_style.dart';

class ConversationInputArea extends StatelessWidget {
  final TextEditingController textController;
  final FocusNode focusNode;
  final bool hasTextInput;
  final Color themeColor;
  final VoidCallback onStartRecording;
  final Function(String) onSendMessage;

  const ConversationInputArea({
    super.key,
    required this.textController,
    required this.focusNode,
    required this.hasTextInput,
    required this.themeColor,
    required this.onStartRecording,
    required this.onSendMessage,
  });

  void _sendMessageIfValid() {
    final text = textController.text.trim();
    if (text.isNotEmpty) {
      onSendMessage(text);
      textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.inputFieldBg,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: focusNode.hasFocus ? themeColor : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Focus(
                  focusNode: focusNode,
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.enter &&
                        !HardwareKeyboard.instance.isShiftPressed) {
                      _sendMessageIfValid();
                      return KeyEventResult.handled; // block newline
                    }
                    return KeyEventResult.ignored;
                  },
                  child: TextField(
                    controller: textController,
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                    style: const TextStyle(fontSize: 16),
                    decoration: const InputDecoration(
                      hintText: 'Talk to your companion...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            hasTextInput
                ? Container(
                    decoration: BoxDecoration(
                      color: themeColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _sendMessageIfValid,
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                      ),
                    ),
                  )
                : VoiceInputButton(onTap: onStartRecording),
          ],
        ),
      ),
    );
  }
}
