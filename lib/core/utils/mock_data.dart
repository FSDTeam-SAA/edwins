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
  static List<Map<String, dynamic>> conversationScript = [
    // Message 1 (Initial - already in conversationMessages)
    {
      "text":
          "Hello! I'm excited to **practice** with you today. What's your **favourite** Place to eat?",
      "translation": {
        "de":
            "Hallo! Ich **freue** mich darauf, heute mit dir zu üben. Was ist dein Lieblingsort zum **Essen**?"
      }
    },
    // Message 2
    {
      "text":
          "That sounds **delicious**! I usually prefer **Italian** **cuisine**. Do you like **pizza** or **pasta**?",
      "translation": {
        "de":
            "Das klingt **lecker**! Ich bevorzuge normalerweise **italienische** **Küche**. Magst du **Pizza** oder **Pasta**?"
      }
    },
    // Message 3
    {
      "text":
          "I agree! A good **sauce** makes all the difference. How often do you **cook** at home?",
      "translation": {
        "de":
            "Ich stimme zu! Eine gute **Soße** macht den Unterschied. Wie oft **kochst** du zu Hause?"
      }
    },
    // Message 4
    {
      "text":
          "Cooking is a great **skill**. I am currently learning to make **sushi**. It is quite **challenging**. Do you have a **signature** **dish**?",
      "translation": {
        "de":
            "Kochen ist eine tolle **Fähigkeit**. Ich lerne gerade, **Sushi** zu machen. Es ist ziemlich **anspruchsvoll**. Hast du ein **Lieblingsgericht**?"
      }
    },
    // Message 5 (Final)
    {
      "text":
          "That sounds **tasty**! I would love to **try** it someday. Let's wrap up for now. You did **excellent** today!",
      "translation": {
        "de":
            "Das klingt **lecker**! Ich würde es gerne eines Tages **probieren**. Lass uns für heute Schluss machen. Du warst heute **ausgezeichnet**!"
      }
    },
  ];

  static Map<String, dynamic> conversationMessages = {
    "messages": [
      {
        "id": "m_120",
        "role": "avatar",
        "text": conversationScript[0]['text'], // Use script index 0
        "translation": conversationScript[0]['translation'],
        "visemes": {"aa": "0:01"},
        "created_at": "2025-12-28T10:12:00Z"
      }
    ],
    "next_before": null
  };

  static Map<String, dynamic>? getNextConversationStep(int nextIndex) {
    // If we have run out of script, return null (Conversation End)
    if (nextIndex >= conversationScript.length) return null;

    final scriptData = conversationScript[nextIndex];

    return {
      "id": "m_avatar_${DateTime.now().millisecondsSinceEpoch}",
      "role": "avatar", // Always avatar response
      "text": scriptData['text'],
      "translation": scriptData['translation'],
      // "audio": "assets/audio/response.mp3", // Mock audio
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
    return {"corrected_text": text, "highlights": []};
  }
}
