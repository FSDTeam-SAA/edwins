import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:language_app/app/constants/app_constants.dart';
import 'package:language_app/core/providers/theme_provider.dart';
import 'package:language_app/features/avatar/avatar_controller.dart';
import 'package:language_app/features/avatar/avatar_view.dart';
import 'package:language_app/features/home/widgets/recording_overlay.dart';
import 'package:language_app/features/home/learning/result/Vocab_end_result.dart';
import 'package:language_app/core/utils/viseme_helper.dart';
import 'package:provider/provider.dart';

class FreeConversationChat extends StatefulWidget {
  final String selectedAvatarName;

  const FreeConversationChat({super.key, required this.selectedAvatarName});

  @override
  State<FreeConversationChat> createState() => _FreeConversationChatState();
}

class _FreeConversationChatState extends State<FreeConversationChat>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  bool isRecording = false;
  bool showWaveform = false;
  bool showSendButton = false;
  bool isMuted = false;
  bool isAvatarMinimized = false;
  bool isAvatarSpeaking = false;
  String? recordedText;
  bool showRecordingControls = false;

  late FlutterTts flutterTts;
  late AvatarController avatarController;

  late AnimationController _waveformController;
  late AnimationController _buttonPressController;
  late AnimationController _avatarController;
  late AnimationController _speakingController;

  List<Map<String, dynamic>> messages = [];
  String currentQuestion = 'Translate the sentence:';
  String currentSentence = 'The cat eats chicken.';
  String correctAnswer = 'Die Katze frisst Hühnchen';

  final VisemeHelper _visemeHelper = VisemeHelper();

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

    // Speak the initial question
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _speak('$currentQuestion $currentSentence');
          setState(() {
            messages.add({
              'text': currentSentence,
              'isUser': true,
              'type': 'text',
            });
          });
        }
      });
    });
  }

  void _initAnimations() {
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
  }

  Future<void> _speak(String text) async {
    if (!isMuted) {
      await flutterTts.stop();
      await Future.delayed(const Duration(milliseconds: 100));
      // Start lip sync using viseme file
      _scheduleVisemesFromFile(text);
      await flutterTts.speak(text);
    }
  }

  Future<void> _scheduleVisemesFromFile(String text) async {
    // For this implementation, we ignore the input text and just play the sequence from the file
    // matching the "The cat eats chicken" sentence which aligns with the viseme.txt updates.
    // In a real scenario, you'd map text to specific timeline files or use the on-the-fly generator.

    String visemeFile = 'test/data/viseme.txt';

    try {
      final visemes = await _visemeHelper.loadVisemesFromAsset(visemeFile);

      if (!mounted) return;

      _speakingController.forward();
      setState(() => isAvatarSpeaking = true);

      // Calculate total duration for the speaking state
      double totalDuration = 0;
      if (visemes.isNotEmpty) {
        totalDuration = visemes.last['endSec'] as double;
      }

      // Schedule each viseme trigger
      for (final v in visemes) {
        final id = v['id'] as String;
        final start = v['startSec'] as double;
        final end = v['endSec'] as double;
        // duration calculation
        final duration = end - start;

        // Convert start time to milliseconds for delay
        final delayMs = (start * 1000).toInt();

        Future.delayed(Duration(milliseconds: delayMs), () {
          if (mounted && isAvatarSpeaking) {
            // Use triggerViseme which is known to work
            // Apply scaling factor (0.5) to prevent over-opening
            final weight = (v['weight'] as double? ?? 1.0) * 0.5;
            avatarController.triggerViseme(id,
                duration: duration, weight: weight);
          }
        });
      }

      // Turn off speaking state after the last viseme
      Future.delayed(
          Duration(milliseconds: (totalDuration * 1000).toInt() + 500), () {
        if (mounted && isAvatarSpeaking) {
          _stopSpeakingAnimation();
        }
      });
    } catch (e) {
      debugPrint("Error loading visemes: $e");
      _speakingController.repeat(reverse: true);
      setState(() => isAvatarSpeaking = true);
    }
  }

  void _stopSpeakingAnimation() {
    if (mounted) {
      _speakingController.stop();
      _speakingController.reset();
      setState(() => isAvatarSpeaking = false);

      // Reset morphs
      avatarController.resetToNeutral();
    }
  }

  Future<void> _stop() async {
    await flutterTts.stop();
  }

  void _toggleMute() {
    setState(() => isMuted = !isMuted);
    if (isMuted) _stop();
  }

  void _toggleAvatarSize() {
    setState(() => isAvatarMinimized = !isAvatarMinimized);
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

    // Simulate STT result
    recordedText = "I think the cat eats chicken";

    // Approve and send the recording
    _approveRecording();

    setState(() {
      isRecording = false;
      showRecordingControls = true;
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
        'isCorrect': true,
      });
      recordedText = null;
    });

    _speak('The correct answer is: $correctAnswer');

    // Add the correct answer as a message from the avatar
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          messages.add({
            'text': correctAnswer,
            'isUser': true, // Display on left side
            'type': 'text',
            'isCorrect': true,
          });
        });
      }
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const VocabEndResultView(),
          ),
        );
      }
    });
  }

  void _sendMessage() {
    if (_textController.text.trim().isEmpty) return;

    String userMessage = _textController.text.trim();
    // Accept any input as correct for reinforcement learning
    bool isCorrect = true;

    setState(() {
      messages.add({
        'text': userMessage,
        'isUser': false,
        'type': 'text',
        'isCorrect': isCorrect,
      });
      _textController.clear();
      showSendButton = false;
    });

    // Reinforcement learning: always speak the correct answer
    _speak('The correct answer is: $correctAnswer');

    // Add the correct answer as a message from the avatar
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          messages.add({
            'text': correctAnswer,
            'isUser': true, // Display on left side
            'type': 'text',
            'isCorrect': true,
          });
        });
      }
    });

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const VocabEndResultView(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: themeProvider.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Column(
                children: [
                  _buildAvatarSection(),
                  if (currentQuestion.isNotEmpty) _buildQuestionHeader(),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        return _buildMessage(messages[index]);
                      },
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
                widget.selectedAvatarName,
                style: const TextStyle(
                  color: Color(0xFFFF8000),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          // _AnimatedIconButton(
          //   icon: Icons.arrow_forward_ios,
          //   color: const Color(0xFFFF8000),
          //   onPressed: () {},
          // ),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      width: double.infinity,
      height: isAvatarMinimized ? 380 : 540,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  AvatarView(
                    avatarName: widget.selectedAvatarName,
                    controller: avatarController,
                    height: isAvatarMinimized ? 380 : 540,
                    backgroundImagePath: AppConstants.backgroundImage,
                    borderRadius: 24,
                  ),
                  if (!isAvatarMinimized && isAvatarSpeaking)
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
                          icon: isMuted ? Icons.volume_off : Icons.volume_up,
                          onTap: _toggleMute,
                        ),
                        const SizedBox(width: 8),
                        _buildCircleAction(
                          icon: isAvatarMinimized
                              ? Icons.fullscreen
                              : Icons.fullscreen_exit,
                          onTap: _toggleAvatarSize,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _repeatCorrectAnswer() {
    _speak('$currentQuestion $currentSentence');
  }

  Widget _buildCircleAction({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
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
                mainAxisAlignment:
                    isUser ? MainAxisAlignment.start : MainAxisAlignment.end,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
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
                            color: (isCorrect ? Colors.green : Colors.red)
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCorrect != null)
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            // child: Icon(
                            //   isCorrect ? Icons.check_circle : Icons.cancel,
                            //   color: isCorrect
                            //       ? Colors.green.shade700
                            //       : Colors.white,
                            //   size: 20,
                            // ),
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

  Widget _buildBottomInput() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
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
                            hintStyle:
                                TextStyle(color: Colors.grey, fontSize: 14),
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
        ),
        if (isRecording)
          Positioned.fill(
            child: RecordingOverlay(
              onRecordingComplete: _approveRecording,
              onRecordingCancelled: _cancelRecording,
            ),
          ),
      ],
    );
  }
}

// Helper Widgets
class _AnimatedIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _AnimatedIconButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }
}

class _AnimatedCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _AnimatedCircleButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF609D), Color(0xFFFF7A06)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF609D).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

class _AnimatedMicButton extends StatelessWidget {
  final bool isRecording;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;

  const _AnimatedMicButton({
    required this.isRecording,
    required this.onStartRecording,
    required this.onStopRecording,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => onStartRecording(),
      onLongPressEnd: (_) => onStopRecording(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isRecording
                ? [Colors.red.shade400, Colors.red.shade600]
                : [const Color(0xFFFF609D), const Color(0xFFFF7A06)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (isRecording ? Colors.red : const Color(0xFFFF609D))
                  .withOpacity(0.3),
              blurRadius: isRecording ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          isRecording ? Icons.mic : Icons.mic_none,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
