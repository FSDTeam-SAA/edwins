import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:language_app/Auth/login.dart';
import 'package:language_app/Screens/test_vocabulary.dart';
import 'package:language_app/avatar/avatar_controller.dart';
import 'package:language_app/avatar/avatar_view.dart';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter/services.dart';
class TestConversationPage extends StatefulWidget {
  final String selectedAvatar;
  
  const TestConversationPage({
    super.key,
    required this.selectedAvatar,
  });

  @override
  State<TestConversationPage> createState() => _TestConversationPageState();
}

class _TestConversationPageState extends State<TestConversationPage> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  bool isRecording = false;
  bool showWaveform = false;
  bool showSendButton = false;
  bool isMuted = false;
  bool isAvatarMinimized = false;
  bool isAvatarSpeaking = false;
  String? recordedText;
  bool showRecordingControls = false;

  // Text-to-Speech instance
  late FlutterTts flutterTts;
  
  // Avatar Controller
  late AvatarController avatarController;
  
  // Animation Controllers
  late AnimationController _waveformController;
  late AnimationController _buttonPressController;
  late AnimationController _avatarController;
  late AnimationController _speakingController;
  late Animation<double> _buttonScaleAnimation;
  late Animation<double> _avatarSizeAnimation;

  List<Map<String, dynamic>> messages = [
    {
      'text': 'The cat eats chicken.',
      'isUser': true,
      'type': 'text',
    },
  ];

  String currentQuestion = 'Translate the sentence:';
  int currentExerciseType = 1; // 1: Translation, 2: Multiple Choice, 3: Fill in blank
     // Viseme data
     Map<String, List<VisemeData>> visemeMap = {};
@override
void initState() {
  super.initState();
  avatarController = AvatarController();
  _initTts();
  _initAnimations();
  
  _textController.addListener(() {
    setState(() {
      showSendButton = _textController.text.trim().isNotEmpty;
    });
  });
  
  // Automatically speak the first message
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (messages.isNotEmpty && mounted) {
        _speak(messages[0]['text']);
      }
    });
  });
}
 
  void _initAnimations() {
    _loadVisemeData();
    _waveformController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _buttonPressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _avatarController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _speakingController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..repeat(reverse: true);

    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _buttonPressController, curve: Curves.easeInOut),
    );

    _avatarSizeAnimation = Tween<double>(begin: 500.0, end: 150.0).animate(
      CurvedAnimation(parent: _avatarController, curve: Curves.easeInOutCubic),
    );
  }

Future<void> _initTts() async {
  flutterTts = FlutterTts();
  
  await flutterTts.setLanguage("en-US");
  
  // Set voice based on avatar selection
  if (widget.selectedAvatar.toLowerCase() == 'karl') {
    // Karl = Male voice
    if (Platform.isAndroid) {
      await flutterTts.setVoice({"name": "en-us-x-tpd-local", "locale": "en-US"});
    } else if (Platform.isIOS) {
      await flutterTts.setVoice({"name": "com.apple.ttsbundle.Daniel-compact", "locale": "en-US"});
    }
  } else {
    // Clara = Female voice (default)
    if (Platform.isAndroid) {
      await flutterTts.setVoice({"name": "en-us-x-tpf-local", "locale": "en-US"});
    } else if (Platform.isIOS) {
      await flutterTts.setVoice({"name": "com.apple.ttsbundle.Samantha-compact", "locale": "en-US"});
    }
  }
  
  await flutterTts.setSpeechRate(0.4);
  await flutterTts.setVolume(1.0);
  await flutterTts.setPitch(1.0);

  if (Platform.isIOS) {
    await flutterTts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.ambient,
      [
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
      ],
      IosTextToSpeechAudioMode.voicePrompt,
    );
    await flutterTts.setSharedInstance(true);
  }

  flutterTts.setStartHandler(() {
    setState(() => isAvatarSpeaking = true);
  });

  flutterTts.setCompletionHandler(() {
    setState(() => isAvatarSpeaking = false);
  });

  flutterTts.setErrorHandler((msg) {
    setState(() => isAvatarSpeaking = false);
  });
}

