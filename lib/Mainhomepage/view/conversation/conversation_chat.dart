import 'package:flutter/material.dart';
import 'package:language_app/Mainhomepage/view/Result/Congratulation_screen.dart';
import '../../../utils/app_style.dart';
import '../../../utils/mock_data.dart';
import 'widgets/suggested_vocab_chip.dart';
import 'widgets/chat_message.dart';
import 'widgets/voice_input_button.dart';
import 'widgets/difficulty_rating_popup.dart';
import 'widgets/recording_overlay.dart';

// Avatar logic imports
import 'package:language_app/avatar/avatar_controller.dart';
import 'package:language_app/avatar/avatar_view.dart';

class ConversationChat extends StatefulWidget {
  final String selectedAvatarName; // Passed from SelectAvatar screen

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

  // 3D Controller for the companion
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

    // Listen for focus changes to handle keyboard visibility
    _focusNode.addListener(() {
      setState(() {
        isKeyboardVisible = _focusNode.hasFocus;
      });
    });

    // Listen for text input to toggle between Voice and Send button
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
      suggestedVocab =
          List<Map<String, dynamic>>.from(thread['suggested_vocab']);
      messages = List<Map<String, dynamic>>.from(messageData['messages']);
    });
  }

  // Determine UI color theme based on selected character name
  Color _getThemeColor() {
    if (widget.selectedAvatarName == "Clara") {
      return const Color(0xFFFF609D); // Clara's pink/rose accent
    }
    return const Color(0xFFFF7A06); // Karl's orange accent
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
    });

    _textController.clear();
    _scrollToBottom();

    // ⬇⬇ Direct navigation to LessonCompletionView after sending the message
    Future.delayed(const Duration(milliseconds: 200), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LessonCompletionView()),
      );
    });
  }

  // void _sendMessage(String text, {bool isVoice = false}) {
  //   if (text.trim().isEmpty) return;

  //   setState(() {
  //     messages.add({
  //       "id": "m_user_${DateTime.now().millisecondsSinceEpoch}",
  //       "role": "user",
  //       "text": text,
  //       "is_voice": isVoice,
  //       "audio": isVoice ? "assets/audio/user_voice.mp3" : null,
  //       "created_at": DateTime.now().toIso8601String(),
  //     });
  //     messageCount++;
  //   });

  //   _textController.clear();
  //   _scrollToBottom();

  //   // Small delay before showing feedback popup
  //   Future.delayed(const Duration(milliseconds: 500), () {
  //     _showDifficultyRating(text);
  //   });
  // }

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

    return Scaffold(
      backgroundColor: AppColors.conversationBg,
      extendBodyBehindAppBar:
          true, // Allows avatar background to fill the screen
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: AnimatedOpacity(
          opacity: isKeyboardOpen ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Text(
            widget.selectedAvatarName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // --- RESPONSIVE 3D AVATAR HEADER ---
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.fastOutSlowIn,
                // Height shrinks from 340 to 140 when keyboard is active
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
                      // The 3D Companion View
                      AvatarView(
                        avatarName: widget.selectedAvatarName,
                        controller: _avatarController,
                        height: isKeyboardOpen ? 180 : 380,
                        backgroundImagePath: "assets/images/background.png",
                        borderRadius: 0,
                      ),

                      // Character Name Label (Hidden when keyboard is open)
                      if (!isKeyboardOpen)
                        Positioned(
                          bottom: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
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

              // --- VOCABULARY SUGGESTIONS (Hidden when typing) ---
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

              // --- CHAT MESSAGES ---
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return ChatMessage(
                      text: message['text'],
                      isUser: message['role'] == 'user',
                      audioUrl: message['audio'],
                      showPlayButton: message['role'] == 'avatar',
                    );
                  },
                ),
              ),

              // --- INPUT AREA ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, -2))
                    ]),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      // Text Field
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

                      // Conditional Button (Send or Record)
                      hasTextInput
                          ? Container(
                              decoration: BoxDecoration(
                                color: themeColor,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: () =>
                                    _sendMessage(_textController.text),
                                icon: const Icon(Icons.send_rounded,
                                    color: Colors.white),
                              ),
                            )
                          : VoiceInputButton(onTap: _startRecording),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Recording Interface Overlay
          if (isRecording)
            RecordingOverlay(onRecordingComplete: _stopRecording),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:language_app/Mainhomepage/view/Result/Congratulation_screen.dart';
