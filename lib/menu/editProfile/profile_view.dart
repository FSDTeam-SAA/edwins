import 'package:flutter/material.dart';

// AppColors class (since you're using app_style.dart)
class AppColors {
  static const Color primaryOrange = Color(0xFFFF7A06);
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF609D), Color(0xFFFF7A06)],
  );
}

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController(text: "Jack Shobs");
  final TextEditingController _emailController = TextEditingController(text: "jackshobs@gmail.com");
  final TextEditingController _usernameController = TextEditingController(text: "Jack");
  String? _selectedLevel;
  
  late AnimationController _profileController;
  late AnimationController _fieldsController;
  late AnimationController _saveButtonController;
  
  late Animation<double> _profileScaleAnimation;
  late Animation<double> _profileFadeAnimation;
  late Animation<double> _profileRotateAnimation;
  
  late List<Animation<double>> _fieldFadeAnimations;
  late List<Animation<Offset>> _fieldSlideAnimations;
  
  late Animation<double> _saveButtonScale;
  late Animation<double> _saveButtonFade;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    // Profile animation controller
    _profileController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Fields animation controller
    _fieldsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Save button press controller
    _saveButtonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    // Profile animations
    _profileScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _profileController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _profileFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _profileController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _profileRotateAnimation = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _profileController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Field animations (4 fields + dropdown)
    _fieldFadeAnimations = List.generate(5, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _fieldsController,
          curve: Interval(
            0.0 + (index * 0.1),
            0.4 + (index * 0.1),
            curve: Curves.easeOut,
          ),
        ),
      );
    });

    _fieldSlideAnimations = List.generate(5, (index) {
      return Tween<Offset>(
        begin: const Offset(-0.5, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _fieldsController,
          curve: Interval(
            0.0 + (index * 0.1),
            0.5 + (index * 0.1),
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    });

    // Save button animations
    _saveButtonScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _saveButtonController, curve: Curves.easeInOut),
    );

    _saveButtonFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fieldsController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  void _startAnimations() {
    _profileController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _fieldsController.forward();
    });
  }

  @override
  void dispose() {
    _profileController.dispose();
    _fieldsController.dispose();
    _saveButtonController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primaryOrange),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Profile",
          style: TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            
            // 1. Animated Profile Picture with Edit Badge
            Center(
              child: FadeTransition(
                opacity: _profileFadeAnimation,
                child: RotationTransition(
                  turns: _profileRotateAnimation,
                  child: ScaleTransition(
                    scale: _profileScaleAnimation,
                    child: AnimatedProfilePicture(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 2. Animated Input Fields
            _buildAnimatedField(0, "Name", _nameController),
            _buildAnimatedField(1, "Email", _emailController),
            _buildAnimatedField(2, "User name", _usernameController),
            
            // 3. Animated Level Dropdown
            FadeTransition(
              opacity: _fieldFadeAnimations[3],
              child: SlideTransition(
                position: _fieldSlideAnimations[3],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Level", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    AnimatedDropdown(
                      selectedLevel: _selectedLevel,
                      onChanged: (newValue) {
                        setState(() => _selectedLevel = newValue);
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 4. Animated Save Button
            FadeTransition(
              opacity: _saveButtonFade,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.5),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _fieldsController,
                  curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
                )),
                child: GestureDetector(
                  onTapDown: (_) => _saveButtonController.forward(),
                  onTapUp: (_) {
                    _saveButtonController.reverse();
                    _handleSave();
                  },
                  onTapCancel: () => _saveButtonController.reverse(),
                  child: ScaleTransition(
                    scale: _saveButtonScale,
                    child: Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF609D).withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          "Save",
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedField(int index, String label, TextEditingController controller) {
    return FadeTransition(
      opacity: _fieldFadeAnimations[index],
      child: SlideTransition(
        position: _fieldSlideAnimations[index],
        child: AnimatedInputField(
          label: label,
          controller: controller,
        ),
      ),
    );
  }

  void _handleSave() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Text("Profile saved successfully!"),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        duration: const Duration(milliseconds: 2000),
      ),
    );
    
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) Navigator.pop(context);
    });
  }
}

// Animated Profile Picture Widget
class AnimatedProfilePicture extends StatefulWidget {
  const AnimatedProfilePicture({super.key});

  @override
  State<AnimatedProfilePicture> createState() => _AnimatedProfilePictureState();
}

class _AnimatedProfilePictureState extends State<AnimatedProfilePicture>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulse ring
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryOrange.withOpacity(
                            0.3 * (2.2 - _pulseAnimation.value),
                          ),
                          width: 3,
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              // Profile picture
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryOrange.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const CircleAvatar(
                  radius: 60,
                  backgroundImage: AssetImage("assets/profile_user.png"),
                ),
              ),
              
              // Edit badge with pulse
              Positioned(
                bottom: 0,
                right: 0,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryOrange.withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 20),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Animated Input Field
class AnimatedInputField extends StatefulWidget {
  final String label;
  final TextEditingController controller;

  const AnimatedInputField({
    super.key,
    required this.label,
    required this.controller,
  });

  @override
  State<AnimatedInputField> createState() => _AnimatedInputFieldState();
}

class _AnimatedInputFieldState extends State<AnimatedInputField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppColors.primaryOrange.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 1,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.pinkAccent.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryOrange, width: 2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

// Animated Dropdown
class AnimatedDropdown extends StatefulWidget {
  final String? selectedLevel;
  final ValueChanged<String?> onChanged;

  const AnimatedDropdown({
    super.key,
    required this.selectedLevel,
    required this.onChanged,
  });

  @override
  State<AnimatedDropdown> createState() => _AnimatedDropdownState();
}

class _AnimatedDropdownState extends State<AnimatedDropdown> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isOpen 
              ? AppColors.primaryOrange 
              : Colors.orange.withOpacity(0.5),
          width: _isOpen ? 2 : 1,
        ),
        boxShadow: _isOpen
            ? [
                BoxShadow(
                  color: AppColors.primaryOrange.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ]
            : [],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: widget.selectedLevel,
          hint: const Text("Select your level"),
          isExpanded: true,
          icon: AnimatedRotation(
            turns: _isOpen ? 0.5 : 0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: const Icon(Icons.keyboard_arrow_down, color: Colors.blueGrey),
          ),
          items: ["Beginner", "Intermediate", "Advanced"].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (value) {
            widget.onChanged(value);
            setState(() => _isOpen = false);
          },
          onTap: () => setState(() => _isOpen = true),
        ),
      ),
    );
  }
}