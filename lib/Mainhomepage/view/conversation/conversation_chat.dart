import 'package:flutter/material.dart';
import 'package:language_app/Mainhomepage/view/Result/Congratulation_screen.dart';
import 'package:language_app/provider/avatar_provider.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_style.dart';
import '../../../utils/mock_data.dart';
import 'widgets/avatar_card.dart';
import 'widgets/suggested_vocab_chip.dart';
import 'widgets/chat_message.dart';
import 'widgets/voice_input_button.dart';
import 'widgets/difficulty_rating_popup.dart';
import 'widgets/recording_overlay.dart';

class ConversationChat extends StatefulWidget {
  const ConversationChat({super.key});

  @override
  State<ConversationChat> createState() => _ConversationChatState();
}

class _ConversationChatState extends State<ConversationChat> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<Map<String, dynamic>> messages = [];
  List<Map<String, dynamic>> suggestedVocab = [];
  bool isRecording = false;
  bool isKeyboardVisible = false;
  bool hasTextInput = false;
  int messageCount = 0;
  final int maxMessages = 1;

  @override
  void initState() {
    super.initState();
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
    final thread = MockData.conversationThread;
    final messageData = MockData.conversationMessages;

    setState(() {
      suggestedVocab = List<Map<String, dynamic>>.from(
        thread['suggested_vocab'],
      );
      messages = List<Map<String, dynamic>>.from(messageData['messages']);
    });
  }

  void _sendMessage(String text, {bool isVoice = false}) {
    if (text.trim().isEmpty) return;

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

    Future.delayed(const Duration(milliseconds: 500), () {
      _showDifficultyRating(text);
    });
  }

  void _showDifficultyRating(String userMessage) {
    String wordToRate = 'Aufgeregt';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DifficultyRatingPopup(
        word: wordToRate,
        onRatingSelected: (difficulty) {
          Navigator.of(context).pop();
          _handleDifficultySelected(difficulty, userMessage);
        },
      ),
    );
  }

  void _handleDifficultySelected(String difficulty, String userMessage) {
    if (messageCount >= maxMessages) {
      Future.delayed(const Duration(milliseconds: 300), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LessonCompletionView()),
        );
      });
    } else {
      Future.delayed(const Duration(milliseconds: 500), () {
        final response = MockData.mockMessageResponse(userMessage);
        setState(() {
          messages.add(response);
        });
        _scrollToBottom();
      });
    }
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

  void _startRecording() {
    setState(() {
      isRecording = true;
    });
  }

  void _stopRecording() {
    setState(() {
      isRecording = false;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      _sendMessage(
        "I love visiting Cafe Maro. It's a beautiful restaurant with delicious food and I always recommend it.",
        isVoice: true,
      );
    });
  }

  void _insertSuggestedWord(String word) {
    final currentText = _textController.text;
    final newText = currentText.isEmpty ? word : '$currentText $word';
    _textController.text = newText;
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: newText.length),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the selected avatar from Provider
    final selectedAvatar = Provider.of<AvatarProvider>(context).selectedAvatar;
    // Detect keyboard height to help with layout if needed
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: AppColors.conversationBg,
      appBar: AppBar(
        backgroundColor: AppColors.conversationBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: selectedAvatar.accentColor),
          onPressed: () => Navigator.pop(context),
        ),
        // Title appears when keyboard is open and card is small
        title: AnimatedOpacity(
          opacity: isKeyboardVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Text(
            selectedAvatar.name,
            style: AppTypography.avatarName.copyWith(
              color: selectedAvatar.accentColor,
            ),
          ),
        ),
        // title: Text(
        //   isKeyboardVisible ? selectedAvatar.name : '',
        //   style: AppTypography.avatarName.copyWith(
        //     color: selectedAvatar.accentColor,
        //   ),
        // ),
        // actions: [
        //   if (isKeyboardVisible)
        //     IconButton(
        //       icon: Icon(
        //         Icons.menu,
        //         color: selectedAvatar.accentColor,
        //       ),
        //       onPressed: () {},
        //     ),
        // ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // --- DYNAMIC AVATAR CARD ---
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: isKeyboardVisible ? 80 : 220, // Shrinks when typing
                child: AvatarCard(
                  avatar: selectedAvatar,
                  // You might want to pass a 'isMini' flag to AvatarCard
                  // to hide internal elements like the volume button when small
                  onSoundTap: isKeyboardVisible
                      ? null
                      : () {
                          debugPrint('Sound tapped');
                        },
                ),
              ),

              // --- HIDE INSTRUCTIONS WHEN KEYBOARD IS OPEN ---
              if (!isKeyboardVisible) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Text(
                    'Use these words in your response:',
                    style: AppTypography.cardTitle,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: suggestedVocab.map((vocab) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: SuggestedVocabChip(
                          text: vocab['text'],
                          onTap: () => _insertSuggestedWord(vocab['text']),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Chat Messages
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isLast = index == messages.length - 1;
                    return ChatMessage(
                      text: message['text'],
                      isUser: message['role'] == 'user',
                      audioUrl: message['audio'],
                      showPlayButton:
                          (message['role'] == 'avatar' ||
                              message['is_voice'] == true) &&
                          isLast,
                    );
                  },
                ),
              ),

              // Input Area with avatar color accent
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      // Text Input Field
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.inputFieldBg,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: _focusNode.hasFocus
                                  ? selectedAvatar.accentColor.withOpacity(0.5)
                                  : AppColors.inputFieldBorder,
                              width: _focusNode.hasFocus ? 2 : 1,
                            ),
                          ),
                          child: TextField(
                            controller: _textController,
                            focusNode: _focusNode,
                            decoration: InputDecoration(
                              hintText: 'Type your response',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (text) => _sendMessage(text),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Send Button or Voice Button
                      if (hasTextInput)
                        GestureDetector(
                          onTap: () => _sendMessage(_textController.text),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  selectedAvatar.accentColor,
                                  selectedAvatar.accentColor.withOpacity(0.8),
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: selectedAvatar.accentColor.withOpacity(
                                    0.4,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        )
                      else
                        VoiceInputButton(onTap: _startRecording),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Recording Overlay
          if (isRecording)
            RecordingOverlay(onRecordingComplete: _stopRecording),
        ],
      ),
    );
  }
}