// import 'package:provider/provider.dart';
// import '../../../provider/avatar_provider.dart';
// import '../../../utils/app_style.dart';
// import '../../../utils/mock_data.dart';
// import 'widgets/suggested_vocab_chip.dart';
// import 'widgets/chat_message.dart';
// import 'widgets/voice_input_button.dart';
// import 'widgets/difficulty_rating_popup.dart';
// import 'widgets/recording_overlay.dart';

// // Avatar logic imports
// import 'package:language_app/avatar/avatar_controller.dart';
// import 'package:language_app/avatar/avatar_view.dart';

// class ConversationChat extends StatefulWidget {
//   final String selectedAvatarName; // Add this field

//   const ConversationChat({
//     super.key, 
//     required this.selectedAvatarName, // Make it required
//   });

//   @override
//   State<ConversationChat> createState() => _ConversationChatState();
// }

// class _ConversationChatState extends State<ConversationChat> {
//   final TextEditingController _textController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   final FocusNode _focusNode = FocusNode();
  
//   // 3D Controller
//   late AvatarController _avatarController;

//   List<Map<String, dynamic>> messages = [];
//   List<Map<String, dynamic>> suggestedVocab = [];
//   bool isRecording = false;
//   bool isKeyboardVisible = false;
//   bool hasTextInput = false;
//   bool isMuted = false;
//   int messageCount = 0;
//   final int maxMessages = 5; // Increased for a better demo flow

//   @override
//   void initState() {
//     super.initState();
//     _avatarController = AvatarController();
//     _loadConversation();

//     _focusNode.addListener(() {
//       setState(() {
//         isKeyboardVisible = _focusNode.hasFocus;
//       });
//     });

//     _textController.addListener(() {
//       setState(() {
//         hasTextInput = _textController.text.trim().isNotEmpty;
//       });
//     });
//   }

//   void _loadConversation() {
//     final thread = MockData.conversationThread;
//     final messageData = MockData.conversationMessages;

//     setState(() {
//       suggestedVocab = List<Map<String, dynamic>>.from(thread['suggested_vocab']);
//       messages = List<Map<String, dynamic>>.from(messageData['messages']);
//     });
//   }

//   void _sendMessage(String text, {bool isVoice = false}) {
//     if (text.trim().isEmpty) return;

//     setState(() {
//       messages.add({
//         "id": "m_user_${DateTime.now().millisecondsSinceEpoch}",
//         "role": "user",
//         "text": text,
//         "is_voice": isVoice,
//         "audio": isVoice ? "assets/audio/user_voice.mp3" : null,
//         "created_at": DateTime.now().toIso8601String(),
//       });
//       messageCount++;
//     });

//     _textController.clear();
//     _scrollToBottom();

//     Future.delayed(const Duration(milliseconds: 500), () {
//       _showDifficultyRating(text);
//     });
//   }

//   void _showDifficultyRating(String userMessage) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => DifficultyRatingPopup(
//         word: 'Excellent',
//         onRatingSelected: (difficulty) {
//           Navigator.of(context).pop();
//           _handleDifficultySelected(difficulty, userMessage);
//         },
//       ),
//     );
//   }

//   void _handleDifficultySelected(String difficulty, String userMessage) {
//     if (messageCount >= maxMessages) {
//       Future.delayed(const Duration(milliseconds: 300), () {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => const LessonCompletionView()),
//         );
//       });
//     } else {
//       Future.delayed(const Duration(milliseconds: 500), () {
//         final response = MockData.mockMessageResponse(userMessage);
//         setState(() {
//           messages.add(response);
//         });
//         _scrollToBottom();
//       });
//     }
//   }

//   void _scrollToBottom() {
//     Future.delayed(const Duration(milliseconds: 100), () {
//       if (_scrollController.hasClients) {
//         _scrollController.animateTo(
//           _scrollController.position.maxScrollExtent,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }

//   void _startRecording() => setState(() => isRecording = true);

//   void _stopRecording() {
//     setState(() => isRecording = false);
//     Future.delayed(const Duration(milliseconds: 300), () {
//       _sendMessage("That sounds like a great plan!", isVoice: true);
//     });
//   }

