import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:language_app/Screens/test_conversation.dart';
import 'package:language_app/avatar/avatar_controller.dart';
import 'package:language_app/avatar/avatar_view.dart';

class TestVocabularyPage extends StatefulWidget {
  final String selectedAvatar; // Add this parameter
  
  const TestVocabularyPage({
    super.key,
    required this.selectedAvatar,
  });

  @override
  State<TestVocabularyPage> createState() => _TestVocabularyPageState();
}

class _TestVocabularyPageState extends State<TestVocabularyPage> {
  int currentQuestionIndex = 0;
  String? selectedOption;
  bool showError = false;
  bool isMuted = false;
  
  // Text-to-Speech instance
  late FlutterTts flutterTts;
  
  // Avatar Controller
  late AvatarController avatarController;

  @override
  void initState() {
    super.initState();
    avatarController = AvatarController();
    _initTts();
  }

  // Initialize TTS with proper configuration
 // Initialize TTS with proper configuration
Future<void> _initTts() async {
  flutterTts = FlutterTts();
  
  // Set language to English (better compatibility)
  await flutterTts.setLanguage("en-US");
  
  // Set speech rate (0.0 to 1.0, 0.5 is normal)
  await flutterTts.setSpeechRate(0.4);
  
  // Set volume (0.0 to 1.0)
  await flutterTts.setVolume(1.0);
  
  // Set pitch (0.5 to 2.0, 1.0 is normal)
  await flutterTts.setPitch(1.0);

  // iOS specific settings - CORRECTED VERSION
  if (Platform.isIOS) {
    await flutterTts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playback,
      [
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
      ],
      IosTextToSpeechAudioMode.voicePrompt,
    );

    // Set shared instance (iOS)
    await flutterTts.setSharedInstance(true);
  }

  // Android specific - set engine
  if (await flutterTts.isLanguageAvailable("en-US")) {
    await flutterTts.setLanguage("en-US");
  }

  // Handlers for debugging
  flutterTts.setStartHandler(() {
    print("TTS Started");
  });

  flutterTts.setCompletionHandler(() {
    print("TTS Completed");
  });

  flutterTts.setErrorHandler((msg) {
    print("TTS Error: $msg");
  });
}

