import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:language_app/app/constants/app_constants.dart';
import 'package:language_app/core/providers/avatar_provider.dart';
import 'package:language_app/features/avatar/avatar_controller.dart';
import 'package:language_app/features/avatar/avatar_view.dart';
import 'package:language_app/features/home/free/free_conversation.dart';
import 'package:provider/provider.dart';

import 'package:language_app/core/providers/theme_provider.dart';

class FreeVocabularyChat extends StatefulWidget {
  final String selectedAvatarName;

  const FreeVocabularyChat({super.key, required this.selectedAvatarName});

  @override
  State<FreeVocabularyChat> createState() => _FreeVocabularyChatState();
}

class _FreeVocabularyChatState extends State<FreeVocabularyChat>
    with TickerProviderStateMixin {
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

  Map<String, List<VisemeData>> visemeMap = {};

  String get selectedAvatarName =>
      Provider.of<AvatarProvider>(context, listen: false).selectedAvatarName;

  late AnimationController _shakeController;
  late AnimationController _correctController;
  late AnimationController _buttonScaleController;
  late Animation<Color?> _correctColorAnimation;

  late Animation<double> _shakeAnimation;
  late Animation<double> _correctScaleAnimation;

  @override
  void initState() {
    super.initState();
    avatarController = AvatarController();
    _initAnimations();
    _initTts();
    _loadVisemeData();

    // ✅ NEW: Land logic - speak correctAnswer as hint for multiple_choice
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          final currentQuestion = questions[currentQuestionIndex];
          if (currentQuestion['type'] == 'multiple_choice') {
            _speak(currentQuestion['correctAnswer']);
          } else if (currentQuestion['type'] == 'fill_blank') {
            String sentence = currentQuestion['question'];
            sentence = sentence.replaceAll('_____', '');
            _speak(sentence.trim());
          }
        }
      });
    });
  }

  Future<void> _loadVisemeData() async {
    try {
      final String data = await rootBundle.loadString('test/data/viseme.txt');
      _parseVisemeData(data);
    } catch (e) {
      print('Error loading viseme data: $e');
    }
  }

  void _parseVisemeData(String data) {
    final lines = data.split('\n');
    String? currentWord;
    List<VisemeData> currentVisemes = [];

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      if (!line.startsWith('(')) {
        if (currentWord != null && currentVisemes.isNotEmpty) {
          visemeMap[currentWord.toLowerCase()] = List.from(currentVisemes);
        }
        currentWord = line;
        currentVisemes.clear();
      } else {
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

    if (currentWord != null && currentVisemes.isNotEmpty) {
      visemeMap[currentWord.toLowerCase()] = currentVisemes;
    }
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

    _buttonScaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
  }

  Future<void> _initTts() async {
    flutterTts = FlutterTts();
    await flutterTts.setLanguage("en-US");

    if (widget.selectedAvatarName.toLowerCase() == 'karl') {
      if (Platform.isAndroid) {
        await flutterTts.setVoice({
          "name": "en-us-x-tpd-local",
          "locale": "en-US",
        });
      } else if (Platform.isIOS) {
        await flutterTts.setVoice({
          "name": "com.apple.ttsbundle.Daniel-compact",
          "locale": "en-US",
        });
      }
    } else {
      if (Platform.isAndroid) {
        await flutterTts.setVoice({
          "name": "en-us-x-tpf-local",
          "locale": "en-US",
        });
      } else if (Platform.isIOS) {
        await flutterTts.setVoice({
          "name": "com.apple.ttsbundle.Samantha-compact",
          "locale": "en-US",
        });
      }
    }

    await flutterTts.setSpeechRate(0.4);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);

    flutterTts.setStartHandler(() {
      if (mounted) setState(() => isAvatarSpeaking = true);
    });

    flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => isAvatarSpeaking = false);
    });

    flutterTts.setErrorHandler((msg) {
      if (mounted) setState(() => isAvatarSpeaking = false);
    });

    flutterTts.setCancelHandler(() {
      if (mounted) setState(() => isAvatarSpeaking = false);
    });
  }

  Future<void> _speak(String text) async {
    if (!isMuted) {
      await flutterTts.stop();
      await Future.delayed(const Duration(milliseconds: 100));
      _startLipSync(text);
      await flutterTts.speak(text);
    }
  }

  void _startLipSync(String text) {
    final words = text.toLowerCase().split(' ');
    double currentOffset = 0.0;

    for (var word in words) {
      word = word.replaceAll(RegExp(r'[^\wäöüß\s]', unicode: true), '').trim();
      if (word.isEmpty) continue;

      String? lookupWord = word;
      if (!visemeMap.containsKey(lookupWord)) {
        lookupWord = word
            .replaceAll('ä', 'a')
            .replaceAll('ö', 'o')
            .replaceAll('ü', 'u')
            .replaceAll('ß', 'ss');
      }

      if (visemeMap.containsKey(lookupWord)) {
        final visemes = visemeMap[lookupWord]!;
        double wordMaxEnd = 0.0;

        for (var viseme in visemes) {
          final delay = ((currentOffset + viseme.startTime) * 1000).toInt();
          final duration = (viseme.endTime - viseme.startTime);
          if (viseme.endTime > wordMaxEnd) wordMaxEnd = viseme.endTime;

          Future.delayed(Duration(milliseconds: delay), () {
            if (mounted && isAvatarSpeaking) {
              avatarController.triggerViseme(viseme.name, duration: duration);
            }
          });
        }
        currentOffset += wordMaxEnd + 0.05; // Gap between words
      } else {
        currentOffset += 0.4; // Fallback duration for unknown words
      }
    }
  }

  Future<void> _stop() async {
    await flutterTts.stop();
    await avatarController.stopHandWave();
    if (mounted) setState(() => isAvatarSpeaking = false);
  }

  void _toggleMute() {
    setState(() => isMuted = !isMuted);
    if (isMuted) _stop();
  }

  void _toggleAvatarSize() {
    setState(() => isAvatarMaximized = !isAvatarMaximized);
  }

  // ✅ NEW: Repeat button function
  void _repeatCorrectAnswer() {
    final currentQuestion = questions[currentQuestionIndex];
    if (currentQuestion['type'] == 'fill_blank') {
      String sentence = currentQuestion['question'];
      sentence = sentence.replaceAll('_____', '');
      _speak(sentence.trim());
    } else {
      String correctAnswer = currentQuestion['correctAnswer'];
      _speak(correctAnswer);
    }
  }

  final List<Map<String, dynamic>> questions = [
    {
      'type': 'multiple_choice',
      'question': null,
      'correctAnswer': 'Cat',
      'options': [
        {
          'text': 'Car',
          'textColor': const Color(0xFFFF8000),
          'bgColor': const Color(0xFFFFF6ED),
          'borderColor': const Color(0xFFFF8000),
        },
        {
          'text': 'Cap',
          'textColor': const Color(0xFFFF8000),
          'bgColor': const Color(0xFFFFF6ED),
          'borderColor': const Color(0xFFFF8000),
        },
        {
          'text': 'Cat',
          'textColor': const Color(0xFFFF8000),
          'bgColor': const Color(0xFFFFF6ED),
          'borderColor': const Color(0xFFFF8000),
        },
        {
          'text': 'Can',
          'textColor': const Color(0xFFFF8000),
          'bgColor': const Color(0xFFFFF6ED),
          'borderColor': const Color(0xFFFF8000),
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
          'textColor': const Color(0xFFFF8000),
          'bgColor': const Color(0xFFFFF6ED),
          'borderColor': const Color(0xFFFF8000),
        },
        {
          'text': 'Frisst',
          'textColor': const Color(0xFFFF8000),
          'bgColor': const Color(0xFFFFF6ED),
          'borderColor': const Color(0xFFFF8000),
        },
        {
          'text': 'Hähnchen',
          'textColor': const Color(0xFFFF8000),
          'bgColor': const Color(0xFFFFF6ED),
          'borderColor': const Color(0xFFFF8000),
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
  //  ✅ CHANGED: Option click এ আর কথা বলবে না
  // void handleOptionTap(String option) {
  //   setState(() {
  //     selectedOption = option;
  //   });

  //   // ✅ NEW: Both types এ option click করলে সেই word বলবে
  //   final currentQuestion = questions[currentQuestionIndex];
  //   _speak(option);
  // }

  //✅ CHANGED: Option click এ আর কথা বলবে না
  void handleOptionTap(String option) {
    setState(() {
      selectedOption = option;
    });

    // ✅ NEW: fill_blank question এ option click করলে সেই word বলবে
    final currentQuestion = questions[currentQuestionIndex];
    if (currentQuestion['type'] == 'fill_blank') {
      _speak(option); // "Katze", "Frisst", "Hähnchen", "Die" বলবে
    }
  }

  void handleContinue() {
    if (selectedOption == null) return;
    String correctAnswer = questions[currentQuestionIndex]['correctAnswer'];
    final currentQuestion = questions[currentQuestionIndex];

    if (!showError) {
      if (selectedOption != correctAnswer) {
        setState(() {
          showError = true;
          HapticFeedback.heavyImpact();
          _shakeController.forward().then((_) => _shakeController.reverse());
        });
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted && showError) {
            _stop().then((_) => _speak("The right answer is $correctAnswer"));
          }
        });
      } else {
        _correctController.forward();
        HapticFeedback.mediumImpact();
        SystemSound.play(SystemSoundType.click);
        _speak("Well done");

        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            if (currentQuestionIndex < questions.length - 1) {
              setState(() {
                currentQuestionIndex++;
                selectedOption = null;
                showError = false;
                showTranslation = false;
                _correctController.reset();
              });

              // ✅ NEW: Next question logic
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  final nextQuestion = questions[currentQuestionIndex];
                  if (nextQuestion['type'] == 'multiple_choice') {
                    _speak(nextQuestion['correctAnswer']);
                  } else if (nextQuestion['type'] == 'fill_blank') {
                    String sentence = nextQuestion['question'];
                    sentence = sentence.replaceAll('_____', '');
                    _speak(sentence.trim());
                  }
                }
              });
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => FreeConversationChat(
                    selectedAvatarName: widget.selectedAvatarName,
                  ),
                ),
              );
            }
          }
        });
      }
    } else {
      setState(() {
        showError = false;
        selectedOption = null;
      });
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _correctController.dispose();
    _buttonScaleController.dispose();
    flutterTts.stop();
    avatarController.stopHandWave();
    avatarController.disposeView();
    super.dispose();
  }

  String _translateText(String text) {
    final translations = {'Die Katze frisst _____': 'The cat eats _____'};
    return translations[text] ?? 'Translation not available';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final currentQuestion = questions[currentQuestionIndex];
    final questionType = currentQuestion['type'];
    final questionText = currentQuestion['question'];
    final options = currentQuestion['options'] as List<Map<String, dynamic>>;
    final correctAnswer = currentQuestion['correctAnswer'];
    final themeColor = themeProvider.getAvatarTheme(widget.selectedAvatarName);

    return Scaffold(
      backgroundColor: themeProvider.scaffoldBackgroundColor,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: themeProvider.appBarColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: themeProvider.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.fastOutSlowIn,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                height: isAvatarMaximized ? 400 : 320,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [themeColor, themeColor.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      AvatarView(
                        avatarName: widget.selectedAvatarName,
                        controller: avatarController,
                        height: isAvatarMaximized ? 540 : 380,
                        backgroundImagePath: AppConstants.backgroundImage,
                        borderRadius: 24,
                      ),
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
                              const SizedBox(width: 12),
                              // ✅ NEW UI: Buttons
                              Row(
                                children: [
                                  _buildCircleAction(
                                    icon: Icons.repeat,
                                    onTap: _repeatCorrectAnswer,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildCircleAction(
                                    icon: isMuted
                                        ? Icons.volume_off
                                        : Icons.volume_up,
                                    onTap: _toggleMute,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildCircleAction(
                                    icon: isAvatarMaximized
                                        ? Icons.fullscreen_exit
                                        : Icons.fullscreen,
                                    onTap: _toggleAvatarSize,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isAvatarMaximized && isAvatarSpeaking)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
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
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Choose the Correct Answer",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
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
                      offset: Offset(
                        _shakeAnimation.value *
                            ((_shakeController.value * 4).floor() % 2 == 0
                                ? 1
                                : -1),
                        0,
                      ),
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
                              margin: const EdgeInsets.fromLTRB(
                                12,
                                0,
                                12,
                                12,
                              ),
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
                                          colors: [
                                            Color(0xFFFF609D),
                                            Color(0xFFFF7A06),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          8,
                                        ),
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

  Widget _buildFillBlankLayout(
    String? questionText,
    List<Map<String, dynamic>> options,
  ) {
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
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(child: _buildOptionButton(options[0], 60, false)),
              const SizedBox(width: 12),
              Expanded(child: _buildOptionButton(options[1], 60, false)),
              const SizedBox(width: 12),
              Expanded(child: _buildOptionButton(options[2], 60, false)),
              const SizedBox(width: 12),
              Expanded(child: _buildOptionButton(options[3], 60, false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(
    Map<String, dynamic> option,
    double height, [
    bool isSmallText = false,
  ]) {
    // Wrapped in AnimatedBuilder to listen for controller changes
    return AnimatedBuilder(
      animation: _correctController,
      builder: (context, child) {
        final isSelected = selectedOption == option['text'];

        // Logic updated to ensure it stays green if animation completes (status == completed)
        final isCorrectAndValidated = selectedOption == option['text'] &&
            selectedOption ==
                questions[currentQuestionIndex]['correctAnswer'] &&
            (_correctController.status == AnimationStatus.forward ||
                _correctController.status == AnimationStatus.completed);

        // Determine explicit colors based on animation state
        // If validated, use the animation value (White -> Green)
        // If not, use standard selection logic
        final Color effectiveBgColor = isCorrectAndValidated
            ? (_correctColorAnimation.value ?? const Color(0xFF4CAF50))
            : (isSelected ? option['textColor'] : option['bgColor']);

        final Color effectiveBorderColor = isCorrectAndValidated
            ? (_correctColorAnimation.value ?? const Color(0xFF4CAF50))
            : (isSelected
                ? option['textColor'].withOpacity(0.5)
                : option['borderColor']);

        return GestureDetector(
          onTap: () => handleOptionTap(option['text']),
          child: Transform.scale(
            // Apply the scale animation here
            scale: isCorrectAndValidated ? _correctScaleAnimation.value : 1.0,
            child: AnimatedContainer(
              // If we are animating the blink, set duration to zero so it follows the controller exactly.
              // Otherwise, use 300ms for smooth selection transitions.
              duration: isCorrectAndValidated
                  ? Duration.zero
                  : const Duration(milliseconds: 300),
              height: height,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: effectiveBgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: effectiveBorderColor,
                  width: 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color:
                              (option['textColor'] as Color).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  option['text'],
                  style: TextStyle(
                    color: isSelected || isCorrectAndValidated
                        ? Colors.white
                        : option['textColor'],
                    fontSize: isSmallText ? 12 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCircleAction({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: Colors.white24,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}

class VisemeData {
  final String name;
  final double startTime;
  final double endTime;
  VisemeData(this.name, this.startTime, this.endTime);
}