//   void _insertSuggestedWord(String word) {
//     final currentText = _textController.text;
//     _textController.text = currentText.isEmpty ? word : '$currentText $word';
//     _textController.selection = TextSelection.fromPosition(
//       TextPosition(offset: _textController.text.length),
//     );
//   }

//   @override
//   void dispose() {
//     _textController.dispose();
//     _scrollController.dispose();
//     _focusNode.dispose();
//     _avatarController.disposeView();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Accessing selected avatar name from Provider (String based)
//     final selectedAvatar = Provider.of<AvatarProvider>(context).selectedAvatar;
//     const accentColor = AppColors.primaryOrange; // Using default theme color
//     // Use widget.selectedAvatarName to identify the companion
//     final String avatarName = widget.selectedAvatarName;
//     final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

//     return Scaffold(
//       backgroundColor: AppColors.conversationBg,
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: AnimatedOpacity(
//           opacity: isKeyboardOpen ? 1.0 : 0.0,
//           duration: const Duration(milliseconds: 200),
//           child: Text(
//             selectedAvatar.name,
//             style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//           ),
//         ),
//         centerTitle: true,
//       ),
//       body: Stack(
//         children: [
//           Column(
//             children: [
//               // --- RESPONSIVE 3D AVATAR HEADER ---
//               AnimatedContainer(
//                 duration: const Duration(milliseconds: 400),
//                 curve: Curves.fastOutSlowIn,
//                 height: isKeyboardOpen ? 140 : 340,
//                 width: double.infinity,
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.topCenter,
//                     end: Alignment.bottomCenter,
//                     colors: [accentColor, accentColor.withOpacity(0.7)],
//                   ),
//                   borderRadius: const BorderRadius.only(
//                     bottomLeft: Radius.circular(32),
//                     bottomRight: Radius.circular(32),
//                   ),
//                 ),
//                 child: SafeArea(
//                   bottom: false,
//                   child: Stack(
//                     alignment: Alignment.bottomCenter,
//                     children: [
//                       // The 3D Companion
//                       AvatarView(
//                         avatarName: avatarName,
//                         controller: _avatarController,
//                         height: isKeyboardOpen ? 180 : 380,
//                         backgroundImagePath: "assets/images/background.png",
//                         borderRadius: 0,
//                       ),
                      
//                       // Bottom label visible only when keyboard is hidden
//                       if (!isKeyboardOpen)
//                         Positioned(
//                           bottom: 20,
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//                             decoration: BoxDecoration(
//                               color: Colors.black.withOpacity(0.2),
//                               borderRadius: BorderRadius.circular(20),
//                             ),
//                             child: Row(
//                               children: [
//                                 Text(
//                                   selectedAvatar.name,
//                                   style: const TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 18,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 const SizedBox(width: 8),
//                                 Icon(
//                                   isMuted ? Icons.volume_off : Icons.volume_up,
//                                   color: Colors.white70,
//                                   size: 16,
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               ),

//               // --- VOCABULARY SUGGESTIONS ---
//               if (!isKeyboardOpen)
//                 Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 12),
//                   child: SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     child: Row(
//                       children: suggestedVocab.map((vocab) {
//                         return Padding(
//                           padding: const EdgeInsets.only(right: 8),
//                           child: SuggestedVocabChip(
//                             text: vocab['text'],
//                             onTap: () => _insertSuggestedWord(vocab['text']),
//                           ),
//                         );
//                       }).toList(),
//                     ),
//                   ),
//                 ),

//               // --- CHAT MESSAGES ---
//               Expanded(
//                 child: ListView.builder(
//                   controller: _scrollController,
//                   padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
//                   itemCount: messages.length,
//                   itemBuilder: (context, index) {
//                     final message = messages[index];
//                     return ChatMessage(
//                       text: message['text'],
//                       isUser: message['role'] == 'user',
//                       audioUrl: message['audio'],
//                       showPlayButton: message['role'] == 'avatar',
//                     );
//                   },
//                 ),
//               ),