// ALTERNATIVE: Simplified version without iOS-specific settings
Future<void> _initTtsSimplified() async {
  flutterTts = FlutterTts();
  
  await flutterTts.setLanguage("en-US");
  await flutterTts.setSpeechRate(0.4);
  await flutterTts.setVolume(1.0);
  await flutterTts.setPitch(1.0);

  // Handlers
  flutterTts.setStartHandler(() {
    print("TTS Started");
  });

  flutterTts.setCompletionHandler(() {
    print("TTS Completed");
  });

  flutterTts.setErrorHandler((msg) {
    print("TTS Error: $msg");
  });
}

  // Speak text function
  Future<void> _speak(String text) async {
    if (!isMuted) {
      await flutterTts.stop(); // Stop any ongoing speech
      await Future.delayed(const Duration(milliseconds: 100));
      await flutterTts.speak(text);
      print("Speaking: $text");
    }
  }

  // Stop speaking
  Future<void> _stop() async {
    await flutterTts.stop();
  }

  // Toggle mute/unmute
  void _toggleMute() {
    setState(() {
      isMuted = !isMuted;
    });
    if (isMuted) {
      _stop();
    }
    print("Mute status: $isMuted");
  }

  @override
  void dispose() {
    flutterTts.stop();
    avatarController.disposeView();
    super.dispose();
  }

  // All questions data
  final List<Map<String, dynamic>> questions = [
    // Question 1: Multiple choice (Car, Cap, Cat, Can)
    {
      'type': 'multiple_choice',
      'question': null,
      'correctAnswer': 'Cat',
      'options': [
        {
          'text': 'Car',
          'textColor': const Color(0xFFFF6291),
          'bgColor': const Color(0xFFFEDF4),
          'borderColor': const Color(0xFFFF6291),
        },
        {
          'text': 'Cap',
          'textColor': const Color(0xFFFF8000),
          'bgColor': const Color(0xFFFFF6ED),
          'borderColor': const Color(0xFFFF8000),
        },
        {
          'text': 'Cat',
          'textColor': const Color(0xFFFF3333),
          'bgColor': const Color(0xFFFFEDED),
          'borderColor': const Color(0xFFFF3333),
        },
        {
          'text': 'Can',
          'textColor': const Color(0xFFFF33FC),
          'bgColor': const Color(0xFFFEDF9),
          'borderColor': const Color(0xFFFF33FC),
        },
      ],
    },
   
    {
      'type': 'fill_blank',
      'question': 'Die Katze frisst _____',
      'correctAnswer': 'Hähnchen',
      'options': [
        {
          'text': 'Katze',
          'textColor': const Color(0xFFFF6291),
          'bgColor': const Color(0xFFFEDF4),
          'borderColor': const Color(0xFFFF6291),
        },
        {
          'text': 'Frisst',
          'textColor': const Color(0xFFFF8000),
          'bgColor': const Color(0xFFFFF6ED),
          'borderColor': const Color(0xFFFF8000),
        },
        {
          'text': 'Hähnchen',
          'textColor': const Color(0xFFFF3333),
          'bgColor': const Color(0xFFFFEDED),
          'borderColor': const Color(0xFFFF3333),
        },
        {
          'text': 'Die',
          'textColor': const Color(0xFFFF8000),
          'bgColor': const Color(0xFFFFF6ED),
          'borderColor': const Color(0xFFFF8000),
        },
      ],
    },
  ];

  void handleOptionTap(String option) {
    setState(() {
      selectedOption = option;
      String correctAnswer = questions[currentQuestionIndex]['correctAnswer'];
      
      // Speak the selected option
      _speak(option);
      
      if (option != correctAnswer) {
        showError = true;
      }
    });
  }

  void handleContinue() {
    String correctAnswer = questions[currentQuestionIndex]['correctAnswer'];
    
    if (selectedOption == correctAnswer) {
      // Move to next question
      if (currentQuestionIndex < questions.length - 1) {
        setState(() {
          currentQuestionIndex++;
          selectedOption = null;
          showError = false;
        });
      } else {
        // All questions completed - navigate to conversation screen
        // Pass the avatar name to the next screen if needed
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => TestConversationPage(
      selectedAvatar: widget.selectedAvatar,
    ),
  ),
);
      }
    } else {
      setState(() {
        showError = false;
        selectedOption = null;
      });
    }
  }

  // Speak the correct answer when error dialog shows
  void _speakCorrectAnswer(String answer) {
    _speak("The right answer is $answer");
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = questions[currentQuestionIndex];
    final questionType = currentQuestion['type'];
    final questionText = currentQuestion['question'];
    final options = currentQuestion['options'] as List<Map<String, dynamic>>;
    final correctAnswer = currentQuestion['correctAnswer'];

    // Show error dialog and speak answer
    if (showError) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _speakCorrectAnswer(correctAnswer);
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Color(0xFFFF8000),
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          if (currentQuestionIndex > 0) {
                            setState(() {
                              currentQuestionIndex--;
                              selectedOption = null;
                              showError = false;
                            });
                          } else {
                            Navigator.pop(context);
                          }
                        },
                      ),
                      Text(
                        widget.selectedAvatar, // Display the selected avatar name
                        style: const TextStyle(
                          color: Color(0xFFFF8000),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // Avatar Display
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      // Avatar View
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AvatarView(
                            avatarName: widget.selectedAvatar,
                            controller: avatarController,
                            height: 220,
                            backgroundImagePath: "assets/images/background.png",
                            borderRadius: 12,
                          ),
                        ),
                      ),
                      // Sound Icon (Mute/Unmute)
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: GestureDetector(
                          onTap: _toggleMute,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isMuted 
                                  ? [Colors.grey.shade400, Colors.grey.shade600]
                                  : [const Color(0xFFFF609D), const Color(0xFFFF7A06)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isMuted ? Icons.volume_off : Icons.volume_up,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Question Container
                questionType == 'multiple_choice' 
                  ? _buildMultipleChoiceLayout(options)
                  : _buildFillBlankLayout(questionText, options),

                const Spacer(),

                // Continue Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: GestureDetector(
                    onTap: handleContinue,
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF609D), Color(0xFFFF7A06)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                
              ],
            ),

            // Error Dialog
            if (showError)
              Container(
                color: Colors.black.withOpacity(0.6),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3333),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Red header
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            "It's incorrect.",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // White content box
                        Container(
                          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'The right answer is',
                                style: TextStyle(
                                  color: Color(0xFF757575),
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                correctAnswer,
                                style: const TextStyle(
                                  color: Color(0xFFFF6347),
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 18),
                              GestureDetector(
                                onTap: () {
                                  _stop(); // Stop speaking when closing dialog
                                  setState(() {
                                    showError = false;
                                  });
                                },
                                child: Container(
                                  width: double.infinity,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFF609D), Color(0xFFFF7A06)],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Continue',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Multiple Choice Layout
  Widget _buildMultipleChoiceLayout(List<Map<String, dynamic>> options) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFFF8000),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // First Row - Car and Cap
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildOptionButton(options[0], 143, 20),
              const SizedBox(width: 12),
              _buildOptionButton(options[1], 143, 20),
            ],
          ),
          const SizedBox(height: 12),
          // Second Row - Cat and Can
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildOptionButton(options[2], 143, 20),
              const SizedBox(width: 12),
              _buildOptionButton(options[3], 143, 20),
            ],
          ),
        ],
      ),
    );
  }

  // Fill Blank Layout
  Widget _buildFillBlankLayout(String? questionText, List<Map<String, dynamic>> options) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFFF8000),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Question Text
          Text(
            questionText ?? '',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          // Icons Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.language,
                size: 22,
                color: Color(0xFFFF8000),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  if (questionText != null) {
                    _speak(questionText);
                  }
                },
                child: const Icon(
                  Icons.volume_up,
                  size: 22,
                  color: Color(0xFFFF609D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Options Row - 4 buttons horizontally
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildOptionButton(options[0], 70, 10),
              const SizedBox(width: 6),
              _buildOptionButton(options[1], 70, 10),
              const SizedBox(width: 6),
              _buildOptionButton(options[2], 70, 10),
              const SizedBox(width: 6),
              _buildOptionButton(options[3], 70, 10),
            ],
          ),
        ],
      ),
    );
  }

  // Option Button
  Widget _buildOptionButton(Map<String, dynamic> option, double width, double fontSize) {
    final isSelected = selectedOption == option['text'];
    
    return GestureDetector(
      onTap: () => handleOptionTap(option['text']),
      child: Container(
        width: width,
        height: fontSize == 20 ? 64 : 44,
        decoration: BoxDecoration(
          color: isSelected 
              ? option['textColor']
              : option['bgColor'],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: option['borderColor'],
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          option['text'],
          style: TextStyle(
            color: isSelected 
                ? Colors.white
                : option['textColor'],
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}