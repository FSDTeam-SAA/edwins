import 'package:flutter/material.dart';
import 'package:language_app/Mainhomepage/view/Result/Congratulation_screen.dart';
import 'package:language_app/Mainhomepage/view/conversation/widgets/recording_overlay.dart';
import 'package:language_app/Mainhomepage/view/conversation/widgets/suggested_vocab_chip.dart';
import '../../../utils/app_style.dart';
import '../../../utils/mock_data.dart';
import 'widgets/chat_message.dart';
import 'widgets/voice_input_button.dart';
import 'widgets/difficulty_rating_popup.dart';

// Avatar logic imports
import 'package:language_app/avatar/avatar_controller.dart';
import 'package:language_app/avatar/avatar_view.dart';

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
    // final thread = MockData.conversationThread;
    final messageData = MockData.conversationMessages;

    setState(() {
      suggestedVocab =
          List<Map<String, dynamic>>.from(MockData.conversationThread['suggested_vocab']);
      messages = List<Map<String, dynamic>>.from(messageData['messages']);
    });
  }

  Color _getThemeColor() {
    if (widget.selectedAvatarName == "Clara") {
      return const Color(0xFF4CAF50).withOpacity(0.5); // Clara's green
    }
    return const Color(0xFF2E7D32).withOpacity(0.5); // Karl's blue
  }

  void _sendMessage(String text, {bool isVoice = false}) {
    if (text.trim().isEmpty) return;

    setState(() {
      messages.add({
        "id": "m_user_${DateTime.now().millisecondsSinceEpoch}",
        "role": "user",
        "text": text,
        "is_voice": isVoice, // Ensure flag is stored
        "audio": isVoice ? "assets/audio/user_voice.mp3" : null,
        "created_at": DateTime.now().toIso8601String(),
      });
      messageCount++;
    });

    _textController.clear();
    _scrollToBottom();

    // Show difficulty rating popup
    Future.delayed(const Duration(milliseconds: 500), () {
      _showDifficultyRating(text);
    });
  }

  void _showDifficultyRating(String userMessage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DifficultyRatingPopup(
        word: 'Excellent',
        onRatingSelected: (difficulty) {
          Navigator.of(context).pop();
          _handleDifficultySelected(difficulty, userMessage);
        },
      ),
    );
  }

  void _handleDifficultySelected(String difficulty, String userMessage) {
    Future.delayed(const Duration(milliseconds: 500), () {
      final response = MockData.mockMessageResponse(userMessage);
      setState(() {
        messages.add(response);
      });
      _scrollToBottom();
    });
  }

  void _navigateToResults() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LessonCompletionView(),
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

  void _startRecording() => setState(() => isRecording = true);

  void _stopRecording() {
    setState(() => isRecording = false);
    Future.delayed(const Duration(milliseconds: 300), () {
      _sendMessage("That sounds like a great plan!", isVoice: true);
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
    final bool showFinishButton = messageCount >= maxMessages;

    return Scaffold(
      backgroundColor: AppColors.conversationBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
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
                onTap: _navigateToResults,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events, color: themeColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'See Results',
                        style: TextStyle(
                          color: themeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
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
                        backgroundImagePath: "assets/images/background.png",
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
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
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
                ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    // Logic: Show waveform only if Avatar message OR User Voice response
                    final bool isVoiceMessage = message['role'] == 'avatar' || (message['is_voice'] ?? false);
                    
                    return ChatMessage(
                      text: message['text'],
                      isUser: message['role'] == 'user',
                      audioUrl: message['audio'],
                      showPlayButton: isVoiceMessage, // Wave only for voice
                      translation: message['translation']?['de'], // Pass German text
                    );
                  },
                ),
              ),
              Container(
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
                              color: _focusNode.hasFocus
                                  ? themeColor
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: TextField(
                            controller: _textController,
                            focusNode: _focusNode,
                            style: const TextStyle(fontSize: 16),
                            decoration: const InputDecoration(
                              hintText: 'Talk to your companion...',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
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
                                onPressed: () =>
                                    _sendMessage(_textController.text, isVoice: false), // Text only
                                icon: const Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : VoiceInputButton(onTap: _startRecording),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (isRecording)
            RecordingOverlay(onRecordingComplete: _stopRecording),
        ],
      ),
    );
  }
}