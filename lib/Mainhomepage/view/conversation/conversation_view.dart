// import 'package:flutter/material.dart';
// import 'package:language_app/Mainhomepage/view/conversation/conversation_chat.dart';
// import 'package:language_app/provider/avatar_provider.dart';
// import 'package:provider/provider.dart';
// import '../../../utils/app_style.dart';
// import '../../../models/avatar_model.dart';

// import 'widgets/avatar_selector.dart';

// class ConversationView extends StatefulWidget {
//   const ConversationView({super.key});

//   @override
//   State<ConversationView> createState() => _ConversationViewState();
// }

// class _ConversationViewState extends State<ConversationView> {
//   void _startConversation(AvatarModel avatar) {
//     // Save the selected avatar to provider
//     Provider.of<AvatarProvider>(context, listen: false).selectAvatar(avatar);
    
//     // Navigate to conversation screen
//     Navigator.push(context, MaterialPageRoute(
//       builder: (context) => const ConversationChat(),
//     ));
//   }

//   @override
//   Widget build(BuildContext context) {
//     final avatarProvider = Provider.of<AvatarProvider>(context);

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios, color: AppColors.primaryOrange),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text(
//           "Choose Your Companion",
//           style: TextStyle(
//             color: AppColors.primaryOrange,
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         centerTitle: true,
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24.0),
//           child: Column(
//             children: [
//               const SizedBox(height: 20),

//               // Subtitle
//               Text(
//                 'Select your AI companion for the conversation',
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: Colors.grey[600],
//                 ),
//                 textAlign: TextAlign.center,
//               ),

//               const SizedBox(height: 20),

//               // Avatar Selector
//               Expanded(
//                 child: SingleChildScrollView(
//                   physics: const BouncingScrollPhysics(),
//                   child: AvatarSelector(
//                     selectedAvatar: avatarProvider.selectedAvatar,
//                     onAvatarSelected: (avatar) {
//                       avatarProvider.selectAvatar(avatar);
//                     },
//                   ),
//                 ),
//               ),

//               // Start Conversation Button
//               Padding(
//                 padding: const EdgeInsets.only(bottom: 40.0, top: 20.0),
//                 child: GestureDetector(
//                   onTap: () => _startConversation(avatarProvider.selectedAvatar),
//                   child: AnimatedContainer(
//                     duration: const Duration(milliseconds: 300),
//                     width: double.infinity,
//                     height: 60,
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         colors: [
//                           avatarProvider.selectedAvatar.accentColor,
//                           avatarProvider.selectedAvatar.accentColor.withOpacity(0.8),
//                         ],
//                       ),
//                       borderRadius: BorderRadius.circular(15),
//                       boxShadow: [
//                         BoxShadow(
//                           color: avatarProvider.selectedAvatar.accentColor.withOpacity(0.4),
//                           blurRadius: 15,
//                           offset: const Offset(0, 8),
//                         )
//                       ],
//                     ),
//                     child: Center(
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             "Start with ${avatarProvider.selectedAvatar.name}",
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                               letterSpacing: 0.5,
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           Container(
//                             padding: const EdgeInsets.all(4),
//                             decoration: BoxDecoration(
//                               color: Colors.white.withOpacity(0.2),
//                               shape: BoxShape.circle,
//                             ),
//                             child: const Icon(
//                               Icons.arrow_forward_rounded,
//                               color: Colors.white,
//                               size: 20,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import '../../../utils/app_style.dart';
// import '../../../models/learning_models.dart';
// import '../../../widgets/data/repository.dart';

// // Import our refactored widgets
// import '../widgets/chat_bubble.dart';
// import '../widgets/voice_recorder_ui.dart';

// enum VoiceState { normal, voiceReady, recording }

// class ConversationView extends StatefulWidget {
//   const ConversationView({super.key});

//   @override
//   State<ConversationView> createState() => _ConversationViewState();
// }

// class _ConversationViewState extends State<ConversationView> {
//   final ILearningRepository repository = MockLearningRepository();
//   final TextEditingController _textController = TextEditingController();
//   final FocusNode _textFocusNode = FocusNode();

//   // Unified State Management
//   VoiceState _currentVoiceState = VoiceState.normal;
//   String? _userAnswer;
//   ConversationStep? _stepData;
//   bool _isTextFieldFocused = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadData();
    
//     // Listen to focus changes
//     _textFocusNode.addListener(() {
//       setState(() {
//         _isTextFieldFocused = _textFocusNode.hasFocus;
//       });
//     });
//   }

//   @override
//   void dispose() {
//     _textController.dispose();
//     _textFocusNode.dispose();
//     super.dispose();
//   }

//   Future<void> _loadData() async {
//     final data = await repository.fetchConversation("conv_1");
//     setState(() => _stepData = data);
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_stepData == null) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator(color: AppColors.primaryOrange)),
//       );
//     }

