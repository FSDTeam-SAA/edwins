import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:language_app/app/constants/app_constants.dart';
import 'package:language_app/features/auth/login.dart';
import 'package:language_app/features/debug/test_vocabulary.dart';
import 'package:language_app/features/avatar/avatar_controller.dart';
import 'package:language_app/features/avatar/avatar_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late FlutterTts flutterTts;
  Map<String, List<VisemeData>> visemeMap = {};
  String selectedNative = "English";
  String selectedTarget = "German";
  String selectedGoal = "";
  String selectedTime = "5 min";
  String selectedLevel = "";
  String selectedAvatar = "";
  List<String> selectedHobbies = [];
  bool _isNextButtonActive =
      true; // true = Next বাটনে অ্যানিমেশন, false = Test বাটনে
  // Avatar Controllers
  final AvatarController claraController = AvatarController();
  final AvatarController karlController = AvatarController();

  // Animation Controllers
  late AnimationController _buttonScaleController;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _buttonScaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonScaleController, curve: Curves.easeInOut),
    );

    _initTts();
    _loadVisemeData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _buttonScaleController.dispose();
    claraController.disposeView();
    karlController.disposeView();
    flutterTts.stop(); // এই line add করুন
    super.dispose();
  }

  _completeOnboarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarded', true);
  }

  // 🎨 Scale + Fade Animation
  Route _createScaleRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeInOutCubic;

        var scaleTween = Tween<double>(
          begin: 0.85,
          end: 1.0,
        ).chain(CurveTween(curve: curve));
        var fadeTween = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: curve));

        return ScaleTransition(
          scale: animation.drive(scaleTween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 500),
    );
  }

  // 🎨 Slide from Bottom Animation
  Route _createSlideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 0.3);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var slideTween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        var fadeTween = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(slideTween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 500),
    );
  }

  // Animated button press handler
  Future<void> _onButtonPressed(VoidCallback action) async {
    await _buttonScaleController.forward();
    await _buttonScaleController.reverse();
    action();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _currentPage == 0
            ? null
            : _AnimatedBackButton(
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOutCubic,
                  );
                },
              ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (int page) {
                  setState(() => _currentPage = page);

                  // যখন Partner page এ আসবে, Clara এর greeting play করবে
                  if (page == 4) {
                    Future.delayed(const Duration(milliseconds: 800), () {
                      if (mounted) {
                        _playAvatarGreeting("Clara");
                      }
                    });
                  }
                },
                children: [
                  _AnimatedPageWrapper(
                    key: const ValueKey(0),
                    child: _buildLanguageStep("What is your target language?", [
                      "German",
                      "English",
                      "Spanish",
                    ], false),
                  ),
                  _AnimatedPageWrapper(
                    key: const ValueKey(1),
                    child: _buildGoalStep(),
                  ),
                  _AnimatedPageWrapper(
                    key: const ValueKey(2),
                    child: _buildLanguageStep("What is your native language?", [
                      "English",
                      "French",
                      "Arabic",
                    ], true),
                  ),
                  _AnimatedPageWrapper(
                    key: const ValueKey(3),
                    child: _buildTimeStep(),
                  ),
                  _AnimatedPageWrapper(
                    key: const ValueKey(4),
                    child: _buildPartnerStep(),
                  ),
                  _AnimatedPageWrapper(
                    key: const ValueKey(5),
                    child: _buildHobbiesStep(),
                  ),
                  _AnimatedPageWrapper(
                    key: const ValueKey(6),
                    child: _buildLevelStep(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: _buildIndicator(),
            ),
            _buildNextButton(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
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

    print('✅ Loaded viseme data for ${visemeMap.length} words');
  }

  void _startLipSync(String text) {
    final words = text.toLowerCase().split(' ');
    print('📝 Words to sync: $words');

    for (var word in words) {
      word = word.replaceAll(RegExp(r'[^\w\s]'), '').trim();

      if (word.isEmpty) continue;

      print('🔍 Looking for viseme data: "$word"');

      if (visemeMap.containsKey(word)) {
        final visemes = visemeMap[word]!;
        print('✅ Found ${visemes.length} visemes for "$word"');

        final controller = word == 'clara' || word == 'am' || word == 'i'
            ? claraController
            : karlController;

        for (var viseme in visemes) {
          final delay = (viseme.startTime * 1000).toInt();
          final duration = (viseme.endTime - viseme.startTime);

          print('⏱️ Scheduling ${viseme.name} at ${delay}ms for ${duration}s');

          Future.delayed(Duration(milliseconds: delay), () {
            if (mounted) {
              print('🎭 Playing viseme: ${viseme.name}');
              controller.triggerViseme(viseme.name, duration: duration);
            }
          });
        }
      } else {
        print('❌ No viseme data found for "$word"');
      }
    }
  }

  Future<void> _initTts() async {
    flutterTts = FlutterTts();
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.4);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
  }

  Future<void> _playAvatarGreeting(String avatarName) async {
    String greetingText = avatarName == "Karl"
        ? "Hi, I am Karl"
        : "Hi, I am Clara";

    print('👋 Playing greeting: $greetingText');

    // Set voice based on avatar
    if (avatarName == "Karl") {
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

    // ✅ Get animation path from AppConstants
    final controller = avatarName == "Clara" ? claraController : karlController;
    final animationPath = avatarName == "Clara"
        ? AppConstants.claraAnimationPath
        : AppConstants.karlAnimationPath;

    print('🎬 Using animation path: $animationPath');

    // ✅ Trigger 8 second hand wave
    await controller.triggerHandWaveWithPath(animationPath, duration: 1.0);

    await Future.delayed(const Duration(milliseconds: 500));

    // Start lip sync BEFORE speaking
    _startLipSync(greetingText);

    await flutterTts.speak(greetingText);
  }

  Widget _buildLanguageStep(String title, List<String> options, bool isNative) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 40),
          _AnimatedDropdown(
            value: isNative ? selectedNative : selectedTarget,
            items: options,
            onChanged: (val) {
              setState(() {
                if (isNative) {
                  selectedNative = val!;
                } else {
                  selectedTarget = val!;
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGoalStep() {
    List<Map<String, String>> goals = [
      {"title": "Travel", "icon": "✈️"},
      {"title": "Work", "icon": "💼"},
      {"title": "Personal", "icon": "👤"},
      {"title": "Studies", "icon": "📖"},
      {"title": "Live Abroad", "icon": "🌐"},
    ];
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Why do you want to learn the language?",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 30),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: goals.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, String> goal = entry.value;
              bool isSelected = selectedGoal == goal['title'];

              return _AnimatedSelectionCard(
                key: ValueKey('goal_$index'),
                isSelected: isSelected,
                delay: Duration(milliseconds: 100 * index),
                onTap: () => setState(() => selectedGoal = goal['title']!),
                child: Text(
                  "${goal['title']} ${goal['icon']}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "How much time do you have in a day?",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 30),
          _AnimatedDropdown(
            value: selectedTime,
            items: const ["5 min", "10 min", "1 hour", "2 hour", "4+ hour"],
            onChanged: (val) => setState(() => selectedTime = val!),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Text(
            "Choose your language partner",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Swipe indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_back_ios, size: 16, color: Colors.grey.shade400),
              const SizedBox(width: 8),
              Text(
                "Swipe and Tap to select",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Horizontal scrollable avatars
          Expanded(
            child: PageView(
              padEnds: false,
              onPageChanged: (index) {
                // Avatar swap করলে greeting play হবে
                if (index == 0) {
                  _playAvatarGreeting("Clara");
                } else if (index == 1) {
                  _playAvatarGreeting("Karl");
                }
              },
              children: [
                // Clara Avatar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _AnimatedAvatarCard(
                    key: const ValueKey('clara'),
                    isSelected: selectedAvatar == "Clara",
                    delay: const Duration(milliseconds: 100),
                    onTap: () => setState(() => selectedAvatar = "Clara"),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            child: AvatarView(
                              avatarName: "Clara",
                              controller: claraController,
                              height: 400,
                              backgroundImagePath:
                                  "assets/images/background.png",
                              borderRadius: 0,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: selectedAvatar == "Clara"
                                ? Colors.orange.withOpacity(0.1)
                                : Colors.white,
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Clara",
                                style: TextStyle(
                                  color: selectedAvatar == "Clara"
                                      ? Colors.orange
                                      : Colors.black,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              if (selectedAvatar == "Clara") ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.orange,
                                  size: 24,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Karl Avatar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _AnimatedAvatarCard(
                    key: const ValueKey('karl'),
                    isSelected: selectedAvatar == "Karl",
                    delay: const Duration(milliseconds: 100),
                    onTap: () => setState(() => selectedAvatar = "Karl"),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            child: AvatarView(
                              avatarName: "Karl",
                              controller: karlController,
                              height: 400,
                              backgroundImagePath:
                                  "assets/images/background.png",
                              borderRadius: 0,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: selectedAvatar == "Karl"
                                ? Colors.orange.withOpacity(0.1)
                                : Colors.white,
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Karl",
                                style: TextStyle(
                                  color: selectedAvatar == "Karl"
                                      ? Colors.orange
                                      : Colors.black,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              if (selectedAvatar == "Karl") ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.orange,
                                  size: 24,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHobbiesStep() {
    List<String> hobbies = [
      "Football",
      "Basketball",
      "Film/TV",
      "History",
      "Geographic",
      "Nature",
      "Hiking",
      "Technology",
      "Fitness",
      "Finance",
      "Health",
      "Food/Cooking",
    ];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "What are your hobbies?",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Select Max 2",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: hobbies.asMap().entries.map((entry) {
                  int index = entry.key;
                  String hobby = entry.value;
                  bool isSelected = selectedHobbies.contains(hobby);
                  bool canSelect = selectedHobbies.length < 2 || isSelected;

                  return _AnimatedSelectionCard(
                    key: ValueKey('hobby_$index'),
                    isSelected: isSelected,
                    delay: Duration(milliseconds: 50 * index),
                    onTap: canSelect
                        ? () {
                            setState(() {
                              if (isSelected) {
                                selectedHobbies.remove(hobby);
                              } else if (selectedHobbies.length < 2) {
                                selectedHobbies.add(hobby);
                              }
                            });
                          }
                        : null,
                    child: Opacity(
                      opacity: canSelect ? 1.0 : 0.4,
                      child: Text(
                        hobby,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "What is your speaking level?",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 30),
          ...['A1', 'A2', 'B1', 'B2', 'C1', 'C2'].asMap().entries.map((entry) {
            int index = entry.key;
            String lvl = entry.value;
            bool isSelected = selectedLevel == lvl;

            return _AnimatedLevelCard(
              key: ValueKey('level_$lvl'),
              isSelected: isSelected,
              delay: Duration(milliseconds: 80 * index),
              onTap: () => setState(() => selectedLevel = lvl),
              child: Text(
                lvl,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(7, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.all(4),
          width: _currentPage == index ? 30 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: _currentPage == index ? Colors.orange : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(5),
            boxShadow: _currentPage == index
                ? [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
        );
      }),
    );
  }

  Widget _buildNextButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          // Next Button - শুধু যখন _isNextButtonActive = true তখনই অ্যানিমেশন চলবে
          ScaleTransition(
            scale: _isNextButtonActive
                ? _buttonScaleAnimation
                : const AlwaysStoppedAnimation<double>(1.0),
            child: _AnimatedGradientButton(
              onPressed: () {
                setState(() {
                  _isNextButtonActive = true; // ✅ Next button animated হবে
                });

                _onButtonPressed(() {
                  bool isValid = true;
                  String message = "";

                  if (_currentPage == 1 && selectedGoal.isEmpty) {
                    isValid = false;
                    message = "Please select a goal!";
                  } else if (_currentPage == 4 && selectedAvatar.isEmpty) {
                    isValid = false;
                    message = "Please select an avatar!";
                  } else if (_currentPage == 5 && selectedHobbies.isEmpty) {
                    isValid = false;
                    message = "Please select at least one hobby!";
                  } else if (_currentPage == 6 && selectedLevel.isEmpty) {
                    isValid = false;
                    message = "Please select your speaking level!";
                  }

                  if (!isValid) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                    return;
                  }

                  if (_currentPage < 6) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOutCubic,
                    );
                  } else {
                    _completeOnboarding();
                    Navigator.pushReplacement(
                      context,
                      _createScaleRoute(const LoginPage()),
                    );
                  }
                });
              },
              text: "Next",
            ),
          ),

          // শুধু level page এ দেখাবে (page == 6)
          if (_currentPage == 6) ...[
            const SizedBox(height: 15),

            // Test Your Level Button - শুধু যখন _isNextButtonActive = false তখনই অ্যানিমেশন
            ScaleTransition(
              scale: !_isNextButtonActive
                  ? _buttonScaleAnimation
                  : const AlwaysStoppedAnimation<double>(1.0),
              child: _AnimatedTestButton(
                onPressed: () {
                  setState(() {
                    _isNextButtonActive = false; // ✅ Test button animated হবে
                  });

                  _onButtonPressed(() {
                    if (selectedAvatar.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("Please select an avatar first!"),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      _createSlideRoute(
                        TestVocabularyPage(selectedAvatar: selectedAvatar),
                      ),
                    );
                  });
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// 🎨 Animated Back Button
class _AnimatedBackButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _AnimatedBackButton({required this.onPressed});

  @override
  State<_AnimatedBackButton> createState() => _AnimatedBackButtonState();
}

class _AnimatedBackButtonState extends State<_AnimatedBackButton>
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
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
        icon: const Icon(Icons.arrow_back_ios, color: Colors.orange),
        onPressed: () async {
          await _controller.forward();
          await _controller.reverse();
          widget.onPressed();
        },
      ),
    );
  }
}

// 🎨 Animated Dropdown
class _AnimatedDropdown extends StatefulWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _AnimatedDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  State<_AnimatedDropdown> createState() => _AnimatedDropdownState();
}

class _AnimatedDropdownState extends State<_AnimatedDropdown>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(
            color: _isPressed ? Colors.orange : Colors.grey.shade300,
            width: _isPressed ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: _isPressed
              ? [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: widget.value,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
            items: widget.items.map((String lang) {
              return DropdownMenuItem<String>(
                value: lang,
                child: Text(lang, style: const TextStyle(fontSize: 18)),
              );
            }).toList(),
            onChanged: (val) {
              setState(() => _isPressed = true);
              _controller.forward().then((_) {
                _controller.reverse();
                setState(() => _isPressed = false);
              });
              widget.onChanged(val);
            },
          ),
        ),
      ),
    );
  }
}

// 🎨 Animated Selection Card (for goals and hobbies)
class _AnimatedSelectionCard extends StatefulWidget {
  final bool isSelected;
  final VoidCallback? onTap;
  final Widget child;
  final Duration delay;

  const _AnimatedSelectionCard({
    Key? key,
    required this.isSelected,
    required this.onTap,
    required this.child,
    this.delay = Duration.zero,
  }) : super(key: key);

  @override
  State<_AnimatedSelectionCard> createState() => _AnimatedSelectionCardState();
}

class _AnimatedSelectionCardState extends State<_AnimatedSelectionCard>
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

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
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
          onTapDown: widget.onTap != null
              ? (_) => setState(() => _isPressed = true)
              : null,
          onTapUp: widget.onTap != null
              ? (_) => setState(() => _isPressed = false)
              : null,
          onTapCancel: widget.onTap != null
              ? () => setState(() => _isPressed = false)
              : null,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: widget.isSelected ? Colors.orange : Colors.grey.shade300,
                width: widget.isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: widget.isSelected
                  ? Colors.orange.withOpacity(0.1)
                  : Colors.white,
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// 🎨 Animated Avatar Card
class _AnimatedAvatarCard extends StatefulWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final Widget child;
  final Duration delay;

  const _AnimatedAvatarCard({
    Key? key,
    required this.isSelected,
    required this.onTap,
    required this.child,
    this.delay = Duration.zero,
  }) : super(key: key);

  @override
  State<_AnimatedAvatarCard> createState() => _AnimatedAvatarCardState();
}

class _AnimatedAvatarCardState extends State<_AnimatedAvatarCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
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
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.isSelected ? Colors.orange : Colors.grey.shade300,
                width: widget.isSelected ? 3 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.isSelected
                      ? Colors.orange.withOpacity(0.3)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: widget.isSelected ? 15 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                color: widget.isSelected
                    ? Colors.orange.withOpacity(0.05)
                    : Colors.white,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 🎨 Animated Level Card
class _AnimatedLevelCard extends StatefulWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final Widget child;
  final Duration delay;

  const _AnimatedLevelCard({
    Key? key,
    required this.isSelected,
    required this.onTap,
    required this.child,
    this.delay = Duration.zero,
  }) : super(key: key);

  @override
  State<_AnimatedLevelCard> createState() => _AnimatedLevelCardState();
}

class _AnimatedLevelCardState extends State<_AnimatedLevelCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

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
      child: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_slideAnimation.value, 0),
            child: child,
          );
        },
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              border: Border.all(
                color: widget.isSelected ? Colors.orange : Colors.grey.shade300,
                width: widget.isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: widget.isSelected
                  ? Colors.orange.withOpacity(0.05)
                  : Colors.white,
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
            child: Center(child: widget.child),
          ),
        ),
      ),
    );
  }
}

// 🎨 Animated Gradient Button
class _AnimatedGradientButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;

  const _AnimatedGradientButton({required this.onPressed, required this.text});

  @override
  State<_AnimatedGradientButton> createState() =>
      _AnimatedGradientButtonState();
}

class _AnimatedGradientButtonState extends State<_AnimatedGradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF5F6D), Color(0xFFFFC371)],
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFFFF5F6D,
              ).withOpacity(_isPressed ? 0.2 : 0.3),
              blurRadius: _isPressed ? 8 : 12,
              offset: Offset(0, _isPressed ? 3 : 6),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          onPressed: () async {
            setState(() => _isPressed = true);
            await _controller.forward();
            await _controller.reverse();
            setState(() => _isPressed = false);
            widget.onPressed();
          },
          child: Text(
            widget.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

// 🎨 Animated Test Button
class _AnimatedTestButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _AnimatedTestButton({required this.onPressed});

  @override
  State<_AnimatedTestButton> createState() => _AnimatedTestButtonState();
}

class _AnimatedTestButtonState extends State<_AnimatedTestButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF2ECC71,
              ).withOpacity(_isPressed ? 0.2 : 0.3),
              blurRadius: _isPressed ? 8 : 12,
              offset: Offset(0, _isPressed ? 3 : 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () async {
            setState(() => _isPressed = true);
            await _controller.forward();
            await _controller.reverse();
            setState(() => _isPressed = false);
            widget.onPressed();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2ECC71),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            "Test your level",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

// 🎨 Animated Page Wrapper
class _AnimatedPageWrapper extends StatefulWidget {
  final Widget child;

  const _AnimatedPageWrapper({Key? key, required this.child}) : super(key: key);

  @override
  State<_AnimatedPageWrapper> createState() => _AnimatedPageWrapperState();
}

class _AnimatedPageWrapperState extends State<_AnimatedPageWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
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
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
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
