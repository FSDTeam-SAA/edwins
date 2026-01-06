// lib/models/learning_models.dart

class UserProgress {
  final double overallProgress;
  final Map<String, int> skills;
  final int total;
  final Map<String, int> days;

  UserProgress({
    required this.overallProgress,
    required this.skills,
    required this.total,
    required this.days,
  });

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      overallProgress: (json['overall_progress_percent'] as num).toDouble(),
      skills: Map<String, int>.from(json['skills']),
      total: json['total'] ?? 0,
      days: Map<String, int>.from(json['days']),
    );
  }
}

class LessonStep {
  final String id;
  final String type;
  final String? question;
  final String? text;
  final String? audio;
  final List<Choice>? choices;

  LessonStep({
    required this.id, 
    required this.type,
    required this.question,
    this.text, 
    this.audio, 
    this.choices
  });

  factory LessonStep.fromJson(Map<String, dynamic> json) {
    return LessonStep(
      id: json['step_id'] ?? '',
      type: json['type'] ?? '',
      // Map 'sentence' or 'source_text' from API to our 'question' field
      question: json['sentence'] ?? json['source_text'] ?? '', 
      audio: json['audio'],
      choices: json['choices'] != null 
        ? (json['choices'] as List).map((i) => Choice.fromJson(i)).toList() 
        : null,
    );
  }
}

class Choice {
  final String id;
  final String text;
  final bool isCorrect;
  Choice({required this.id, 
  required this.text,
  this.isCorrect = false});

  factory Choice.fromJson(Map<String, dynamic> json) {
    return Choice(id: json['choice_id'], text: json['text']);
  }
}

class ConversationStep {
  final String id;
  final String prompt;
  final String correctAnswer;

  ConversationStep({
    required this.id,
    required this.prompt,
    required this.correctAnswer,
  });
}