//               // --- INPUT AREA ---
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: const BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//                 ),
//                 child: SafeArea(
//                   top: false,
//                   child: Row(
//                     children: [
//                       Expanded(
//                         child: Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 16),
//                           decoration: BoxDecoration(
//                             color: AppColors.inputFieldBg,
//                             borderRadius: BorderRadius.circular(30),
//                           ),
//                           child: TextField(
//                             controller: _textController,
//                             focusNode: _focusNode,
//                             decoration: const InputDecoration(
//                               hintText: 'Reply to your partner...',
//                               border: InputBorder.none,
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       hasTextInput
//                           ? IconButton(
//                               onPressed: () => _sendMessage(_textController.text),
//                               icon: Icon(Icons.send_rounded, color: accentColor, size: 32),
//                             )
//                           : VoiceInputButton(onTap: _startRecording),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           if (isRecording) RecordingOverlay(onRecordingComplete: _stopRecording),
//         ],
//       ),
//     );
//   }
// }

// // import 'package:flutter/material.dart';
// // import 'package:language_app/Mainhomepage/view/Result/Congratulation_screen.dart';
// // import 'package:language_app/provider/avatar_provider.dart';
// // import 'package:provider/provider.dart';
// // import '../../../utils/app_style.dart';
// // import '../../../utils/mock_data.dart';
// // import 'widgets/avatar_card.dart';
// // import 'widgets/suggested_vocab_chip.dart';
// // import 'widgets/chat_message.dart';
// // import 'widgets/voice_input_button.dart';
// // import 'widgets/difficulty_rating_popup.dart';
// // import 'widgets/recording_overlay.dart';

// // class ConversationChat extends StatefulWidget {
// //   const ConversationChat({super.key});

// //   @override
// //   State<ConversationChat> createState() => _ConversationChatState();
// // }

// // class _ConversationChatState extends State<ConversationChat> {
// //   final TextEditingController _textController = TextEditingController();
// //   final ScrollController _scrollController = ScrollController();
// //   final FocusNode _focusNode = FocusNode();

// //   List<Map<String, dynamic>> messages = [];
// //   List<Map<String, dynamic>> suggestedVocab = [];
// //   bool isRecording = false;
// //   bool isKeyboardVisible = false;
// //   bool hasTextInput = false;
// //   int messageCount = 0;
// //   final int maxMessages = 1;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _loadConversation();

// //     _focusNode.addListener(() {
// //       setState(() {
// //         isKeyboardVisible = _focusNode.hasFocus;
// //       });
// //     });

// //     _textController.addListener(() {
// //       setState(() {
// //         hasTextInput = _textController.text.trim().isNotEmpty;
// //       });
// //     });
// //   }

// //   void _loadConversation() {
// //     final thread = MockData.conversationThread;
// //     final messageData = MockData.conversationMessages;

// //     setState(() {
// //       suggestedVocab = List<Map<String, dynamic>>.from(
// //         thread['suggested_vocab'],
// //       );
// //       messages = List<Map<String, dynamic>>.from(messageData['messages']);
// //     });
// //   }

// //   void _sendMessage(String text, {bool isVoice = false}) {
// //     if (text.trim().isEmpty) return;

// //     setState(() {
// //       messages.add({
// //         "id": "m_user_${DateTime.now().millisecondsSinceEpoch}",
// //         "role": "user",
// //         "text": text,
// //         "is_voice": isVoice,
// //         "audio": isVoice ? "assets/audio/user_voice.mp3" : null,
// //         "created_at": DateTime.now().toIso8601String(),
// //       });
// //       messageCount++;
// //     });

// //     _textController.clear();
// //     _scrollToBottom();

// //     Future.delayed(const Duration(milliseconds: 500), () {
// //       _showDifficultyRating(text);
// //     });
// //   }

// //   void _showDifficultyRating(String userMessage) {
// //     String wordToRate = 'Aufgeregt';

// //     showDialog(
// //       context: context,
// //       barrierDismissible: false,
// //       builder: (context) => DifficultyRatingPopup(
// //         word: wordToRate,
// //         onRatingSelected: (difficulty) {
// //           Navigator.of(context).pop();
// //           _handleDifficultySelected(difficulty, userMessage);
// //         },
// //       ),
// //     );
// //   }

// //   void _handleDifficultySelected(String difficulty, String userMessage) {
// //     if (messageCount >= maxMessages) {
// //       Future.delayed(const Duration(milliseconds: 300), () {
// //         Navigator.pushReplacement(
// //           context,
// //           MaterialPageRoute(builder: (context) => const LessonCompletionView()),
// //         );
// //       });
// //     } else {
// //       Future.delayed(const Duration(milliseconds: 500), () {
// //         final response = MockData.mockMessageResponse(userMessage);
// //         setState(() {
// //           messages.add(response);
// //         });
// //         _scrollToBottom();
// //       });
// //     }
// //   }

