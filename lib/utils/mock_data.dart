class MockData {
  // Home Progress Mock
  static Map<String, dynamic> homeProgress = {
    "overall_progress_percent": 75,
    "skills": {
      "Grammar": 10,
      "Speaking": 20,
      "Listening": 15,
      "Conversation": 20,
      "Vocabulary": 10,
    },
    "total": 1250,
    "days": {"Mon": 10, "Tue": 35, "Wed": 15, "Thu": 40, "Fri": 30}
  };

  // Listening MC Step Mock
  static Map<String, dynamic> listeningStep = {
    "step_id": "st_1",
    "type": "listening_mc",
    "audio": "assets/audio/cat.mp3",
    "choices": [
      {"choice_id": "c1", "text": "Cat"},
      {"choice_id": "c2", "text": "Cap"},
      {"choice_id": "c3", "text": "Car"},
      {"choice_id": "c4", "text": "Can"}
    ]
  };

  static Map<String, dynamic> conversationStep = {
    "step_id": "conv_1",
    "prompt": "The cat eats chicken.",
    "correct_answer": "Die Katze frisst Hühnchen"
  };

  // Conversation Thread Mock (matches API structure)
  static Map<String, dynamic> conversationThread = {
    "thread_id": "thr_abc",
    "avatar_id": "clara",
    "lang": "en",
    "suggested_vocab": [
      {"vocab_id": "v1", "text": "Recommend", "translation": "empfehlen"},
      {"vocab_id": "v2", "text": "Delicious", "translation": "lecker"},
      {"vocab_id": "v3", "text": "Restaurant", "translation": "Restaurant"}
    ],
    "latest_message_id": "m_120"
  };

  // Initial conversation messages
  static Map<String, dynamic> conversationMessages = {
    "messages": [
      {
        "id": "m_120",
        "role": "avatar",
        "text": "Hello! I'm excited to **practice** with you today. What's your **favourite place** to eat?",
        "translation": {
          "de": "Hallo! Ich **freue** mich darauf, heute mit dir zu üben. Was ist dein Lieblingsort zum **Essen**?"
        },
        // "audio": "assets/audio/greeting.mp3",
        "visemes": {"aa": "0:01"},
        "created_at": "2025-12-28T10:12:00Z"
      }
    ],
    "next_before": null
  };

  // Mock avatar data
  // static Map<String, dynamic> avatarData = {
  //   "id": "clara",
  //   "name": "Clara",
  //   "image": "assets/images/clara_avatar.png",
  //   "language": "English"
  // };

  // Mock response for user message submission
  static Map<String, dynamic> mockMessageResponse(String userText) {
    return {
      "id": "m_${DateTime.now().millisecondsSinceEpoch}",
      "role": "avatar",
      "text": "That sounds wonderful! I love visiting Cafe Maro. It's a beautiful restaurant with delicious food and I always recommend it.",
      "translation": {
        "de": "Das klingt wunderbar! Ich besuche gerne Cafe Maro. Es ist ein schönes Restaurant mit leckerem Essen und ich empfehle es immer."
      },
      "audio": "assets/audio/response.mp3",
      "visemes": {"aa": "0:01"},
      "created_at": DateTime.now().toIso8601String()
    };
  }

  // Mock correction for user text
  static Map<String, dynamic> getUserCorrection(String text) {
    // Simple mock: if text contains grammar issues
    if (text.toLowerCase().contains("go") && !text.contains("went")) {
      return {
        "corrected_text": text.replaceAll("go", "went"),
        "highlights": [
          {"from": "go", "to": "went", "reason": "past tense"}
        ]
      };
    }
    return {
      "corrected_text": text,
      "highlights": []
    };
  }
}