import 'package:flutter/material.dart';
import 'package:language_app/features/learning/result/lesson_end_result.dart';
import 'package:language_app/features/conversation/widgets/recording_overlay.dart';
import 'package:language_app/features/conversation/widgets/suggested_vocab_chip.dart';
import 'package:language_app/features/conversation/widgets/conversation_header.dart';
import 'package:language_app/features/conversation/widgets/conversation_input_area.dart';
import 'package:language_app/app/theme/app_style.dart';
import 'package:language_app/core/utils/mock_data.dart';
import 'widgets/chat_message.dart';
import 'widgets/difficulty_rating_popup.dart';

// Avatar logic imports
import 'package:language_app/features/avatar/avatar_controller.dart';
import 'package:language_app/features/avatar/avatar_view.dart';
import 'package:language_app/app/constants/app_constants.dart';

class ConversationChat extends StatefulWidget {
  final String selectedAvatarName;

  const ConversationChat({
    super.key,
    required this.selectedAvatarName,
  });

  @override
  State<ConversationChat> createState() => _ConversationChatState();
}

class _ConversationChatState extends State<ConversationChat> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  late AvatarController _avatarController;

  List<Map<String, dynamic>> messages = [];
  List<Map<String, dynamic>> suggestedVocab = [];
  bool isRecording = false;
  bool isKeyboardVisible = false;
  bool hasTextInput = false;
  bool isMuted = false;
  int messageCount = 0;
  final int maxMessages = 5;

  @override
  void _cancelRecording() {
    setState(() {
      isRecording = false;
    });
    debugPrint("Recording Cancelled");
    // We do NOT call _sendMessage here, effectively aborting the voice note.
  }

  @override
  void initState() {
    super.initState();
    _avatarController = AvatarController();
    _loadConversation();

    _focusNode.addListener(() {
      setState(() {
        isKeyboardVisible = _focusNode.hasFocus;
      });
    });

    _textController.addListener(() {
      setState(() {
        hasTextInput = _textController.text.trim().isNotEmpty;
      });
    });
  }

  void _loadConversation() {
    final messageData = MockData.conversationMessages;

    setState(() {
      suggestedVocab = List<Map<String, dynamic>>.from(
          MockData.conversationThread['suggested_vocab']);
      messages = List<Map<String, dynamic>>.from(messageData['messages']);
    });
  }

  Color _getThemeColor() {
    return AppColors.getAvatarTheme(widget.selectedAvatarName);
  }

  void _sendMessage(String text, {bool isVoice = false}) {
    if (text.trim().isEmpty && !isVoice) return;

    setState(() {
      messages.add({
        "id": "m_user_${DateTime.now().millisecondsSinceEpoch}",
        "role": "user",
        "text": text,
        "is_voice": isVoice,
        "audio": isVoice ? "assets/audio/user_voice.mp3" : null,
        "created_at": DateTime.now().toIso8601String(),
      });
      messageCount++;
    });

    _textController.clear();
    _scrollToBottom();
    _getAvatarResponse();
  }

  // UPDATED: Now accepts the word and an optional callback
  void _showDifficultyRating(
      {required String word, Function(String)? onRatingDone}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DifficultyRatingPopup(
        word: word, // Pass dynamic word
        onRatingSelected: (difficulty) {
          Navigator.of(context).pop();
          if (onRatingDone != null) {
            // Use specific callback (e.g., for sending messages)
            onRatingDone(difficulty);
          } else {
            // Default behavior for vocab chips (e.g., just log it)
            debugPrint("User rated word '$word' as $difficulty");
          }
        },
      ),
    );
  }

  void _getAvatarResponse() {
    // Simulate "thinking" delay for realism
    Future.delayed(const Duration(milliseconds: 1000), () {
      int currentAvatarCount =
          messages.where((m) => m['role'] == 'avatar').length;
      final response = MockData.getNextConversationStep(currentAvatarCount);
      if (response != null) {
        setState(() {
          messages.add(response);
        });
        _scrollToBottom();
      } else {
        // Conversation Script Finished
        debugPrint("Conversation finished. User can check results.");
        setState(() {});
      }
    });
  }

  void _navigateToResults() {
    final Map<String, int> newScores = {
      "Speaking": 85,
      "Listening": 70,
      "Grammar": 92,
      "Vocabulary": 75,
      "Writing": 60
    };

    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LessonEndResultView(skills: newScores),
        ));
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startRecording() => setState(() => isRecording = true);

  void _stopRecording() {
    setState(() => isRecording = false);
    Future.delayed(const Duration(milliseconds: 300), () {
      _sendMessage("", isVoice: true);
    });
  }

  void _insertSuggestedWord(String word) {
    final currentText = _textController.text;
    _textController.text = currentText.isEmpty ? word : '$currentText $word';
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: _textController.text.length),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _avatarController.disposeView();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _getThemeColor();
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: AppColors.conversationBg,
      extendBodyBehindAppBar: true,
      appBar: ConversationHeader(
        messageCount: messageCount,
        maxMessages: maxMessages,
        onNavigateToResults: _navigateToResults,
        themeColor: themeColor,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.fastOutSlowIn,
                height: isKeyboardOpen ? 140 : 340,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [themeColor, themeColor.withOpacity(0.7)],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      AvatarView(
                        avatarName: widget.selectedAvatarName,
                        controller: _avatarController,
                        height: isKeyboardOpen ? 180 : 380,
                        backgroundImagePath: AppConstants.backgroundImage,
                        borderRadius: 0,
                      ),
                      if (!isKeyboardOpen)
                        Positioned(
                          bottom: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  widget.selectedAvatarName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  isMuted ? Icons.volume_off : Icons.volume_up,
                                  color: Colors.white.withOpacity(0.7),
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (!isKeyboardOpen)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 1. New Helper Text
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 16, bottom: 8, right: 16),
                        child: Text(
                          textAlign: TextAlign.center,
                          "Try to use these words in your responses",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // 2. Existing Horizontal Scroll List
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(left: 16, right: 16),
                        child: Row(
                          children: suggestedVocab.map((vocab) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: SuggestedVocabChip(
                                text: vocab['text'],
                                onTap: () =>
                                    _showDifficultyRating(word: vocab['text']),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final bool isVoiceMessage = message['role'] == 'avatar' ||
                        (message['is_voice'] ?? false);

                    return ChatMessage(
                      text: message['text'],
                      isUser: message['role'] == 'user',
                      audioUrl: message['audio'],
                      showPlayButton: isVoiceMessage,
                      translation: message['translation']?['de'],

                      // --- ADD THIS CALLBACK HERE ---
                      onHighlightTap: (word) {
                        // When a bold word is tapped, show the rating popup
                        _showDifficultyRating(word: word);
                      },
                    );
                  },
                ),
              ),
              ConversationInputArea(
                textController: _textController,
                focusNode: _focusNode,
                hasTextInput: hasTextInput,
                themeColor: themeColor,
                onStartRecording: _startRecording,
                onSendMessage: (text) => _sendMessage(text, isVoice: false),
              ),
            ],
          ),
          if (isRecording)
            RecordingOverlay(
              onRecordingComplete: _stopRecording,
              onRecordingCancelled: _cancelRecording, // <--- Add this
            ),
        ],
      ),
    );
  }
}