// //   void _scrollToBottom() {
// //     Future.delayed(const Duration(milliseconds: 100), () {
// //       if (_scrollController.hasClients) {
// //         _scrollController.animateTo(
// //           _scrollController.position.maxScrollExtent,
// //           duration: const Duration(milliseconds: 300),
// //           curve: Curves.easeOut,
// //         );
// //       }
// //     });
// //   }

// //   void _startRecording() {
// //     setState(() {
// //       isRecording = true;
// //     });
// //   }

// //   void _stopRecording() {
// //     setState(() {
// //       isRecording = false;
// //     });

// //     Future.delayed(const Duration(milliseconds: 300), () {
// //       _sendMessage(
// //         "I love visiting Cafe Maro. It's a beautiful restaurant with delicious food and I always recommend it.",
// //         isVoice: true,
// //       );
// //     });
// //   }

// //   void _insertSuggestedWord(String word) {
// //     final currentText = _textController.text;
// //     final newText = currentText.isEmpty ? word : '$currentText $word';
// //     _textController.text = newText;
// //     _textController.selection = TextSelection.fromPosition(
// //       TextPosition(offset: newText.length),
// //     );
// //   }

// //   @override
// //   void dispose() {
// //     _textController.dispose();
// //     _scrollController.dispose();
// //     _focusNode.dispose();
// //     super.dispose();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     // Get the selected avatar from Provider
// //     final selectedAvatar = Provider.of<AvatarProvider>(context).selectedAvatar;
// //     // Detect keyboard height to help with layout if needed
// //     final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

// //     return Scaffold(
// //       backgroundColor: AppColors.conversationBg,
// //       appBar: AppBar(
// //         backgroundColor: AppColors.conversationBg,
// //         elevation: 0,
// //         leading: IconButton(
// //           icon: Icon(Icons.arrow_back_ios, color: selectedAvatar.accentColor),
// //           onPressed: () => Navigator.pop(context),
// //         ),
// //         // Title appears when keyboard is open and card is small
// //         title: AnimatedOpacity(
// //           opacity: isKeyboardVisible ? 1.0 : 0.0,
// //           duration: const Duration(milliseconds: 300),
// //           child: Text(
// //             selectedAvatar.name,
// //             style: AppTypography.avatarName.copyWith(
// //               color: selectedAvatar.accentColor,
// //             ),
// //           ),
// //         ),
// //         // title: Text(
// //         //   isKeyboardVisible ? selectedAvatar.name : '',
// //         //   style: AppTypography.avatarName.copyWith(
// //         //     color: selectedAvatar.accentColor,
// //         //   ),
// //         // ),
// //         // actions: [
// //         //   if (isKeyboardVisible)
// //         //     IconButton(
// //         //       icon: Icon(
// //         //         Icons.menu,
// //         //         color: selectedAvatar.accentColor,
// //         //       ),
// //         //       onPressed: () {},
// //         //     ),
// //         // ],
// //       ),
// //       body: Stack(
// //         children: [
// //           Column(
// //             children: [
// //               // --- DYNAMIC AVATAR CARD ---
// //               AnimatedContainer(
// //                 duration: const Duration(milliseconds: 300),
// //                 curve: Curves.easeInOut,
// //                 height: isKeyboardVisible ? 80 : 220, // Shrinks when typing
// //                 child: AvatarCard(
// //                   avatar: selectedAvatar,
// //                   // You might want to pass a 'isMini' flag to AvatarCard
// //                   // to hide internal elements like the volume button when small
// //                   onSoundTap: isKeyboardVisible
// //                       ? null
// //                       : () {
// //                           debugPrint('Sound tapped');
// //                         },
// //                 ),
// //               ),

// //               // --- HIDE INSTRUCTIONS WHEN KEYBOARD IS OPEN ---
// //               if (!isKeyboardVisible) ...[
// //                 Padding(
// //                   padding: const EdgeInsets.symmetric(
// //                     horizontal: 16,
// //                     vertical: 12,
// //                   ),
// //                   child: Text(
// //                     'Use these words in your response:',
// //                     style: AppTypography.cardTitle,
// //                   ),
// //                 ),
// //                 Padding(
// //                   padding: const EdgeInsets.symmetric(horizontal: 16),
// //                   child: Row(
// //                     mainAxisAlignment: MainAxisAlignment.start,
// //                     children: suggestedVocab.map((vocab) {
// //                       return Padding(
// //                         padding: const EdgeInsets.only(right: 8),
// //                         child: SuggestedVocabChip(
// //                           text: vocab['text'],
// //                           onTap: () => _insertSuggestedWord(vocab['text']),
// //                         ),
// //                       );
// //                     }).toList(),
// //                   ),
// //                 ),
// //               ],

