import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:language_app/avatar/avatar_controller.dart';
import 'package:language_app/avatar/avatar_view.dart';
import 'package:language_app/Screens/test_conversation.dart';

class TestVocabularyPage extends StatefulWidget {
  final String selectedAvatar;
  
  const TestVocabularyPage({
    super.key,
    required this.selectedAvatar,
  });

  @override
  State<TestVocabularyPage> createState() => _TestVocabularyPageState();
}

class _TestVocabularyPageState extends State<TestVocabularyPage> with TickerProviderStateMixin {
  int currentQuestionIndex = 0;
  String? selectedOption;
  bool showError = false;
  bool isMuted = false;
  bool isAvatarMaximized = true;
  bool isAvatarSpeaking = false;
  String translatedText = '';
  bool showTranslation = false;
  
  late FlutterTts flutterTts;
  late AvatarController avatarController;
  
  // Viseme data
  Map<String, List<VisemeData>> visemeMap = {};
  
  // Animation Controllers
  late AnimationController _shakeController;
  late AnimationController _correctController;
  late AnimationController _avatarController;
  late AnimationController _buttonScaleController;
  
  late Animation<double> _shakeAnimation;
  late Animation<double> _correctScaleAnimation;
  late Animation<Color?> _correctColorAnimation;
  late Animation<double> _avatarSizeAnimation;

  @override
  void initState() {
    super.initState();
    avatarController = AvatarController();
    _initAnimations();
    _initTts();
    _loadVisemeData();
  }

  // Load viseme data from file
  Future<void> _loadVisemeData() async {
    try {
      final String data = await rootBundle.loadString('test/data/viseme.txt');
      _parseVisemeData(data);
    } catch (e) {
      print('Error loading viseme data: $e');
    }
  }

  // Parse viseme data
  void _parseVisemeData(String data) {
    final lines = data.split('\n');
    String? currentWord;
    List<VisemeData> currentVisemes = [];

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // Check if it's a word line (doesn't start with parenthesis)
      if (!line.startsWith('(')) {
        if (currentWord != null && currentVisemes.isNotEmpty) {
          visemeMap[currentWord.toLowerCase()] = List.from(currentVisemes);
        }
        currentWord = line;
        currentVisemes.clear();
      } else {
        // Parse viseme line: ('viseme_PP', 0.03, 0.07)
        final regex = RegExp(r"\('([^']+)',\s*([\d.]+),\s*([\d.]+)\)");
        final match = regex.firstMatch(line);
        if (match != null) {
          final visemeName = match.group(1)!;
          final startTime = double.parse(match.group(2)!);
          final endTime = double.parse(match.group(3)!);
          currentVisemes.add(VisemeData(visemeName, startTime, endTime));
        }
      }
    }

    // Add last word
    if (currentWord != null && currentVisemes.isNotEmpty) {
      visemeMap[currentWord.toLowerCase()] = currentVisemes;
    }

    print('Loaded viseme data for ${visemeMap.length} words');
  }

  void _initAnimations() {
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _correctController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _correctScaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _correctController, curve: Curves.easeOut),
    );
    _correctColorAnimation = ColorTween(
      begin: Colors.white,
      end: const Color(0xFF4CAF50),
    ).animate(_correctController);

    _avatarController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _avatarSizeAnimation = Tween<double>(begin: 380, end: 180).animate(
      CurvedAnimation(parent: _avatarController, curve: Curves.easeInOut),
    );

    _buttonScaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
  }