Future<void> _speak(String text) async {
  if (!isMuted) {
    await flutterTts.stop();
    await Future.delayed(const Duration(milliseconds: 100));
    
    print('🎤 Speaking: $text');
    print('📊 Speech Rate: 0.4');
    
    // Start lip sync animation BEFORE speaking
    _startLipSync(text);
    
    // Small delay to ensure lip sync starts
    await Future.delayed(const Duration(milliseconds: 50));
    
    // Speak with await to ensure it completes
    var result = await flutterTts.speak(text);
    if (result == 1) {
      print('✅ TTS started successfully');
    } else {
      print('❌ TTS failed to start: $result');
    }
  }
}

  Future<void> _stop() async {
    await flutterTts.stop();
  }
  // Translation helper function
String _translateToGerman(String englishText) {
  final translations = {
    'the cat eats chicken': 'Die Katze frisst Hühnchen',
    'hello': 'Hallo',
    'good morning': 'Guten Morgen',
    'thank you': 'Danke',
    // Add more translations as needed
  };
  
  String lowerText = englishText.toLowerCase().trim();
  return translations[lowerText] ?? englishText;
}

// German phoneme to viseme mapper
List<VisemeData> _generateVisemesFromGermanWord(String word) {
  List<VisemeData> visemes = [];
  double currentTime = 0.0;
  final double phonemeDuration = 0.15; // Each sound lasts 150ms
  
  // Convert word to lowercase
  word = word.toLowerCase();
  
  print('🔤 Generating visemes for: "$word"');
  
  int i = 0;
  while (i < word.length) {
    String char = word[i];
    String? nextChar = i + 1 < word.length ? word[i + 1] : null;
    
    // Handle German digraphs (two-letter combinations)
    if (nextChar != null) {
      String digraph = char + nextChar;
      
      // German specific combinations
      if (digraph == 'ch') {
        visemes.add(VisemeData('viseme_CH', currentTime, currentTime + phonemeDuration));
        currentTime += phonemeDuration;
        i += 2;
        continue;
      } else if (digraph == 'sch') {
        if (i + 2 < word.length && word[i + 2] == 'h') {
          visemes.add(VisemeData('viseme_SS', currentTime, currentTime + phonemeDuration));
          currentTime += phonemeDuration;
          i += 3;
          continue;
        }
      } else if (digraph == 'ie') {
        visemes.add(VisemeData('viseme_I', currentTime, currentTime + phonemeDuration));
        currentTime += phonemeDuration;
        i += 2;
        continue;
      } else if (digraph == 'ei' || digraph == 'ai') {
        visemes.add(VisemeData('viseme_aa', currentTime, currentTime + phonemeDuration));
        currentTime += phonemeDuration;
        i += 2;
        continue;
      } else if (digraph == 'eu' || digraph == 'äu') {
        visemes.add(VisemeData('viseme_O', currentTime, currentTime + phonemeDuration));
        currentTime += phonemeDuration;
        i += 2;
        continue;
      }
    }
    
    // Single character mappings
    String? visemeName;
    
    switch (char) {
      // Vowels
      case 'a':
      case 'ä':
        visemeName = 'viseme_aa';
        break;
      case 'e':
        visemeName = 'viseme_E';
        break;
      case 'i':
        visemeName = 'viseme_I';
        break;
      case 'o':
      case 'ö':
        visemeName = 'viseme_O';
        break;
      case 'u':
      case 'ü':
        visemeName = 'viseme_U';
        break;
      
      // Consonants
      case 'b':
      case 'p':
        visemeName = 'viseme_PP';
        break;
      case 'd':
      case 't':
        visemeName = 'viseme_DD';
        break;
      case 'f':
      case 'v':
        visemeName = 'viseme_FF';
        break;
      case 'g':
      case 'k':
        visemeName = 'viseme_kk';
        break;
      case 'h':
        visemeName = 'viseme_O'; // Slight open mouth
        break;
      case 'l':
        visemeName = 'viseme_DD';
        break;
      case 'm':
        visemeName = 'viseme_PP'; // Lips closed
        break;
      case 'n':
        visemeName = 'viseme_nn';
        break;
      case 'r':
        visemeName = 'viseme_RR';
        break;
      case 's':
      case 'ß':
      case 'z':
        visemeName = 'viseme_SS';
        break;
      case 'w':
        visemeName = 'viseme_FF';
        break;
      case 'j':
        visemeName = 'viseme_I';
        break;
      default:
        // Skip unknown characters
        i++;
        continue;
    }
    
    if (visemeName != null) {
      visemes.add(VisemeData(visemeName, currentTime, currentTime + phonemeDuration));
      currentTime += phonemeDuration;
      print('  ➡️ $char → $visemeName');
    }
    
    i++;
  }
  
  print('  ✅ Generated ${visemes.length} visemes');
  return visemes;
}
// Load viseme data
Future<void> _loadVisemeData() async {
  _loadDefaultVisemeData();
}