// //               const SizedBox(height: 16),

// //               // Chat Messages
// //               Expanded(
// //                 child: ListView.builder(
// //                   controller: _scrollController,
// //                   padding: const EdgeInsets.symmetric(horizontal: 16),
// //                   itemCount: messages.length,
// //                   itemBuilder: (context, index) {
// //                     final message = messages[index];
// //                     final isLast = index == messages.length - 1;
// //                     return ChatMessage(
// //                       text: message['text'],
// //                       isUser: message['role'] == 'user',
// //                       audioUrl: message['audio'],
// //                       showPlayButton:
// //                           (message['role'] == 'avatar' ||
// //                               message['is_voice'] == true) &&
// //                           isLast,
// //                     );
// //                   },
// //                 ),
// //               ),

// //               // Input Area with avatar color accent
// //               Container(
// //                 padding: const EdgeInsets.all(16),
// //                 decoration: BoxDecoration(
// //                   color: Colors.white,
// //                   boxShadow: [
// //                     BoxShadow(
// //                       color: Colors.black.withOpacity(0.05),
// //                       blurRadius: 10,
// //                       offset: const Offset(0, -2),
// //                     ),
// //                   ],
// //                 ),
// //                 child: SafeArea(
// //                   child: Row(
// //                     children: [
// //                       // Text Input Field
// //                       Expanded(
// //                         child: Container(
// //                           decoration: BoxDecoration(
// //                             color: AppColors.inputFieldBg,
// //                             borderRadius: BorderRadius.circular(25),
// //                             border: Border.all(
// //                               color: _focusNode.hasFocus
// //                                   ? selectedAvatar.accentColor.withOpacity(0.5)
// //                                   : AppColors.inputFieldBorder,
// //                               width: _focusNode.hasFocus ? 2 : 1,
// //                             ),
// //                           ),
// //                           child: TextField(
// //                             controller: _textController,
// //                             focusNode: _focusNode,
// //                             decoration: InputDecoration(
// //                               hintText: 'Type your response',
// //                               hintStyle: TextStyle(
// //                                 color: Colors.grey[400],
// //                                 fontSize: 16,
// //                               ),
// //                               border: InputBorder.none,
// //                               contentPadding: const EdgeInsets.symmetric(
// //                                 horizontal: 20,
// //                                 vertical: 12,
// //                               ),
// //                             ),
// //                             onSubmitted: (text) => _sendMessage(text),
// //                           ),
// //                         ),
// //                       ),
// //                       const SizedBox(width: 12),

// //                       // Send Button or Voice Button
// //                       if (hasTextInput)
// //                         GestureDetector(
// //                           onTap: () => _sendMessage(_textController.text),
// //                           child: Container(
// //                             width: 56,
// //                             height: 56,
// //                             decoration: BoxDecoration(
// //                               gradient: LinearGradient(
// //                                 colors: [
// //                                   selectedAvatar.accentColor,
// //                                   selectedAvatar.accentColor.withOpacity(0.8),
// //                                 ],
// //                               ),
// //                               shape: BoxShape.circle,
// //                               boxShadow: [
// //                                 BoxShadow(
// //                                   color: selectedAvatar.accentColor.withOpacity(
// //                                     0.4,
// //                                   ),
// //                                   blurRadius: 12,
// //                                   offset: const Offset(0, 4),
// //                                 ),
// //                               ],
// //                             ),
// //                             child: const Icon(
// //                               Icons.send,
// //                               color: Colors.white,
// //                               size: 24,
// //                             ),
// //                           ),
// //                         )
// //                       else
// //                         VoiceInputButton(onTap: _startRecording),
// //                     ],
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           ),

// //           // Recording Overlay
// //           if (isRecording)
// //             RecordingOverlay(onRecordingComplete: _stopRecording),
// //         ],
// //       ),
// //     );
// //   }
// // }