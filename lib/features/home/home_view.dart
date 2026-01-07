import 'package:flutter/material.dart';
import 'package:language_app/features/conversation/conversation_chat.dart';
import 'package:language_app/features/conversation/demo/demo_conversation.dart';
// import 'package:language_app/features/conversation/demo/demo_conversation.dart';
import 'package:language_app/features/conversation/demo/demo_vocabulary.dart';
import 'package:language_app/core/providers/avatar_provider.dart';
import 'package:provider/provider.dart';
import 'package:language_app/app/theme/app_style.dart';
import 'package:language_app/core/utils/mock_data.dart';
import 'package:language_app/core/widgets/radar_chart.dart';
import 'package:language_app/core/widgets/weekly_activity_chart.dart';
import 'package:language_app/features/profile/menu_view.dart';

class HomeView extends StatefulWidget {
  final bool initialHasStartedLearning;

  const HomeView({super.key, this.initialHasStartedLearning = false});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late bool hasStartedLearning;

  @override
  void initState() {
    super.initState();
    hasStartedLearning = widget.initialHasStartedLearning;
  }

  Future<Map<String, dynamic>> _fetchHomeData() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return MockData.homeProgress;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchHomeData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryPink),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final data = snapshot.data!;
          // Safely cast types
          final skills = Map<String, int>.from(data['skills']);
          final days = Map<String, int>.from(data['days']);
          final int overallProgress = data['overall_progress_percent'];
          const int totalWords = 80; // Hardcoded to match UI screenshot example
          final avatarProvider =
              Provider.of<AvatarProvider>(context, listen: false);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Greeting (Green Text)
                const Text(
                  "Hello! Jack",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50), // Matches UI Green
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 20),
                // --- START / CONTINUE BUTTON ---
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      if (!hasStartedLearning) {
                        // --- CASE 1: START LEARNING ---
                        // Update state and go to Dummy Page
                        setState(() {
                          hasStartedLearning = true;
                        });
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DemoVocabulary(
                                  selectedAvatar:
                                      avatarProvider.selectedAvatarName),
                            ));
                      } else {
                        // --- CASE 2: CONTINUE LEARNING ---
                        // Go directly to ConversationChat
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ConversationChat(
                              selectedAvatarName:
                                  avatarProvider.selectedAvatarName,
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    // 3. Conditional Text Rendering
                    child: Text(
                      hasStartedLearning
                          ? "Continue Learning"
                          : "Start Learning",
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                // 3. Gradient Progress Card
                _buildProgressCard(
                  skills: skills,
                  totalScore: overallProgress.toString(),
                ),

                // 4. Weekly Activity Card
                _buildWeeklyActivityCard(
                  title: "Weekly Learn Word",
                  trailing: "$totalWords",
                  child: SizedBox(
                    height: 170, // Fixed height for the chart area
                    child: WeeklyActivityChart(
                      days: days,
                      totalCount: totalWords,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                _buildToggleSection(),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  /// Specialized Builder for the "Your Progress" Gradient Card
  Widget _buildProgressCard({
    required Map<String, int> skills,
    required String totalScore,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      // 1. Gradient Border Container
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromRGBO(255, 96, 157, 0.4),
            Color.fromRGBO(255, 122, 6, 0.4)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(1), // Border width
      child: Container(
        padding: const EdgeInsets.all(24),
        // 2. Inner Gradient Background
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color.fromRGBO(255, 240, 245, 1), // Very light pink
              Color.fromRGBO(255, 248, 240, 1) // Very light orange
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(19),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Your Progress", style: AppTypography.cardTitle),
                    SizedBox(height: 6),
                    Text(
                      "Your progress after 5 lessons",
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
                Text(
                  "$totalScore%",
                  style: const TextStyle(
                    color: AppColors.primaryOrange,
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            // Radar Chart
            SizedBox(
              height: 250,
              child: ProgressRadarChart(skills: skills),
            ),
          ],
        ),
      ),
    );
  }

  /// Generic Builder for the Weekly Activity Card
  Widget _buildWeeklyActivityCard({
    required String title,
    required String trailing,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5),
        boxShadow: [
          BoxShadow(
            color:
                const Color(0xFF009DFF).withOpacity(0.05), // Blue tint shadow
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTypography.cardTitle),
              Text(
                trailing,
                style: const TextStyle(
                  color: Color(0xFF009DFF), // Specific Blue from UI
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      toolbarHeight: 50,
      backgroundColor: Colors.white,
      automaticallyImplyLeading: false,
      titleSpacing: 24,
      title: Row(
        children: [
          // Logo Image
          Image.asset(
            "assets/images/logo.png", // Ensure this image contains the icon + "LUNGULU" text
            height: 40,
            fit: BoxFit.contain,
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 24.0),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MenuView()),
              );
            },
            child: const Icon(Icons.menu,
                color: AppColors.primaryOrange, size: 32),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleSection() {
    return Row(
      children: [
        // 1. Conversation Button (Outlined, White BG)
        Expanded(
          child: GestureDetector(
            onTap: () {
              // Get the selected avatar from provider
              final avatarProvider =
                  Provider.of<AvatarProvider>(context, listen: false);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DemoConversation(
                    selectedAvatar: avatarProvider.selectedAvatarName,
                  ),
                ),
              );
            },
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryOrange, width: 1.5),
              ),
              child: const Center(
                child: Text(
                  "Conversation",
                  style: TextStyle(
                    color: AppColors.primaryOrange,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // 2. Vocabulary Button (Gradient BG)
        Expanded(
          child: GestureDetector(
            onTap: () {
              // This is the current page, so we don't navigate or we just refresh
              //  Navigator.pushNamed(context, '/vocab-loop');
              final avatarProvider =
                  Provider.of<AvatarProvider>(context, listen: false);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DemoVocabulary(
                        selectedAvatar: avatarProvider.selectedAvatarName),
                  ));
            },
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8A65), Color(0xFFFF5252)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryOrange.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  "Vocabulary",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