void _loadDefaultVisemeData() {
  visemeMap['car'] = [
    VisemeData('viseme_kk', 0.0, 0.15),
    VisemeData('viseme_aa', 0.15, 0.35),
    VisemeData('viseme_RR', 0.35, 0.5),
  ];
  
  visemeMap['cat'] = [
    VisemeData('viseme_kk', 0.0, 0.15),
    VisemeData('viseme_aa', 0.15, 0.35),
    VisemeData('viseme_DD', 0.35, 0.5),
  ];
  
  visemeMap['cap'] = [
    VisemeData('viseme_kk', 0.0, 0.15),
    VisemeData('viseme_aa', 0.15, 0.35),
    VisemeData('viseme_PP', 0.35, 0.5),
  ];
  
  visemeMap['can'] = [
    VisemeData('viseme_kk', 0.0, 0.15),
    VisemeData('viseme_aa', 0.15, 0.35),
    VisemeData('viseme_nn', 0.35, 0.5),
  ];
  
  visemeMap['the'] = [
    VisemeData('viseme_TH', 0.0, 0.15),
    VisemeData('viseme_E', 0.15, 0.3),
  ];
  
  visemeMap['right'] = [
    VisemeData('viseme_RR', 0.0, 0.12),
    VisemeData('viseme_I', 0.12, 0.25),
    VisemeData('viseme_DD', 0.25, 0.4),
  ];
  
  visemeMap['answer'] = [
    VisemeData('viseme_aa', 0.0, 0.15),
    VisemeData('viseme_nn', 0.15, 0.25),
    VisemeData('viseme_SS', 0.25, 0.35),
    VisemeData('viseme_E', 0.35, 0.45),
    VisemeData('viseme_RR', 0.45, 0.6),
  ];
  
  visemeMap['is'] = [
    VisemeData('viseme_I', 0.0, 0.12),
    VisemeData('viseme_SS', 0.12, 0.25),
  ];
  
  visemeMap['correct'] = [
    VisemeData('viseme_kk', 0.0, 0.12),
    VisemeData('viseme_O', 0.12, 0.25),
    VisemeData('viseme_RR', 0.25, 0.35),
    VisemeData('viseme_E', 0.35, 0.45),
    VisemeData('viseme_kk', 0.45, 0.55),
    VisemeData('viseme_DD', 0.55, 0.65),
  ];
  
  visemeMap['translate'] = [
    VisemeData('viseme_DD', 0.0, 0.1),
    VisemeData('viseme_RR', 0.1, 0.2),
    VisemeData('viseme_aa', 0.2, 0.3),
    VisemeData('viseme_nn', 0.3, 0.4),
    VisemeData('viseme_SS', 0.4, 0.5),
    VisemeData('viseme_E', 0.5, 0.6),
  ];
  
  visemeMap['sentence'] = [
    VisemeData('viseme_SS', 0.0, 0.12),
    VisemeData('viseme_E', 0.12, 0.22),
    VisemeData('viseme_nn', 0.22, 0.32),
    VisemeData('viseme_DD', 0.32, 0.42),
    VisemeData('viseme_E', 0.42, 0.52),
    VisemeData('viseme_nn', 0.52, 0.65),
  ];
  
  // German words for "Die Katze frisst Hühnchen"
// German words for "Die Katze frisst Hühnchen" - Adjusted for speech rate 0.4
visemeMap['die'] = [
  VisemeData('viseme_DD', 0.0, 0.2),
  VisemeData('viseme_I', 0.2, 0.4),
];

visemeMap['katze'] = [
  VisemeData('viseme_kk', 0.0, 0.25),
  VisemeData('viseme_aa', 0.25, 0.5),
  VisemeData('viseme_DD', 0.5, 0.7),
  VisemeData('viseme_E', 0.7, 0.9),
];

visemeMap['frisst'] = [
  VisemeData('viseme_FF', 0.0, 0.2),
  VisemeData('viseme_RR', 0.2, 0.35),
  VisemeData('viseme_I', 0.35, 0.5),
  VisemeData('viseme_SS', 0.5, 0.7),
  VisemeData('viseme_DD', 0.7, 0.9),
];

visemeMap['hühnchen'] = [
  VisemeData('viseme_O', 0.0, 0.2),
  VisemeData('viseme_nn', 0.2, 0.4),
  VisemeData('viseme_CH', 0.4, 0.6),
  VisemeData('viseme_E', 0.6, 0.8),
  VisemeData('viseme_nn', 0.8, 1.0),
];
  
}

