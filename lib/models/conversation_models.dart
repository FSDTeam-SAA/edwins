// lib/models/conversation_models.dart

class ConversationThread {
  final String threadId;
  final String avatarId;
  final String lang;
  final List<SuggestedVocab> suggestedVocab;
  final String latestMessageId;

  ConversationThread({
    required this.threadId,
    required this.avatarId,
    required this.lang,
    required this.suggestedVocab,
    required this.latestMessageId,
  });

  factory ConversationThread.fromJson(Map<String, dynamic> json) {
    return ConversationThread(
      threadId: json['thread_id'],
      avatarId: json['avatar_id'],
      lang: json['lang'],
      suggestedVocab: (json['suggested_vocab'] as List)
          .map((v) => SuggestedVocab.fromJson(v))
          .toList(),
      latestMessageId: json['latest_message_id'],
    );
  }
}

class SuggestedVocab {
  final String vocabId;
  final String text;
  final String translation;

  SuggestedVocab({
    required this.vocabId,
    required this.text,
    required this.translation,
  });

  factory SuggestedVocab.fromJson(Map<String, dynamic> json) {
    return SuggestedVocab(
      vocabId: json['vocab_id'],
      text: json['text'],
      translation: json['translation'],
    );
  }
}

class ConversationMessage {
  final String id;
  final String role; // 'user' or 'avatar'
  final String text;
  final Map<String, String>? translation;
  final String? audio;
  final Map<String, String>? visemes;
  final MessageCorrection? corrections;
  final DateTime createdAt;

  ConversationMessage({
    required this.id,
    required this.role,
    required this.text,
    this.translation,
    this.audio,
    this.visemes,
    this.corrections,
    required this.createdAt,
  });

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    return ConversationMessage(
      id: json['id'],
      role: json['role'],
      text: json['text'],
      translation: json['translation'] != null
          ? Map<String, String>.from(json['translation'])
          : null,
      audio: json['audio'],
      visemes: json['visemes'] != null
          ? Map<String, String>.from(json['visemes'])
          : null,
      corrections: json['corrections'] != null
          ? MessageCorrection.fromJson(json['corrections'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  bool get isUser => role == 'user';
  bool get isAvatar => role == 'avatar';
}

class MessageCorrection {
  final String correctedText;
  final List<TextHighlight> highlights;

  MessageCorrection({
    required this.correctedText,
    required this.highlights,
  });

  factory MessageCorrection.fromJson(Map<String, dynamic> json) {
    return MessageCorrection(
      correctedText: json['corrected_text'],
      highlights: (json['highlights'] as List)
          .map((h) => TextHighlight.fromJson(h))
          .toList(),
    );
  }
}

class TextHighlight {
  final String from;
  final String to;
  final String reason;

  TextHighlight({
    required this.from,
    required this.to,
    required this.reason,
  });

  factory TextHighlight.fromJson(Map<String, dynamic> json) {
    return TextHighlight(
      from: json['from'],
      to: json['to'],
      reason: json['reason'],
    );
  }
}

class MessagesResponse {
  final List<ConversationMessage> messages;
  final String? nextBefore;

  MessagesResponse({
    required this.messages,
    this.nextBefore,
  });

  factory MessagesResponse.fromJson(Map<String, dynamic> json) {
    return MessagesResponse(
      messages: (json['messages'] as List)
          .map((m) => ConversationMessage.fromJson(m))
          .toList(),
      nextBefore: json['next_before'],
    );
  }
}