Future<void> _initTts() async {
  flutterTts = FlutterTts();
  
  // Set language and speech parameters
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
    if (mounted) {
      setState(() => isAvatarSpeaking = true);
    }
  });

  flutterTts.setCompletionHandler(() {
    if (mounted) {
      setState(() => isAvatarSpeaking = false);
    }
  });

  flutterTts.setErrorHandler((msg) {
    print('TTS Error: $msg');
    if (mounted) {
      setState(() => isAvatarSpeaking = false);
    }
  });
  
  flutterTts.setCancelHandler(() {
    if (mounted) {
      setState(() => isAvatarSpeaking = false);
    }
  });
}

  Future<void> _speak(String text) async {
    if (!isMuted) {
      await flutterTts.stop();
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Start lip sync animation BEFORE speaking
      print('🎤 Speaking: $text');
      _startLipSync(text);
      
      // Speak with await to ensure it completes
      var result = await flutterTts.speak(text);
      if (result == 1) {
        print('✅ TTS started successfully');
      } else {
        print('❌ TTS failed to start: $result');
      }
    }
  }

  // Start lip sync based on viseme data
  void _startLipSync(String text) {
    final words = text.toLowerCase().split(' ');
    print('📝 Words to sync: $words');
    
    for (var word in words) {
      // Remove punctuation
      word = word.replaceAll(RegExp(r'[^\w\s]'), '');
      
      print('🔍 Looking for viseme data: "$word"');
      
      if (visemeMap.containsKey(word)) {
        final visemes = visemeMap[word]!;
        print('✅ Found ${visemes.length} visemes for "$word"');
        
        // Play each viseme with proper timing
        for (var viseme in visemes) {
          final delay = (viseme.startTime * 1000).toInt();
          final duration = (viseme.endTime - viseme.startTime);
          
          print('⏱️ Scheduling ${viseme.name} at ${delay}ms for ${duration}s');
          
          Future.delayed(Duration(milliseconds: delay), () {
            if (mounted && isAvatarSpeaking) {
              print('🎭 Playing viseme: ${viseme.name}');
              avatarController.triggerViseme(viseme.name, duration: duration);
            }
          });
        }
      } else {
        print('❌ No viseme data found for "$word"');
        print('📋 Available words: ${visemeMap.keys.toList()}');
      }
    }
  }

  Future<void> _stop() async {
    await flutterTts.stop();
    setState(() => isAvatarSpeaking = false);
  }

  void _toggleMute() {
    setState(() => isMuted = !isMuted);
    if (isMuted) _stop();
  }

  void _toggleAvatarSize() {
    setState(() {
      isAvatarMaximized = !isAvatarMaximized;
      if (isAvatarMaximized) {
        _avatarController.reverse();
      } else {
        _avatarController.forward();
      }
    });
  }

  Future<void> _playCorrectSound() async {
    try {
      await SystemSound.play(SystemSoundType.click);
      HapticFeedback.mediumImpact();
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  void _vibratePhone() {
    HapticFeedback.heavyImpact();
  }

  String _translateText(String text) {
    final translations = {
      'Die Katze frisst _____': 'The cat eats _____',
    };
    return translations[text] ?? 'Translation not available';
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _correctController.dispose();
    _avatarController.dispose();
    _buttonScaleController.dispose();
    flutterTts.stop();
    avatarController.disposeView();
    super.dispose();
  }

  final List<Map<String, dynamic>> questions = [
    {
      'type': 'multiple_choice',
      'question': null,
      'correctAnswer': 'Cat',
      'options': [
        {
          'text': 'Car',
          'textColor': const Color(0xFFFF6291),
          'bgColor': const Color(0xFFFFF0F4),
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
          'textColor': const Color(0xFFFF6666),
          'bgColor': const Color(0xFFFFF0F0),
          'borderColor': const Color(0xFFFF6666),
        },
        {
          'text': 'Can',
          'textColor': const Color(0xFFFF66CC),
          'bgColor': const Color(0xFFFFF0F9),
          'borderColor': const Color(0xFFFF66CC),
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
          'bgColor': const Color(0xFFFFF0F4),
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
          'textColor': const Color(0xFFFF6666),
          'bgColor': const Color(0xFFFFF0F0),
          'borderColor': const Color(0xFFFF6666),
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
    // Prevent multiple taps on the same option or when error is showing
    if (showError || selectedOption == option) return;
    
    setState(() {
      selectedOption = option;
      String correctAnswer = questions[currentQuestionIndex]['correctAnswer'];
      
      _speak(option);
      
      if (option != correctAnswer) {
        showError = true;
        _vibratePhone();
        _shakeController.forward().then((_) => _shakeController.reverse());
        
        // Speak correct answer once after delay
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted && showError) {
            _speakCorrectAnswer(correctAnswer);
          }
        });
      } else {
        _correctController.forward();
        _playCorrectSound();
      }
    });
  }

  void handleContinue() {
    String correctAnswer = questions[currentQuestionIndex]['correctAnswer'];
    
    if (selectedOption == correctAnswer) {
      if (currentQuestionIndex < questions.length - 1) {
        setState(() {
          currentQuestionIndex++;
          selectedOption = null;
          showError = false;
          showTranslation = false;
          _correctController.reset();
        });
      } else {
        Navigator.pushReplacement(
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

  void _speakCorrectAnswer(String answer) {
    // Stop any ongoing speech first
    _stop().then((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _speak("The right answer is $answer");
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = questions[currentQuestionIndex];
    final questionType = currentQuestion['type'];
    final questionText = currentQuestion['question'];
    final options = currentQuestion['options'] as List<Map<String, dynamic>>;
    final correctAnswer = currentQuestion['correctAnswer'];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
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
                              _correctController.reset();
                            });
                          } else {
                            Navigator.pop(context);
                          }
                        },
                      ),
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
                ),

                const SizedBox(height: 4),

                AnimatedBuilder(
                  animation: _avatarSizeAnimation,
                  builder: (context, child) {
                    return GestureDetector(
                      onTap: _toggleAvatarSize,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        width: double.infinity,
                        height: _avatarSizeAnimation.value,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                transform: Matrix4.identity()
                                  ..scale(isAvatarSpeaking ? 1.05 : 1.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: _avatarSizeAnimation.value,
                                    child: AvatarView(
                                      avatarName: widget.selectedAvatar,
                                      controller: avatarController,
                                      height: _avatarSizeAnimation.value,
                                      backgroundImagePath: "assets/images/background.png",
                                      borderRadius: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (isAvatarSpeaking)
                              Positioned(
                                top: 10,
                                left: 10,
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.8, end: 1.2),
                                  duration: const Duration(milliseconds: 500),
                                  builder: (context, value, child) {
                                    return Transform.scale(
                                      scale: value,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF8000),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.volume_up,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Speaking...',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  onEnd: () {
                                    if (mounted && isAvatarSpeaking) {
                                      setState(() {});
                                    }
                                  },
                                ),
                              ),
                            Positioned(
                              bottom: 10,
                              right: 10,
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: _toggleAvatarSize,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Color(0xFFFF609D), Color(0xFFFF7A06)],
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isAvatarMaximized 
                                            ? Icons.minimize 
                                            : Icons.fullscreen,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: _toggleMute,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: isMuted 
                                            ? [Colors.grey.shade400, Colors.grey.shade600]
                                            : [const Color(0xFFFF609D), const Color(0xFFFF7A06)],
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isMuted ? Icons.volume_off : Icons.volume_up,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                Expanded(
                  child: questionType == 'multiple_choice' 
                    ? _buildMultipleChoiceLayout(options)
                    : _buildFillBlankLayout(questionText, options),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: GestureDetector(
                    onTap: handleContinue,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF609D), Color(0xFFFF7A06)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF609D).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
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

            if (showError)
              Container(
                color: Colors.black.withOpacity(0.6),
                child: Center(
                  child: AnimatedBuilder(
                    animation: _shakeAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_shakeAnimation.value * 
                          ((_shakeController.value * 4).floor() % 2 == 0 ? 1 : -1), 0),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 40),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6666),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
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
                                        color: Color(0xFFFF6666),
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    GestureDetector(
                                      onTap: () {
                                        _stop();
                                        setState(() => showError = false);
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        height: 46,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFFFF609D), Color(0xFFFF7A06)],
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
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultipleChoiceLayout(List<Map<String, dynamic>> options) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(child: _buildOptionButton(options[0], 80, false)),
              const SizedBox(width: 16),
              Expanded(child: _buildOptionButton(options[1], 80, false)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildOptionButton(options[2], 80, false)),
              const SizedBox(width: 16),
              Expanded(child: _buildOptionButton(options[3], 80, false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFillBlankLayout(String? questionText, List<Map<String, dynamic>> options) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  questionText ?? '',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (showTranslation) ...[
                  const SizedBox(height: 12),
                  Text(
                    translatedText,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          showTranslation = !showTranslation;
                          if (showTranslation && questionText != null) {
                            translatedText = _translateText(questionText);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8000).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.language,
                          size: 24,
                          color: Color(0xFFFF8000),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    GestureDetector(
                      onTap: () {
                        if (questionText != null) {
                          _speak(questionText);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF609D).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.volume_up,
                          size: 24,
                          color: Color(0xFFFF609D),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(child: _buildOptionButton(options[0], 60, true)),
              const SizedBox(width: 12),
              Expanded(child: _buildOptionButton(options[1], 60, true)),
              const SizedBox(width: 12),
              Expanded(child: _buildOptionButton(options[2], 60, true)),
              const SizedBox(width: 12),
              Expanded(child: _buildOptionButton(options[3], 60, true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(Map<String, dynamic> option, double height, [bool isSmallText = false]) {
    final isSelected = selectedOption == option['text'];
    final isCorrect = selectedOption == option['text'] && 
                      selectedOption == questions[currentQuestionIndex]['correctAnswer'];
    
    return GestureDetector(
      onTap: () => handleOptionTap(option['text']),
      child: AnimatedBuilder(
        animation: isCorrect ? _correctScaleAnimation : _shakeAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isCorrect ? _correctScaleAnimation.value : 1.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: height,
              decoration: BoxDecoration(
                color: isCorrect 
                    ? const Color(0xFF4CAF50)
                    : (isSelected 
                        ? option['textColor']
                        : option['bgColor']),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCorrect 
                      ? const Color(0xFF4CAF50)
                      : option['borderColor'],
                  width: 2,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: (option['textColor'] as Color).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ] : null,
              ),
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  option['text'],
                  style: TextStyle(
                    color: isSelected || isCorrect
                        ? Colors.white
                        : option['textColor'],
                    fontSize: isSmallText ? 14 : 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Viseme data model
class VisemeData {
  final String name;
  final double startTime;
  final double endTime;

  VisemeData(this.name, this.startTime, this.endTime);
}