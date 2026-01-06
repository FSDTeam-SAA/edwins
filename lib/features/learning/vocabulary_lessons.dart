import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:language_app/features/home/home_view.dart';
import 'package:provider/provider.dart';
import 'package:language_app/core/providers/avatar_provider.dart';
import 'package:language_app/features/avatar/avatar_controller.dart';
import 'package:language_app/features/avatar/avatar_view.dart';
import 'package:language_app/core/data/repository.dart';
import 'package:language_app/core/models/learning_models.dart';
import 'package:language_app/features/home/widgets/choice_chip_widget.dart';
import 'package:language_app/core/services/tts_service.dart';
import 'package:language_app/app/theme/app_style.dart';

class VocabLoopView extends StatefulWidget {
  final String lessonId;
  const VocabLoopView({super.key, required this.lessonId});

  @override
  State<VocabLoopView> createState() => _VocabLoopViewState();
}

class _VocabLoopViewState extends State<VocabLoopView>
    with TickerProviderStateMixin {
  late TtsService _ttsService;
  late AvatarController avatarController;
  final ILearningRepository repository = MockLearningRepository();

  String? selectedChoiceId;
  String? selectedChoiceText;
  bool showError = false;
  bool isMuted = false;
  bool isAvatarMaximized = true;
  bool isAvatarSpeaking = false;
  bool showTranslation = false;

  late AnimationController _shakeController;
  late AnimationController _correctController;
  late AnimationController _avatarController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _avatarSizeAnimation;

  LessonStep? _cachedStep;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    avatarController = AvatarController();
    _ttsService = TtsService();

    // Link TTS state to UI
    _ttsService.onSpeakingStateChanged = (speaking) {
      if (mounted) setState(() => isAvatarSpeaking = speaking);
    };

    _initAnimations();
    _loadLessonStep();

    // Load Visemes via Controller
    avatarController.loadVisemeData();

    // Initialize Voice
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final avatarProvider =
          Provider.of<AvatarProvider>(context, listen: false);
      _ttsService.setVoiceForAvatar(avatarProvider.selectedAvatarName);
    });
  }

  Future<void> _loadLessonStep() async {
    final step = await repository.fetchNextStep(widget.lessonId);
    if (mounted) {
      setState(() {
        _cachedStep = step;
        _isLoading = false;
      });
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

    _avatarController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _avatarSizeAnimation = Tween<double>(begin: 380, end: 180).animate(
      CurvedAnimation(parent: _avatarController, curve: Curves.easeInOut),
    );
  }

  Future<void> _speak(String text) async {
    if (!isMuted) {
      // 1. Trigger Lip Sync via Controller
      avatarController.speakWithLipSync(text);

      // 2. Play Audio via Service
      await _ttsService.speak(text);
    }
  }

  Future<void> _stop() async {
    await _ttsService.stop();
    await avatarController.stopHandWave();
    if (mounted) setState(() => isAvatarSpeaking = false);
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

  Color _getThemeColor(String avatarName) {
    return AppColors.getAvatarTheme(avatarName);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _correctController.dispose();
    _avatarController.dispose();
    _ttsService.stop();
    avatarController.stopHandWave();
    avatarController.disposeView();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avatarProvider = context.watch<AvatarProvider>();
    final selectedAvatar = avatarProvider.selectedAvatarName;
    final themeColor = _getThemeColor(selectedAvatar);

    if (_isLoading || _cachedStep == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: themeColor),
        ),
      );
    }

    final step = _cachedStep!;
    final isSentenceType = step.type == "complete_mc";
    final correctChoice = step.choices!.firstWhere((c) => c.isCorrect);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildAvatarHeader(context, selectedAvatar, themeColor, step),
                const SizedBox(height: 24),
                Expanded(
                  child: isSentenceType
                      ? _buildFillBlankLayout(step)
                      : _buildMultipleChoiceLayout(step),
                ),
                _buildContinueButton(step, themeColor),
              ],
            ),
            if (showError) _buildErrorDialog(correctChoice.text, themeColor),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarHeader(
    BuildContext context,
    String avatarName,
    Color themeColor,
    LessonStep step,
  ) {
    return AnimatedBuilder(
      animation: _avatarSizeAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTap: _toggleAvatarSize,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            width: double.infinity,
            height: _avatarSizeAnimation.value,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: themeColor.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      transform: Matrix4.identity()
                        ..scale(isAvatarSpeaking ? 1.05 : 1.0),
                      child: AvatarView(
                        avatarName: avatarName,
                        controller: avatarController,
                        height: _avatarSizeAnimation.value,
                        backgroundImagePath: "assets/images/background.png",
                        borderRadius: 12,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Color(0xFFFF8000),
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        avatarName,
                        style: const TextStyle(
                          color: Color(0xFFFF8000),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isAvatarSpeaking)
                  Positioned(
                    top: 10,
                    right: 10,
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
                              color: themeColor,
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
                                ? Icons.fullscreen_exit
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
                                  : [
                                      const Color(0xFFFF609D),
                                      const Color(0xFFFF7A06)
                                    ],
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
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 80,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => _speak(step.question ?? ''),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: themeColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.volume_up,
                              color: themeColor,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            step.question ?? 'Select the correct answer',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMultipleChoiceLayout(LessonStep step) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: step.choices!.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemBuilder: (context, index) {
          final choice = step.choices![index];
          return ChoiceChipWidget(
            choice: choice,
            isSelected: selectedChoiceId == choice.id,
            onTap: () => _onChoiceSelected(choice),
            isLarge: true,
          );
        },
      ),
    );
  }

  Widget _buildFillBlankLayout(LessonStep step) {
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
              border: Border.all(color: const Color(0xFFFF8000), width: 2),
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
                  step.question ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          showTranslation = !showTranslation;
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
                      onTap: () => _speak(step.question ?? ''),
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: step.choices!.map((choice) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChipWidget(
                    choice: choice,
                    isSelected: selectedChoiceId == choice.id,
                    onTap: () => _onChoiceSelected(choice),
                    isLarge: false,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(LessonStep step, Color themeColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: GestureDetector(
        onTap: () => _handleContinue(step),
        child: Container(
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
    );
  }

  Widget _buildErrorDialog(String correctAnswer, Color themeColor) {
    return Container(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                  _shakeAnimation.value *
                      ((_shakeController.value * 4).floor() % 2 == 0 ? 1 : -1),
                  0),
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
                              setState(() {
                                showError = false;
                                selectedChoiceId = null;
                              });
                            },
                            child: Container(
                              width: double.infinity,
                              height: 46,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF609D),
                                    Color(0xFFFF7A06)
                                  ],
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
    );
  }

  void _onChoiceSelected(Choice choice) {
    setState(() {
      selectedChoiceId = choice.id;
      selectedChoiceText = choice.text;
    });
    _speak(choice.text);
  }

  void _handleContinue(LessonStep step) {
    if (selectedChoiceId == null) return;

    final correctChoice = step.choices!.firstWhere((c) => c.isCorrect);

    if (!showError) {
      if (selectedChoiceId != correctChoice.id) {
        setState(() {
          showError = true;
          _vibratePhone();
          _shakeController.forward().then((_) => _shakeController.reverse());
        });

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && showError) {
            _speak("The right answer is ${correctChoice.text}");
          }
        });
        return;
      } else {
        _correctController.forward();
        _playCorrectSound();
        _speak("Well done");

        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) {
            if (widget.lessonId == "lesson_1") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const VocabLoopView(lessonId: "lesson_2"),
                ),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const HomeView(),
                ),
              );
            }
          }
        });
      }
    }
  }
}