//     return Scaffold(
//       backgroundColor: Colors.white,
//       // Stack allows the Voice Overlay to cover the entire screen including AppBar
//       body: Stack(
//         children: [
//           // --- LAYER 1: MAIN CONVERSATION UI ---
//           Column(
//             children: [
//               _buildAppBar(),
//               Expanded(
//                 child: ListView(
//                   padding: const EdgeInsets.all(20),
//                   children: [
//                     const Text(
//                       "Translate the sentence:", 
//                       style: TextStyle(
//                         fontSize: 18, 
//                         fontWeight: FontWeight.w600, 
//                         color: Colors.black
//                       ),
//                     ),
//                     const SizedBox(height: 20),
                    
//                     // System Prompt (Yellow Bubble)
//                     ChatBubble(text: _stepData!.prompt, isUser: false),
                    
//                     // User Answer (Appears after recording/typing)
//                     if (_userAnswer != null) ...[
//                       const SizedBox(height: 20),
//                       _buildAudioResultBubble(),
//                       const SizedBox(height: 10),
//                       ChatBubble(text: _userAnswer!, isUser: true),
//                     ]
//                   ],
//                 ),
//               ),
              
//               // Bottom Input Bar (Hidden when the mic overlay is active)
//               if (_currentVoiceState == VoiceState.normal) _buildTextInputUI(),
//             ],
//           ),

//           // --- LAYER 2: FULL SCREEN VOICE OVERLAY ---
//           if (_currentVoiceState != VoiceState.normal)
//             Positioned.fill(
//               child: VoiceRecorderUI(
//                 state: _currentVoiceState,
//                 onStartRecording: () => setState(() => _currentVoiceState = VoiceState.recording),
//                 onStopRecording: _stopRecordingAndProcess,
//                 onCancel: () => setState(() => _currentVoiceState = VoiceState.normal),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   // Custom AppBar inside Column to allow the Overlay to cover it easily
//   Widget _buildAppBar() {
//     return SafeArea(
//       bottom: false,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
//         child: Row(
//           children: [
//             IconButton(
//               icon: const Icon(Icons.arrow_back_ios, color: AppColors.primaryOrange),
//               onPressed: () => Navigator.pop(context),
//             ),
//             const Expanded(
//               child: Center(
//                 child: Text(
//                   "Conversation", 
//                   style: TextStyle(
//                     color: AppColors.primaryOrange, 
//                     fontSize: 20, 
//                     fontWeight: FontWeight.bold
//                   ),
//                 ),
//               ),
//             ),
//             // IconButton(
//             //   icon: const Icon(Icons.menu, color: AppColors.primaryOrange),
//             //   onPressed: () {},
//             // ),
//           ],
//         ),
//       ),
//     );
//   }