void _startLipSync(String text) {
  final words = text.toLowerCase().split(' ');
  print('🔊 Starting lip sync for: $text');
  
  double currentDelay = 0.0; // Cumulative delay in seconds
  
  for (var word in words) {
    word = word.replaceAll(RegExp(r'[^\wäöüß]'), ''); // Keep German characters
    
    if (word.isEmpty) continue;
    
    print('🔍 Processing word: "$word"');
    
    List<VisemeData> visemes;
    
    // Check if we have pre-defined viseme data
    if (visemeMap.containsKey(word)) {
      visemes = visemeMap[word]!;
      print('  📚 Using pre-defined visemes');
    } else {
      // Generate visemes automatically
      visemes = _generateVisemesFromGermanWord(word);
      print('  🤖 Auto-generated visemes');
    }
    
    // Play each viseme with proper timing
    for (var viseme in visemes) {
      final absoluteStartTime = currentDelay + viseme.startTime;
      final duration = viseme.endTime - viseme.startTime;
      final delay = (absoluteStartTime * 1000).toInt();
      
      Future.delayed(Duration(milliseconds: delay), () {
        if (mounted && isAvatarSpeaking) {
          avatarController.triggerViseme(viseme.name, duration: duration);
        }
      });
    }
    
    // Add word duration to cumulative delay
    if (visemes.isNotEmpty) {
      currentDelay += visemes.last.endTime;
    }
    
    // Add pause between words (200ms)
    currentDelay += 0.2;
  }
}
  void _toggleMute() {
    setState(() {
      isMuted = !isMuted;
    });
    if (isMuted) {
      _stop();
    }
  }

  void _toggleAvatarSize() {
    setState(() {
      isAvatarMinimized = !isAvatarMinimized;
    });
    if (isAvatarMinimized) {
      _avatarController.forward();
    } else {
      _avatarController.reverse();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _waveformController.dispose();
    _buttonPressController.dispose();
    _avatarController.dispose();
    _speakingController.dispose();
    flutterTts.stop();
    avatarController.disposeView();
    super.dispose();
  }

  void _startRecording() {
    HapticFeedback.mediumImpact();
    setState(() {
      isRecording = true;
      showWaveform = true;
      showRecordingControls = false;
      recordedText = null;
    });
  }

  void _stopRecording() {
    if (!isRecording) return;

    HapticFeedback.lightImpact();
    setState(() {
      isRecording = false;
      showRecordingControls = true;
      recordedText = "Die Katze frisst Hühnchen.";
    });
  }

  void _cancelRecording() {
    HapticFeedback.lightImpact();
    setState(() {
      showRecordingControls = false;
      showWaveform = false;
      recordedText = null;
    });
  }

void _approveRecording() {
  HapticFeedback.mediumImpact();
  setState(() {
    showRecordingControls = false;
    showWaveform = false;

    messages.add({
      'text': recordedText,
      'isUser': false,
      'type': 'text',
    });
    recordedText = null;
  });

  // Translate and speak (lip sync will happen inside _speak function)
  String germanText = 'Die Katze frisst Hühnchen.';
  _speak(germanText);

  Timer(const Duration(seconds: 3), () {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        _createFadeRoute(const LanguageLevelPage()),
      );
    }
  });
}
void _sendMessage() {
  if (_textController.text.trim().isEmpty) return;

  String userMessage = _textController.text;
  
  setState(() {
    messages.add({
      'text': userMessage,
      'isUser': false,
      'type': 'text',
    });
    _textController.clear();
    showSendButton = false;
  });

  // Translate and speak (lip sync will happen inside _speak function)
  String translatedMessage = _translateToGerman(userMessage);
  _speak(translatedMessage);

  Timer(const Duration(seconds: 3), () {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        _createFadeRoute(const LanguageLevelPage()),
      );
    }
  });
}

  void _checkAnswer(String answer, bool isCorrect) async {
    await _buttonPressController.forward();
    await _buttonPressController.reverse();

    if (isCorrect) {
      HapticFeedback.mediumImpact();
      // Show success dialog
      _showSuccessDialog(answer);
    } else {
      // Triple vibration for wrong answer
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      HapticFeedback.heavyImpact();
      
      // Show error dialog
      _showErrorDialog(answer);
    }
  }

  void _showErrorDialog(String wrongAnswer) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ErrorDialog(correctAnswer: 'Cat'),
    );
  }

  void _showSuccessDialog(String correctAnswer) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SuccessDialog(answer: correctAnswer),
    ).then((_) {
      // Navigate after closing dialog
      Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            _createFadeRoute(const LanguageLevelPage()),
          );
        }
      });
    });
  }

  Route _createFadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeInOut),
        );
        
        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Column(
                children: [
                  _buildAvatarSection(),
                  if (currentQuestion.isNotEmpty)
                    _buildQuestionHeader(),
                  Expanded(
                    child: Stack(
                      children: [
                        ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            return _buildMessage(messages[index]);
                          },
                        ),
                        if (currentExerciseType == 2)
                          _buildMultipleChoiceOptions(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _buildBottomInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _AnimatedIconButton(
                icon: Icons.arrow_back_ios,
                color: const Color(0xFFFF8000),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 4),
              Text(
                widget.selectedAvatar,
                style: const TextStyle(
                  color: Color(0xFFFF8000),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          _AnimatedIconButton(
            icon: Icons.menu,
            color: const Color(0xFFFF8000),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionHeader() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Text(
        currentQuestion,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return AnimatedBuilder(
      animation: _avatarSizeAnimation,
      builder: (context, child) {
        double avatarHeight = _avatarSizeAnimation.value;
        
        return GestureDetector(
          onTap: _toggleAvatarSize,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            width: double.infinity,
            height: avatarHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      AvatarView(
                        avatarName: widget.selectedAvatar,
                        controller: avatarController,
                        height: avatarHeight,
                        backgroundImagePath: "assets/images/background.png",
                        borderRadius: 20,
                      ),
                      if (isAvatarSpeaking)
                        AnimatedBuilder(
                          animation: _speakingController,
                          builder: (context, child) {
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.orange.withOpacity(0.1 * _speakingController.value),
                                    Colors.transparent,
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                
                // Control buttons overlay
Positioned(
  bottom: 12,
  left: 12,
  right: 12,
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      _AvatarControlButton(
        icon: isAvatarMinimized ? Icons.fullscreen : Icons.fullscreen_exit,
        onPressed: _toggleAvatarSize,
      ),
      _AvatarControlButton(
        icon: isMuted ? Icons.volume_off : Icons.volume_up,
        onPressed: _toggleMute,
      ),
    ],
  ),
),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    bool isUser = message['isUser'];
    String? text = message['text'];
    bool? isCorrect = message['isCorrect'];

    Color bgColor;
    if (isCorrect == true) {
      bgColor = Colors.green.shade100;
    } else if (isCorrect == false) {
      bgColor = Colors.red.shade300;
    } else if (isUser) {
      bgColor = const Color(0xFFFFFDE7);
    } else {
      bgColor = Colors.transparent;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: isUser ? MainAxisAlignment.start : MainAxisAlignment.end,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser || isCorrect != null ? bgColor : null,
                      gradient: !isUser && isCorrect == null
                          ? const LinearGradient(
                              colors: [Color(0xFFFF609D), Color(0xFFFF7A06)],
                            )
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        if (isCorrect != null)
                          BoxShadow(
                            color: (isCorrect ? Colors.green : Colors.red).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCorrect != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(
                              isCorrect ? Icons.check_circle : Icons.cancel,
                              color: isCorrect ? Colors.green.shade700 : Colors.white,
                              size: 20,
                            ),
                          ),
                        Flexible(
                          child: Text(
                            text ?? '',
                            style: TextStyle(
                              color: isUser || isCorrect == false 
                                  ? Colors.black87 
                                  : isCorrect == true 
                                      ? Colors.green.shade900 
                                      : Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
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
        );
      },
    );
  }

Widget _buildMultipleChoiceOptions() {
    List<Map<String, dynamic>> options = [
      {'text': 'Cat', 'isCorrect': true},
      {'text': 'Cap', 'isCorrect': false},
      {'text': 'Can', 'isCorrect': false},
      {'text': 'Car', 'isCorrect': false},
    ];

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // First row with 2 buttons
            Row(
              children: [
                Expanded(
                  child: _AnimatedOptionButton(
                    text: options[0]['text'],
                    onPressed: () => _checkAnswer(options[0]['text'], options[0]['isCorrect']),
                    delay: const Duration(milliseconds: 100),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _AnimatedOptionButton(
                    text: options[1]['text'],
                    onPressed: () => _checkAnswer(options[1]['text'], options[1]['isCorrect']),
                    delay: const Duration(milliseconds: 200),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Second row with 2 buttons
            Row(
              children: [
                Expanded(
                  child: _AnimatedOptionButton(
                    text: options[2]['text'],
                    onPressed: () => _checkAnswer(options[2]['text'], options[2]['isCorrect']),
                    delay: const Duration(milliseconds: 300),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _AnimatedOptionButton(
                    text: options[3]['text'],
                    onPressed: () => _checkAnswer(options[3]['text'], options[3]['isCorrect']),
                    delay: const Duration(milliseconds: 400),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Continue button
            _AnimatedContinueButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  _createFadeRoute(const LanguageLevelPage()),
                );
              },
              delay: const Duration(milliseconds: 500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomInput() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showWaveform && isRecording)
            AnimatedBuilder(
              animation: _waveformController,
              builder: (context, child) {
                return Container(
                  height: 50,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(30, (index) {
                      double baseHeight = 8 + (index % 5) * 3;
                      double animatedHeight = baseHeight + 
                          (math.sin((index / 30 * 2 * math.pi) + 
                          (_waveformController.value * 2 * math.pi)) * 8);
                      
                      return Container(
                        width: 3,
                        height: animatedHeight.clamp(8.0, 40.0),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF609D), Color(0xFFFF7A06)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                );
              },
            ),
          
          if (showRecordingControls)
            _buildRecordingControls(),
          
          if (!showRecordingControls)
            Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        width: 2,
                        color: const Color(0xFFFF609D),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF609D).withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'Type your response',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                if (showSendButton)
                  _AnimatedCircleButton(
                    icon: Icons.send,
                    onPressed: _sendMessage,
                  )
                else
                  _AnimatedMicButton(
                    isRecording: isRecording,
                    onStartRecording: _startRecording,
                    onStopRecording: _stopRecording,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRecordingControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Text(
            recordedText ?? '',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _RecordingActionButton(
                icon: Icons.delete_outline,
                label: 'Delete',
                color: Colors.red,
                onPressed: _cancelRecording,
              ),
              _RecordingActionButton(
                icon: Icons.check,
                label: 'Send',
                color: Colors.green,
                onPressed: _approveRecording,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Custom Animated Widgets

class _AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _AnimatedIconButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  State<_AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<_AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: IconButton(
        icon: Icon(widget.icon, color: widget.color, size: 20),
        padding: EdgeInsets.zero,
        onPressed: () async {
          HapticFeedback.lightImpact();
          await _controller.forward();
          await _controller.reverse();
          widget.onPressed();
        },
      ),
    );
  }
}

class _AvatarControlButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _AvatarControlButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  State<_AvatarControlButton> createState() => _AvatarControlButtonState();
}

class _AvatarControlButtonState extends State<_AvatarControlButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: () async {
          HapticFeedback.mediumImpact();
          await _controller.forward();
          await _controller.reverse();
          widget.onPressed();
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF609D), Color(0xFFFF7A06)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF609D).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            widget.icon,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _AnimatedOptionButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Duration delay;

  const _AnimatedOptionButton({
    required this.text,
    required this.onPressed,
    this.delay = Duration.zero,
  });

  @override
  State<_AnimatedOptionButton> createState() => _AnimatedOptionButtonState();
}

class _AnimatedOptionButtonState extends State<_AnimatedOptionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTapDown: (_) {
            setState(() => _isPressed = true);
          },
          onTapUp: (_) {
            setState(() => _isPressed = false);
            HapticFeedback.lightImpact();
            widget.onPressed();
          },
          onTapCancel: () {
            setState(() => _isPressed = false);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isPressed ? const Color(0xFFFF609D) : Colors.grey.shade300,
                width: _isPressed ? 2 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isPressed 
                      ? const Color(0xFFFF609D).withOpacity(0.2)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: _isPressed ? 12 : 8,
                  offset: Offset(0, _isPressed ? 4 : 2),
                ),
              ],
            ),
            transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
            child: Center(
              child: Text(
                widget.text,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _isPressed ? const Color(0xFFFF609D) : Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedCircleButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _AnimatedCircleButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  State<_AnimatedCircleButton> createState() => _AnimatedCircleButtonState();
}

class _AnimatedCircleButtonState extends State<_AnimatedCircleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: () async {
          HapticFeedback.mediumImpact();
          await _controller.forward();
          await _controller.reverse();
          widget.onPressed();
        },
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF609D), Color(0xFFFF7A06)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF609D).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            widget.icon,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _AnimatedMicButton extends StatefulWidget {
  final bool isRecording;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;

  const _AnimatedMicButton({
    required this.isRecording,
    required this.onStartRecording,
    required this.onStopRecording,
  });

  @override
  State<_AnimatedMicButton> createState() => _AnimatedMicButtonState();
}

class _AnimatedMicButtonState extends State<_AnimatedMicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    if (widget.isRecording) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_AnimatedMicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !oldWidget.isRecording) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => widget.onStartRecording(),
      onLongPressEnd: (_) => widget.onStopRecording(),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            width: 52 + (_pulseController.value * 8),
            height: 52 + (_pulseController.value * 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF609D), Color(0xFFFF7A06)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF609D).withOpacity(
                    0.4 + (_pulseController.value * 0.2),
                  ),
                  blurRadius: 12 + (_pulseController.value * 8),
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              widget.isRecording ? Icons.stop : Icons.mic,
              color: Colors.white,
              size: 24,
            ),
          );
        },
      ),
    );
  }
}

class _RecordingActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _RecordingActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  State<_RecordingActionButton> createState() => _RecordingActionButtonState();
}

class _RecordingActionButtonState extends State<_RecordingActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: () async {
          HapticFeedback.mediumImpact();
          await _controller.forward();
          await _controller.reverse();
          widget.onPressed();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Error Dialog Widget
class _ErrorDialog extends StatefulWidget {
  final String correctAnswer;

  const _ErrorDialog({required this.correctAnswer});

  @override
  State<_ErrorDialog> createState() => _ErrorDialogState();
}

class _ErrorDialogState extends State<_ErrorDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: 0.0), weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_shakeAnimation.value, 0),
            child: child,
          );
        },
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFF6B6B).withOpacity(0.9), // Lighter red
                        const Color(0xFFFF8E8E).withOpacity(0.9), // Even lighter red
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    "It's incorrect.",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'The right answer is',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.correctAnswer,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF609D), Color(0xFFFF7A06)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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
          ),
        ),
      ),
    );
  }
}

