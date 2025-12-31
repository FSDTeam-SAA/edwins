import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:language_app/Auth/login.dart';
import 'package:language_app/avatar/avatar_controller.dart';
import 'package:language_app/avatar/avatar_view.dart';
import 'dart:io' show Platform;
import 'dart:math' as math;


class TestConversationPage extends StatefulWidget {
  final String selectedAvatar; // Add this parameter
  
  const TestConversationPage({
    super.key,
    required this.selectedAvatar,
  });

  @override
  State<TestConversationPage> createState() => _TestConversationPageState();
}

class _TestConversationPageState extends State<TestConversationPage> {
  final TextEditingController _textController = TextEditingController();
  bool isRecording = false;
  bool showWaveform = false;
  bool showSendButton = false;
  bool isMuted = false;

  // Text-to-Speech instance
  late FlutterTts flutterTts;
  
  // Avatar Controller
  late AvatarController avatarController;

  List<Map<String, dynamic>> messages = [
    {
      'text': 'The cat eats chicken.',
      'isUser': true,
      'type': 'text',
    },
  ];

  String currentQuestion = 'Translate the sentence:';
  bool showCharacter = false;

  @override
  void initState() {
    super.initState();
    avatarController = AvatarController();
    _initTts();
    
    // Listen to text changes to toggle send button
    _textController.addListener(() {
      setState(() {
        showSendButton = _textController.text.trim().isNotEmpty;
      });
    });
  }

