import 'package:flutter/foundation.dart';

/// Manages vocabulary lesson state and quiz logic
class VocabularyProvider extends ChangeNotifier {
  int _currentQuestionIndex = 0;
  String? _selectedOption;
  bool _showError = false;
  bool _showTranslation = false;
  String _translatedText = '';
  int _correctAnswers = 0;
  int _totalAttempts = 0;

  // Questions data - can be loaded from repository later
  List<Map<String, dynamic>> _questions = [];

  // Getters
  int get currentQuestionIndex => _currentQuestionIndex;
  String? get selectedOption => _selectedOption;
  bool get showError => _showError;
  bool get showTranslation => _showTranslation;
  String get translatedText => _translatedText;
  int get correctAnswers => _correctAnswers;
  int get totalAttempts => _totalAttempts;
  int get totalQuestions => _questions.length;
  bool get isLastQuestion => _currentQuestionIndex >= _questions.length - 1;
  double get accuracy =>
      _totalAttempts > 0 ? _correctAnswers / _totalAttempts : 0.0;

  Map<String, dynamic>? get currentQuestion {
    if (_questions.isEmpty || _currentQuestionIndex >= _questions.length) {
      return null;
    }
    return _questions[_currentQuestionIndex];
  }

  /// Load questions for the vocabulary lesson
  void loadQuestions(List<Map<String, dynamic>> questions) {
    _questions = questions;
    _currentQuestionIndex = 0;
    _selectedOption = null;
    _showError = false;
    _showTranslation = false;
    _correctAnswers = 0;
    _totalAttempts = 0;
    notifyListeners();
  }

  /// Select an option
  void selectOption(String option) {
    _selectedOption = option;
    notifyListeners();
  }

  /// Check answer and proceed
  bool checkAnswer() {
    if (_selectedOption == null || currentQuestion == null) return false;

    final correctAnswer = currentQuestion!['correctAnswer'];
    _totalAttempts++;

    if (_selectedOption != correctAnswer) {
      _showError = true;
      notifyListeners();
      return false;
    } else {
      _correctAnswers++;
      notifyListeners();
      return true;
    }
  }

  /// Move to next question
  void nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      _currentQuestionIndex++;
      _selectedOption = null;
      _showError = false;
      _showTranslation = false;
      notifyListeners();
    }
  }

  /// Retry current question after error
  void retryQuestion() {
    _showError = false;
    _selectedOption = null;
    notifyListeners();
  }

  /// Toggle translation visibility
  void toggleTranslation(String? questionText) {
    _showTranslation = !_showTranslation;
    if (_showTranslation && questionText != null) {
      _translatedText = _translateText(questionText);
    }
    notifyListeners();
  }

  /// Simple translation helper (can be replaced with actual translation service)
  String _translateText(String text) {
    final translations = {
      'Die Katze frisst _____': 'The cat eats _____',
      // Add more translations as needed
    };
    return translations[text] ?? 'Translation not available';
  }

  /// Reset the vocabulary lesson
  void reset() {
    _currentQuestionIndex = 0;
    _selectedOption = null;
    _showError = false;
    _showTranslation = false;
    _translatedText = '';
    _correctAnswers = 0;
    _totalAttempts = 0;
    notifyListeners();
  }

  /// Get results summary
  Map<String, dynamic> getResults() {
    return {
      'totalQuestions': totalQuestions,
      'correctAnswers': _correctAnswers,
      'totalAttempts': _totalAttempts,
      'accuracy': accuracy,
      'score': (accuracy * 100).round(),
    };
  }
}