// Success Dialog Widget
class _SuccessDialog extends StatefulWidget {
  final String answer;

  const _SuccessDialog({required this.answer});

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();

    // Play success sound effect (implement with audio player)
    // Auto close after 1.5 seconds
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 60,
                  color: Colors.green.shade600,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Correct!",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.answer,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Continue Button Widget
class _AnimatedContinueButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Duration delay;

  const _AnimatedContinueButton({
    required this.onPressed,
    this.delay = Duration.zero,
  });

  @override
  State<_AnimatedContinueButton> createState() => _AnimatedContinueButtonState();
}

class _AnimatedContinueButtonState extends State<_AnimatedContinueButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            HapticFeedback.mediumImpact();
            widget.onPressed();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF609D), Color(0xFFFF7A06)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF609D).withOpacity(_isPressed ? 0.3 : 0.4),
                  blurRadius: _isPressed ? 8 : 12,
                  offset: Offset(0, _isPressed ? 3 : 5),
                ),
              ],
            ),
            transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
            child: const Center(
              child: Text(
                'Continue',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// LanguageLevelPage Widget (unchanged but with improved animations)
class LanguageLevelPage extends StatelessWidget {
  const LanguageLevelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Test result',
          style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w500),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Opacity(
                            opacity: value,
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          const Text(
                            'Your language level',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'B1',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF7043),
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    const RadarChartWidget(),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: _AnimatedStartButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedStartButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _AnimatedStartButton({required this.onPressed});

  @override
  State<_AnimatedStartButton> createState() => _AnimatedStartButtonState();
}

class _AnimatedStartButtonState extends State<_AnimatedStartButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF609D), Color(0xFFFF7A06)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF609D).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: ElevatedButton(
            onPressed: () async {
              HapticFeedback.mediumImpact();
              await _controller.forward();
              await _controller.reverse();
              widget.onPressed();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Start Now',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RadarChartWidget extends StatelessWidget {
  const RadarChartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return SizedBox(
          width: 320,
          height: 320,
          child: CustomPaint(
            painter: RadarChartPainter(animationValue: value),
          ),
        );
      },
    );
  }
}

