import 'package:flutter/material.dart';
import 'package:language_app/Screens/test_vocabulary.dart';
import 'package:language_app/avatar/avatar_controller.dart';
import 'package:language_app/avatar/avatar_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  String selectedNative = "English";
  String selectedTarget = "German";
  String selectedGoal = "";
  String selectedTime = "5 min";
  String selectedLevel = "";
  String selectedAvatar = "";
  List<String> selectedHobbies = [];

  // Avatar Controllers
  final AvatarController claraController = AvatarController();
  final AvatarController karlController = AvatarController();

  @override
  void dispose() {
    _pageController.dispose();
    claraController.disposeView();
    karlController.disposeView();
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
        
        var scaleTween = Tween<double>(begin: 0.85, end: 1.0).chain(
          CurveTween(curve: curve),
        );
        var fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: curve),
        );
        
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
        
        var slideTween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        var fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: curve),
        );
        
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _currentPage == 0
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.orange),
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
                onPageChanged: (int page) => setState(() => _currentPage = page),
                children: [
                  _AnimatedPageWrapper(
                    key: const ValueKey(0),
                    child: _buildLanguageStep("What is your target language?", ["German", "English", "Spanish"], false),
                  ),
                  _AnimatedPageWrapper(
                    key: const ValueKey(1),
                    child: _buildGoalStep(),
                  ),
                  _AnimatedPageWrapper(
                    key: const ValueKey(2),
                    child: _buildLanguageStep("What is your native language?", ["English", "French", "Arabic"], true),
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

  Widget _buildLanguageStep(String title, List<String> options, bool isNative) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: isNative ? selectedNative : selectedTarget,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                items: options.map((String lang) {
                  return DropdownMenuItem<String>(
                    value: lang,
                    child: Text(lang, style: const TextStyle(fontSize: 18)),
                  );
                }).toList(),
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
            ),
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
          const Text("Why do you want to learn the language?", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: goals.map((goal) {
              bool isSelected = selectedGoal == goal['title'];
              return GestureDetector(
                onTap: () => setState(() => selectedGoal = goal['title']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? Colors.orange : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected ? Colors.orange.withOpacity(0.1) : Colors.white,
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ] : [],
                  ),
                  child: Text(
                    "${goal['title']} ${goal['icon']}", 
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
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
          const Text("How much time do you have in a day?", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedTime,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                items: ["5 min", "10 min", "1 hour", "2 hour", "4+ hour"].map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (val) => setState(() => selectedTime = val!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerStep() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              "Choose your language partner",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            
            // Clara Avatar
            GestureDetector(
              onTap: () => setState(() => selectedAvatar = "Clara"),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selectedAvatar == "Clara" ? Colors.orange : Colors.grey.shade300,
                    width: selectedAvatar == "Clara" ? 3 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: selectedAvatar == "Clara" 
                          ? Colors.orange.withOpacity(0.3)
                          : Colors.black.withOpacity(0.1),
                      blurRadius: selectedAvatar == "Clara" ? 15 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: AvatarView(
                        avatarName: "Clara",
                        controller: claraController,
                        height: 250,
                        backgroundImagePath: "assets/images/background.png",
                        borderRadius: 0,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selectedAvatar == "Clara" 
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.white,
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Clara",
                            style: TextStyle(
                              color: selectedAvatar == "Clara" ? Colors.orange : Colors.black,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (selectedAvatar == "Clara") ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.check_circle, color: Colors.orange, size: 22),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Karl Avatar
            GestureDetector(
              onTap: () => setState(() => selectedAvatar = "Karl"),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selectedAvatar == "Karl" ? Colors.orange : Colors.grey.shade300,
                    width: selectedAvatar == "Karl" ? 3 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: selectedAvatar == "Karl" 
                          ? Colors.orange.withOpacity(0.3)
                          : Colors.black.withOpacity(0.1),
                      blurRadius: selectedAvatar == "Karl" ? 15 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: AvatarView(
                        avatarName: "Karl",
                        controller: karlController,
                        height: 250,
                        backgroundImagePath: "assets/images/background.png",
                        borderRadius: 0,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selectedAvatar == "Karl" 
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.white,
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Karl",
                            style: TextStyle(
                              color: selectedAvatar == "Karl" ? Colors.orange : Colors.black,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (selectedAvatar == "Karl") ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.check_circle, color: Colors.orange, size: 22),
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
    );
  }

  Widget _buildHobbiesStep() {
    List<String> hobbies = ["Football", "Basketball", "Film/TV", "History", "Geographic", "Nature", "Hiking", "Technology", "Fitness", "Finance", "Health", "Food/Cooking"];
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("What are your hobbies?", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: hobbies.map((hobby) {
                  bool isSelected = selectedHobbies.contains(hobby);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        isSelected ? selectedHobbies.remove(hobby) : selectedHobbies.add(hobby);
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? Colors.orange : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: isSelected ? Colors.orange.withOpacity(0.1) : Colors.white,
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ] : [],
                      ),
                      child: Text(
                        hobby,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
          const Text("What is your speaking level?", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          ...['A1', 'A2', 'B1', 'B2'].map((lvl) {
            bool isSelected = selectedLevel == lvl;
            return GestureDetector(
              onTap: () => setState(() => selectedLevel = lvl),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? Colors.orange : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected ? Colors.orange.withOpacity(0.05) : Colors.white,
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ] : [],
                ),
                child: Center(
                  child: Text(
                    lvl, 
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
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
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFF5F6D), Color(0xFFFFC371)]),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF5F6D).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
              onPressed: () {
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
                    SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
                  );
                  return;
                }

                if (_currentPage < 6) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOutCubic,
                  );
                } else {
                  // _currentPage == 6
                  _completeOnboarding();
                  // Navigate to TestVocabularyPage with selected avatar
                  Navigator.pushReplacement(
                    context,
                    _createScaleRoute(
                      TestVocabularyPage(selectedAvatar: selectedAvatar),
                    ),
                  );
                }
              },
              child: const Text("Next", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          
          if (_currentPage == 6) ...[
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2ECC71).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  if (selectedAvatar.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please select an avatar first!"),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }
                  // Navigate to TestVocabularyPage with selected avatar
                  Navigator.push(
                    context,
                    _createSlideRoute(
                      TestVocabularyPage(selectedAvatar: selectedAvatar),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2ECC71),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Test your level", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          ]
        ],
      ),
    );
  }
}

// 🎨 Animated Page Wrapper
class _AnimatedPageWrapper extends StatefulWidget {
  final Widget child;
  
  const _AnimatedPageWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<_AnimatedPageWrapper> createState() => _AnimatedPageWrapperState();
}

class _AnimatedPageWrapperState extends State<_AnimatedPageWrapper> with SingleTickerProviderStateMixin {
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

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: widget.child,
        ),
      ),
    );
  }
}