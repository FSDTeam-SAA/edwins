import 'package:flutter/material.dart';

class DifficultyRatingPopup extends StatefulWidget {
  final String word;
  final Function(String difficulty) onRatingSelected;

  const DifficultyRatingPopup({
    super.key,
    required this.word,
    required this.onRatingSelected,
  });

  @override
  State<DifficultyRatingPopup> createState() => _DifficultyRatingPopupState();
}

class _DifficultyRatingPopupState extends State<DifficultyRatingPopup> {
  String? selectedDifficulty;
  String phoneticSpelling = '';

  @override
  void initState() {
    super.initState();
    phoneticSpelling = WordPhonetics.get(widget.word);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFCC80), Color(0xFFFFB74D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Word display
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (phoneticSpelling.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      phoneticSpelling,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                Text(
                  widget.word,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Question - UPDATED HERE
            Text(
              'How difficult is the word "${widget.word}"?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            // Difficulty buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDifficultyButton('Easy'),
                _buildDifficultyButton('Medium'),
                _buildDifficultyButton('Hard'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyButton(String difficulty) {
    final isSelected = selectedDifficulty == difficulty;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDifficulty = difficulty;
        });
        // Wait a moment to show selection, then callback
        Future.delayed(const Duration(milliseconds: 300), () {
          widget.onRatingSelected(difficulty);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF7043) : Colors.white,
            width: 2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFFFF7043).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Text(
          difficulty,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color:
                isSelected ? const Color(0xFFFF7043) : const Color(0xFFFF9800),
          ),
        ),
      ),
    );
  }
}

class WordPhonetics {
  // Normalize keys to lowercase for easier lookup
  static const Map<String, String> dictionary = {
    // Message 1
    'practice': '/ˈpræktɪs/',
    'favourite': '/ˈfeɪvərɪt/',

    // Message 2
    'delicious': '/dɪˈlɪʃəs/',
    'cuisine': '/kwɪˈziːn/',
    'italian': '/ɪˈtæljən/',
    'pizza': '/ˈpiːtsə/',
    'pasta': '/ˈpɑːstə/',

    // Message 3
    'sauce': '/sɔːs/',
    'cook': '/kʊk/',

    // Message 4
    'skill': '/skɪl/',
    'sushi': '/ˈsuːʃi/',
    'challenging': '/ˈtʃælɪndʒɪŋ/',
    'signature': '/ˈsɪɡnətʃə/',
    'dish': '/dɪʃ/',

    // Message 5
    'tasty': '/ˈteɪsti/',
    'try': '/traɪ/',
    'excellent': '/ˈeksələnt/',
  };

  static String get(String word) {
    // Clean the word (lowercase, trim) and lookup
    return dictionary[word.toLowerCase().trim()] ?? '';
  }
}