class RadarChartPainter extends CustomPainter {
  final double animationValue;
  
  RadarChartPainter({this.animationValue = 1.0});
  
  final List<String> labels = [
    'Grammar\n20%',
    'Speaking\n30%',
    'Listening\n15%',
    'Conversation\n25%',
    'Vocabulary\n10%',
  ];

  final List<double> values = [20, 30, 15, 25, 10];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 60;
    final sides = 5;
    final angle = (2 * math.pi) / sides;

    final bgPaint = Paint()
      ..color = const Color(0xFFFFF9C4).withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius + 20, bgPaint);

    final webPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int level = 1; level <= 5; level++) {
      final levelRadius = (radius * level) / 5;
      final path = Path();
      for (int i = 0; i < sides; i++) {
        final x = center.dx + levelRadius * math.cos(angle * i - math.pi / 2);
        final y = center.dy + levelRadius * math.sin(angle * i - math.pi / 2);
        i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      path.close();
      canvas.drawPath(path, webPaint);
    }

    final linePaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < sides; i++) {
      final x = center.dx + radius * math.cos(angle * i - math.pi / 2);
      final y = center.dy + radius * math.sin(angle * i - math.pi / 2);
      canvas.drawLine(center, Offset(x, y), linePaint);
    }

    final dataPath = Path();
    final dataPaint = Paint()
      ..color = const Color(0xFFFFB74D).withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final dataBorderPaint = Paint()
      ..color = const Color(0xFFFF9800)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < sides; i++) {
      final percentage = (values[i] / 100) * animationValue;
      final dataRadius = radius * percentage;
      final x = center.dx + dataRadius * math.cos(angle * i - math.pi / 2);
      final y = center.dy + dataRadius * math.sin(angle * i - math.pi / 2);
      i == 0 ? dataPath.moveTo(x, y) : dataPath.lineTo(x, y);
    }
    dataPath.close();
    canvas.drawPath(dataPath, dataPaint);
    canvas.drawPath(dataPath, dataBorderPaint);

    final pointPaint = Paint()..color = const Color(0xFFFF9800);
    for (int i = 0; i < sides; i++) {
      final percentage = (values[i] / 100) * animationValue;
      final dataRadius = radius * percentage;
      final x = center.dx + dataRadius * math.cos(angle * i - math.pi / 2);
      final y = center.dy + dataRadius * math.sin(angle * i - math.pi / 2);
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }

    final textStyle = const TextStyle(
      color: Color(0xFF757575),
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );

    for (int i = 0; i < sides; i++) {
      final labelRadius = radius + 35;
      final x = center.dx + labelRadius * math.cos(angle * i - math.pi / 2);
      final y = center.dy + labelRadius * math.sin(angle * i - math.pi / 2);

      final textPainter = TextPainter(
        text: TextSpan(text: labels[i], style: textStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      double offsetX = x - textPainter.width / 2;
      double offsetY = y - textPainter.height / 2;

      if (i == 0) offsetY -= 10;
      else if (i == 1) { offsetX += 5; offsetY -= 5; }
      else if (i == 2) { offsetX += 5; offsetY += 5; }
      else if (i == 3) { offsetX -= 5; offsetY += 5; }
      else if (i == 4) { offsetX -= 5; offsetY -= 5; }

      textPainter.paint(canvas, Offset(offsetX, offsetY));
    }
  }

  @override
  bool shouldRepaint(RadarChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }

  
}
// Viseme data model
class VisemeData {
  final String name;
  final double startTime;
  final double endTime;

  VisemeData(this.name, this.startTime, this.endTime);
}