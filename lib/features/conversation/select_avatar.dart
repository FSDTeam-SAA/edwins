import 'package:flutter/material.dart';
import 'package:language_app/features/home/home_view.dart';
import 'package:provider/provider.dart';
import 'package:language_app/core/providers/avatar_provider.dart';
import 'package:language_app/app/theme/app_style.dart';
import 'package:language_app/features/avatar/avatar_controller.dart';
import 'package:language_app/features/avatar/avatar_view.dart';

class SelectAvatar extends StatefulWidget {
  const SelectAvatar({super.key});

  @override
  State<SelectAvatar> createState() => _SelectAvatarState();
}

class _SelectAvatarState extends State<SelectAvatar> {
  late PageController _pageController;
  int currentPageIndex = 0;

  final AvatarController _claraController = AvatarController();
  final AvatarController _karlController = AvatarController();

  @override
  void initState() {
    super.initState();
    final avatarProvider = Provider.of<AvatarProvider>(context, listen: false);

    // Set initial page based on saved avatar
    final initialIndex = avatarProvider.selectedAvatarName == "Clara" ? 0 : 1;
    currentPageIndex = initialIndex;

    _pageController = PageController(
      viewportFraction: 0.85,
      initialPage: initialIndex,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _claraController.disposeView();
    _karlController.disposeView();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      currentPageIndex = index;
    });

    final avatarProvider = Provider.of<AvatarProvider>(context, listen: false);
    final avatarName = index == 0 ? "Clara" : "Karl";
    avatarProvider.setSelectedAvatar(avatarName);
  }

  void _onAvatarCardTap(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _startConversation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HomeView(),
      ),
    );
  }

  // Helper to get accent color based on name (Optional visual flair)
  Color _getAccentColor() {
    return AppColors.primaryOrange;
  }

  @override
  Widget build(BuildContext context) {
    final selectedAvatarName =
        context.watch<AvatarProvider>().selectedAvatarName;
    final accentColor = _getAccentColor();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.primaryOrange,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Choose Your Companion",
          style: TextStyle(
            color: AppColors.primaryOrange,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Subtitle
            Text(
              'Select your companion for the conversation',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 10),

            // Swipe indicator (from onboarding reference)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_back_ios,
                    size: 14, color: Colors.grey.shade300),
                const SizedBox(width: 8),
                Text(
                  "Swipe to choose",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios,
                    size: 14, color: Colors.grey.shade300),
              ],
            ),

            const SizedBox(height: 20),

            // 3D Avatar Selector (PageView)
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                padEnds: false,
                physics: const BouncingScrollPhysics(),
                children: [
                  // 1. Clara Card
                  _buildAvatarCard(
                    index: 0,
                    name: "Clara",
                    controller: _claraController,
                    isSelected: selectedAvatarName == "Clara",
                    // isSelected: $selectedAvatarName,
                  ),

                  // 2. Karl Card
                  _buildAvatarCard(
                    index: 1,
                    name: "Karl",
                    controller: _karlController,
                    isSelected: selectedAvatarName == "Karl",
                  ),
                ],
              ),
            ),

            // Start Conversation Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              child: GestureDetector(
                onTap: _startConversation,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accentColor,
                        accentColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Start with $selectedAvatarName",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarCard({
    required int index,
    required String name,
    required AvatarController controller,
    required bool isSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: GestureDetector(
        onTap: () => _onAvatarCardTap(index),
        child: AnimatedScale(
          scale: isSelected ? 1.0 : 0.95,
          duration: const Duration(milliseconds: 300),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar Image Area
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    // Optional shadow for depth
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ]
                        : [],
                  ),
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    child: AvatarView(
                      avatarName: name,
                      controller: controller,
                      height: 400,
                      backgroundImagePath: "assets/images/background.png",
                      borderRadius: 0,
                    ),
                  ),
                ),
              ),

              // Name Label Area
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryOrange.withOpacity(0.1)
                      : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                  border: isSelected
                      ? Border.all(
                          color: AppColors.primaryOrange.withOpacity(0.3),
                          width: 1)
                      : Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.primaryOrange
                            : Colors.black87,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.primaryOrange,
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
    );
  }
}