//   // Audio waveform bubble seen in "Conversation 1 voice answer 2"
//   Widget _buildAudioResultBubble() {
//     return Align(
//       alignment: Alignment.centerRight,
//       child: Container(
//         width: 220,
//         padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
//         decoration: BoxDecoration(
//           gradient: AppColors.primaryGradient,
//           borderRadius: BorderRadius.circular(20),
//         ),
//         child: Row(
//           children: [
//             const Icon(Icons.play_arrow, color: Colors.white, size: 28),
//             const SizedBox(width: 8),
//             Expanded(
//               child: Opacity(
//                 opacity: 0.6,
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: List.generate(15, (i) => Container(
//                     width: 2,
//                     height: (i % 3 == 0) ? 12 : 6,
//                     color: Colors.white,
//                   )),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 8),
//             const Text("1.34", style: TextStyle(color: Colors.white, fontSize: 12)),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTextInputUI() {
//     return Container(
//       padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         border: Border(top: BorderSide(color: Colors.grey.shade200)),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: TextField(
//               controller: _textController,
//               focusNode: _textFocusNode,
//               decoration: InputDecoration(
//                 hintText: "Type your response",
//                 hintStyle: TextStyle(color: Colors.grey[400]),
//                 contentPadding: const EdgeInsets.symmetric(horizontal: 20),
//                 enabledBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(15),
//                   borderSide: const BorderSide(color: AppColors.primaryOrange),
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(15),
//                   borderSide: const BorderSide(color: AppColors.primaryOrange, width: 2),
//                 ),
//               ),
//               onSubmitted: (value) => _handleTextSubmit(),
//             ),
//           ),
//           const SizedBox(width: 12),
//           GestureDetector(
//             onTap: _isTextFieldFocused 
//               ? _handleTextSubmit 
//               : () => setState(() => _currentVoiceState = VoiceState.voiceReady),
//             child: Container(
//               height: 50, 
//               width: 50,
//               decoration: const BoxDecoration(
//                 shape: BoxShape.circle,
//                 gradient: AppColors.primaryGradient,
//               ),
//               child: Icon(
//                 _isTextFieldFocused ? Icons.send : Icons.mic, 
//                 color: Colors.white
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // --- LOGIC METHODS ---

//   void _handleTextSubmit() {
//     final text = _textController.text.trim();
//     if (text.isEmpty) return;

//     setState(() {
//       _userAnswer = text;
//     });

//     _textController.clear();
//     _textFocusNode.unfocus();

//     // Brief delay for UX so user sees the message appear in chat
//     Future.delayed(const Duration(milliseconds: 500), () {
//       if (mounted) {
//         _handleFinalAnswer(_userAnswer!);
//       }
//     });
//   }

//   Future<void> _stopRecordingAndProcess() async {
//     // 1. Move to "Normal" state immediately on release
//     setState(() => _currentVoiceState = VoiceState.normal);
    
//     // 2. Show Processing Dialog
//     showDialog(
//       context: context, 
//       barrierDismissible: false,
//       builder: (c) => const Center(
//         child: CircularProgressIndicator(color: AppColors.primaryOrange),
//       ),
//     );
    
//     // Simulate Speech-to-Text delay
//     await Future.delayed(const Duration(seconds: 1)); 
//     if (!mounted) return;
//     Navigator.pop(context); // Close Dialog

//     setState(() {
//       _userAnswer = "Die Katze frisst Hühnchen";
//     });

//     // 3. Brief delay for UX so user sees the message appear in chat
//     await Future.delayed(const Duration(milliseconds: 1000));
//     if (!mounted) return;
//     _handleFinalAnswer(_userAnswer!);
//   }

//   void _handleFinalAnswer(String answer) {
//     if (answer.isEmpty) return;

//     // These would typically come from a logic controller/bloc
//     final Map<String, int> newScores = {
//       "Speaking": 85, 
//       "Listening": 70, 
//       "Grammar": 92, 
//       "Vocabulary": 75, 
//       "Writing": 60
//     };

//     Navigator.pushNamed(
//       context, 
//       '/vocab-result', 
//       arguments: newScores,
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:language_app/Mainhomepage/view/Result/result_view.dart';
import 'package:language_app/models/learning_models.dart';
import 'package:language_app/utils/app_style.dart';
import 'package:language_app/widgets/data/repository.dart';

// Import our refactored widgets
import '../widgets/chat_bubble.dart';
import '../widgets/voice_recorder_ui.dart';

enum VoiceState { normal, voiceReady, recording }

class ConversationView extends StatefulWidget {
  const ConversationView({super.key});

  @override
  State<ConversationView> createState() => _ConversationViewState();
}

class _ConversationViewState extends State<ConversationView> {
  final ILearningRepository repository = MockLearningRepository();
  final TextEditingController _textController = TextEditingController();

  // Unified State Management
  VoiceState _currentVoiceState = VoiceState.normal;
  String? _userAnswer;
  ConversationStep? _stepData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await repository.fetchConversation("conv_1");
    setState(() => _stepData = data);
  }

  @override
  Widget build(BuildContext context) {
    if (_stepData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryOrange)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      // Stack allows the Voice Overlay to cover the entire screen including AppBar
      body: Stack(
        children: [
          // --- LAYER 1: MAIN CONVERSATION UI ---
          Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text(
                      "Translate the sentence:", 
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.w600, 
                        color: Colors.black
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // System Prompt (Yellow Bubble)
                    ChatBubble(text: _stepData!.prompt, isUser: false),
                    
                    // User Answer (Appears after recording/typing)
                    if (_userAnswer != null) ...[
                      const SizedBox(height: 20),
                      _buildAudioResultBubble(),
                      const SizedBox(height: 10),
                      ChatBubble(text: _userAnswer!, isUser: true),
                    ]
                  ],
                ),
              ),
              
              // Bottom Input Bar (Hidden when the mic overlay is active)
              if (_currentVoiceState == VoiceState.normal) _buildTextInputUI(),
            ],
          ),

          // --- LAYER 2: FULL SCREEN VOICE OVERLAY ---
          if (_currentVoiceState != VoiceState.normal)
            Positioned.fill(
              child: VoiceRecorderUI(
                state: _currentVoiceState,
                onStartRecording: () => setState(() => _currentVoiceState = VoiceState.recording),
                onStopRecording: _stopRecordingAndProcess,
                onCancel: () => setState(() => _currentVoiceState = VoiceState.normal),
              ),
            ),
        ],
      ),
    );
  }

  // Custom AppBar inside Column to allow the Overlay to cover it easily
  Widget _buildAppBar() {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: AppColors.primaryOrange),
              onPressed: () => Navigator.pop(context),
            ),
            const Expanded(
              child: Center(
                child: Text(
                  "Conversation", 
                  style: TextStyle(
                    color: AppColors.primaryOrange, 
                    fontSize: 20, 
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
            ),
            // IconButton(
            //   icon: const Icon(Icons.menu, color: AppColors.primaryOrange),
            //   onPressed: () {},
            // ),
          ],
        ),
      ),
    );
  }

  // Audio waveform bubble seen in "Conversation 1 voice answer 2"
  Widget _buildAudioResultBubble() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 220,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.play_arrow, color: Colors.white, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Opacity(
                opacity: 0.6,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(15, (i) => Container(
                    width: 2,
                    height: (i % 3 == 0) ? 12 : 6,
                    color: Colors.white,
                  )),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text("1.34", style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextInputUI() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: "Type your response",
                hintStyle: TextStyle(color: Colors.grey[400]),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: AppColors.primaryOrange),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: AppColors.primaryOrange, width: 2),
                ),
              ),
              onSubmitted: (value) => _handleFinalAnswer(value),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => setState(() => _currentVoiceState = VoiceState.voiceReady),
            child: Container(
              height: 50, width: 50,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
              child: const Icon(Icons.mic, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // --- LOGIC METHODS ---

  Future<void> _stopRecordingAndProcess() async {
    // 1. Move to "Normal" state immediately on release
    setState(() => _currentVoiceState = VoiceState.normal);
    
    // 2. Show Processing Dialog
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (c) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryOrange),
      ),
    );
    
    // Simulate Speech-to-Text delay
    await Future.delayed(const Duration(seconds: 1)); 
    if (!mounted) return;
    Navigator.pop(context); // Close Dialog

    setState(() {
      _userAnswer = "Die Katze frisst Hühnchen";
    });

    // 3. Brief delay for UX so user sees the message appear in chat
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    _handleFinalAnswer(_userAnswer!);
  }

  void _handleFinalAnswer(String answer) {
    if (answer.isEmpty) return;

    // These would typically come from a logic controller/bloc
    final Map<String, int> newScores = {
      "Speaking": 85, 
      "Listening": 70, 
      "Grammar": 92, 
      "Vocabulary": 75, 
      "Writing": 60
    };

    Navigator.push(context, MaterialPageRoute(builder: 
      (context) => ResultView(skills: newScores),
    ));

    // Navigator.pushNamed(
    //   context, 
    //   '/vocab-result', 
    //   arguments: newScores,
    // );
    // Navigator.pushNamed(
    //   context, 
    //   '/vocab-result', 
    //   arguments: newScores,
    // );
  }
}