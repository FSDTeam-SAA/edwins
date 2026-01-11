import 'package:flutter/material.dart';
import 'package:language_app/features/home/learning/result/conversation_end_result.dart';
import 'package:language_app/features/home/widgets/recording_overlay.dart';
import 'package:language_app/features/home/widgets/suggested_vocab_chip.dart';
import 'package:language_app/features/home/widgets/conversation_header.dart';
import 'package:language_app/features/home/widgets/conversation_input_area.dart';
import '../widgets/chat_message.dart';
import '../widgets/difficulty_rating_popup.dart';
import 'package:language_app/core/providers/theme_provider.dart';
import 'package:language_app/core/providers/conversation_provider.dart';
import 'package:language_app/core/providers/audio_provider.dart';
import 'package:provider/provider.dart';

// Avatar logic imports
import 'package:language_app/features/avatar/avatar_controller.dart';
import 'package:language_app/core/widgets/avatar_card.dart';

/// Refactored ConversationChat using providers
class ConversationChatRefactored extends StatefulWidget {
  final String selectedAvatarName;

  const ConversationChatRefactored(
      {super.key, required this.selectedAvatarName});

  @override
  State<ConversationChatRefactored> createState() =>
      _ConversationChatRefactoredState();
}

class _ConversationChatRefactoredState
    extends State<ConversationChatRefactored> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  late AvatarController _avatarController;

  bool isKeyboardVisible = false;
  bool hasTextInput = false;
  bool isAvatarMaximized = true;

  @override
  void initState() {
    super.initState();
    _avatarController = AvatarController();

    // Load conversation data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConversationProvider>().loadConversation();
      context
          .read<AudioProvider>()
          .setVoiceForAvatar(widget.selectedAvatarName);
    });

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

  void _sendMessage(String text, {bool isVoice = false}) {
    final conversationProvider = context.read<ConversationProvider>();
    conversationProvider.sendMessage(text, isVoice: isVoice);
    _textController.clear();
    _scrollToBottom();
  }

  void _showDifficultyRating({
    required String word,
    String? contextWord,
    Function(String)? onRatingDone,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DifficultyRatingPopup(
        word: word,
        contextWord: contextWord,
        onRatingSelected: (difficulty) {
          Navigator.of(context).pop();
          if (onRatingDone != null) {
            onRatingDone(difficulty);
          } else {
            debugPrint("User rated word '$word' as $difficulty");
          }
        },
      ),
    );
  }

  void _toggleAvatarSize() {
    setState(() => isAvatarMaximized = !isAvatarMaximized);
  }

  Future<void> _repeatDemoAudio() async {
    final audioProvider = context.read<AudioProvider>();
    if (audioProvider.isMuted) return;

    try {
      final visemes = await _avatarController.loadVisemesFromAsset(
        'test/data/viseme.txt',
      );
      await _avatarController.playAudioViseme(
        'test/test_assets/russian_sample.wav',
        visemes,
      );
    } catch (e) {
      debugPrint("Error playing demo audio: $e");
    }
  }

  void _navigateToResults() {
    final Map<String, int> newScores = {
      "Speaking": 85,
      "Listening": 70,
      "Grammar": 92,
      "Vocabulary": 75,
      "Writing": 60,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConversationEndResultView(skills: newScores),
      ),
    );
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
    final themeProvider = context.watch<ThemeProvider>();
    final conversationProvider = context.watch<ConversationProvider>();
    final audioProvider = context.watch<AudioProvider>();

    final themeColor = themeProvider.getAvatarTheme(widget.selectedAvatarName);
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: themeProvider.scaffoldBackgroundColor,
      extendBodyBehindAppBar: false,
      appBar: ConversationHeader(
        messageCount: conversationProvider.messageCount,
        maxMessages: conversationProvider.maxMessages,
        onNavigateToResults: _navigateToResults,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Avatar Card - using reusable component
              AvatarCard(
                avatarName: widget.selectedAvatarName,
                controller: _avatarController,
                themeColor: themeColor,
                isMaximized: isAvatarMaximized,
                isMuted: audioProvider.isMuted,
                isSpeaking: audioProvider.isSpeaking,
                isKeyboardOpen: isKeyboardOpen,
                onToggleSize: _toggleAvatarSize,
                onToggleMute: () => audioProvider.toggleMute(),
                onRepeat: _repeatDemoAudio,
              ),

              // Suggested Vocabulary
              if (!isKeyboardOpen)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          bottom: 8,
                          right: 16,
                        ),
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
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(left: 16, right: 16),
                        child: Row(
                          children:
                              conversationProvider.suggestedVocab.map((vocab) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: SuggestedVocabChip(
                                text: vocab['text'],
                                onTap: () =>
                                    _insertSuggestedWord(vocab['text']),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

              // Messages List
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                  itemCount: conversationProvider.messages.length,
                  itemBuilder: (context, index) {
                    final message = conversationProvider.messages[index];
                    final bool isVoiceMessage = message['role'] == 'avatar' ||
                        (message['is_voice'] ?? false);

                    return ChatMessage(
                      text: message['text'],
                      isUser: message['role'] == 'user',
                      audioUrl: message['audio'],
                      showPlayButton: isVoiceMessage,
                      translation: message['translation']?['de'],
                      onHighlightTap: (word, contextWord) {
                        _showDifficultyRating(
                          word: word,
                          contextWord: contextWord,
                        );
                      },
                    );
                  },
                ),
              ),

              // Input Area
              ConversationInputArea(
                textController: _textController,
                focusNode: _focusNode,
                hasTextInput: hasTextInput,
                themeColor: themeColor,
                onStartRecording: () => conversationProvider.startRecording(),
                onSendMessage: (text) => _sendMessage(text, isVoice: false),
              ),
            ],
          ),

          // Recording Overlay
          if (conversationProvider.isRecording)
            RecordingOverlay(
              onRecordingComplete: () => conversationProvider.stopRecording(),
              onRecordingCancelled: () =>
                  conversationProvider.cancelRecording(),
            ),
        ],
      ),
    );
  }
}
