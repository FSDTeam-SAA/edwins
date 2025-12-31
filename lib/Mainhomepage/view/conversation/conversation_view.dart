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