  // Initialize TTS with proper configuration
  Future<void> _initTts() async {
    flutterTts = FlutterTts();
    
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.4);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);

    // iOS specific settings
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
      await flutterTts.setSharedInstance(true);
    }

    if (await flutterTts.isLanguageAvailable("en-US")) {
      await flutterTts.setLanguage("en-US");
    }

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
      await flutterTts.stop();
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
    _textController.dispose();
    flutterTts.stop();
    avatarController.disposeView();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      isRecording = true;
      showWaveform = false;
    });

    Timer(const Duration(milliseconds: 500), () {
      if (mounted && isRecording) {
        setState(() {
          showWaveform = true;
        });
      }
    });
  }

  void _stopRecording() {
    if (!isRecording) return;

    setState(() {
      isRecording = false;
      showWaveform = false;

      messages.add({
        'text': null,
        'isUser': false,
        'type': 'audio',
        'duration': '1:34',
      });

      messages.add({
        'text': 'Die Katze frisst Hühnchen.',
        'isUser': false,
        'type': 'text',
      });
    });

    // Speak the response
    _speak('Die Katze frisst Hühnchen.');

    // Navigate to LanguageLevelPage after 2 seconds
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LanguageLevelPage()),
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

    // Speak the user's message
    _speak(userMessage);

    // Navigate to LanguageLevelPage after 2 seconds
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LanguageLevelPage()),
        );
      }
    });
  }

  void _toggleToVoiceRecordScreen() {
    setState(() {
      showCharacter = true;
      currentQuestion = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: showCharacter ? const Color(0xFFF5F5F5) : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Stack(
                children: [
                  Column(
                    children: [
                      if (showCharacter) _buildCharacterSection(),
                      if (!showCharacter && currentQuestion.isNotEmpty)
                        _buildQuestionHeader(),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            return _buildMessage(messages[index]);
                          },
                        ),
                      ),
                    ],
                  ),
                  // Show big microphone button only in character view
                  if (showCharacter)
                    Positioned(
                      bottom: 100,
                      left: 0,
                      right: 0,
                      child: Center(child: _buildMicrophoneButton()),
                    ),
                ],
              ),
            ),
            if (!showCharacter) _buildBottomInput(),
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
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFFF8000), size: 18),
                padding: EdgeInsets.zero,
                onPressed: () {
                  if (showCharacter) {
                    // If in character view, go back to conversation
                    setState(() {
                      showCharacter = false;
                      currentQuestion = 'Translate the sentence:';
                    });
                  } else {
                    // Otherwise, pop the page
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
        ],
      ),
    );
  }

  Widget _buildQuestionHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: const Text(
        'Translate the sentence:',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
      ),
    );
  }

  Widget _buildCharacterSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                padding: const EdgeInsets.all(8),
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
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    bool isUser = message['isUser'];
    String? text = message['text'];
    String type = message['type'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (type == 'audio' && !isUser)
            _buildAudioMessage(message['duration'])
          else
            Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFFFFFDE7) : null,
                gradient: !isUser
                    ? const LinearGradient(colors: [Color(0xFFFF609D), Color(0xFFFF7A06)])
                    : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                text ?? '',
                style: TextStyle(color: isUser ? Colors.black87 : Colors.white, fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAudioMessage(String duration) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFF609D), Color(0xFFFF7A06)]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.play_arrow, color: Colors.white, size: 20),
          const SizedBox(width: 6),
          SizedBox(
            width: 100,
            height: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(20, (index) {
                double height = (index % 3 == 0) ? 16 : (index % 2 == 0) ? 12 : 8;
                return Container(
                  width: 2,
                  height: height,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(1),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 8),
          Text(duration, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMicrophoneButton() {
    return GestureDetector(
      onTapDown: (_) => _startRecording(),
      onTapUp: (_) => _stopRecording(),
      onTapCancel: () => _stopRecording(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showWaveform)
            Container(
              width: 180,
              height: 70,
              margin: const EdgeInsets.only(bottom: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(25, (index) {
                  double height;
                  if (index == 12) {
                    height = 60;
                  } else if ([11, 13].contains(index)) {
                    height = 55;
                  } else if ([10, 14].contains(index)) {
                    height = 48;
                  } else if ([9, 15].contains(index)) {
                    height = 42;
                  } else if ([8, 16].contains(index)) {
                    height = 38;
                  } else if ([7, 17].contains(index)) {
                    height = 32;
                  } else if ([6, 18].contains(index)) {
                    height = 28;
                  } else {
                    height = 22;
                  }

                  return Container(
                    width: 3,
                    height: height,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
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
            ),
          Stack(
            alignment: Alignment.center,
            children: [
              if (isRecording)
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFF609D).withOpacity(0.15),
                        const Color(0xFFFF7A06).withOpacity(0.05),
                        Colors.transparent
                      ],
                      stops: const [0.3, 0.6, 1.0],
                    ),
                  ),
                ),
              if (isRecording)
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFF609D).withOpacity(0.25),
                        const Color(0xFFFF7A06).withOpacity(0.15),
                        Colors.transparent
                      ],
                      stops: const [0.4, 0.7, 1.0],
                    ),
                  ),
                ),
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: isRecording
                        ? [
                            const Color(0xFFFF609D).withOpacity(0.4),
                            const Color(0xFFFF7A06).withOpacity(0.2),
                            Colors.transparent
                          ]
                        : [
                            const Color(0xFFFFE0B2).withOpacity(0.5),
                            const Color(0xFFFFE0B2).withOpacity(0.2),
                            Colors.transparent
                          ],
                    stops: const [0.3, 0.6, 1.0],
                  ),
                ),
              ),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [Color(0xFFFF609D), Color(0xFFFF7A06)]),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF609D).withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.mic, color: Colors.white, size: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(width: 2, color: const Color(0xFFFF609D)),
              ),
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'Type your response',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Toggle between Voice and Send button
          GestureDetector(
            onTap: showSendButton ? _sendMessage : _toggleToVoiceRecordScreen,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFFFF609D), Color(0xFFFF7A06)]),
                shape: BoxShape.circle,
              ),
              child: Icon(
                showSendButton ? Icons.send : Icons.mic,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// LanguageLevelPage Widget
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
                    const Text(
                      'Your language level',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'B1',
                          style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFFFF7043), letterSpacing: 2),
                        ),
                        const SizedBox(width: 12),
                      ],
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
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFF609D), Color(0xFFFF7A06)]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: const Color(0xFFFF609D).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Start Now',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RadarChartWidget extends StatelessWidget {
  const RadarChartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 320, height: 320, child: CustomPaint(painter: RadarChartPainter()));
  }
}

class RadarChartPainter extends CustomPainter {
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
      final percentage = values[i] / 100;
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
      final percentage = values[i] / 100;
      final dataRadius = radius * percentage;
      final x = center.dx + dataRadius * math.cos(angle * i - math.pi / 2);
      final y = center.dy + dataRadius * math.sin(angle * i - math.pi / 2);
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }

    final textStyle = const TextStyle(color: Color(0xFF757575), fontSize: 12, fontWeight: FontWeight.w500);

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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}