import 'package:flutter/foundation.dart';
import 'package:language_app/core/models/learning_models.dart';
import 'package:language_app/core/data/repository.dart';

/// Manages user learning progress and statistics
class LearningProgressProvider extends ChangeNotifier {
  final ILearningRepository _repository;

  UserProgress? _userProgress;
  bool _isLoading = false;
  String? _error;
  bool _hasStartedLearning = false;

  // Getters
  UserProgress? get userProgress => _userProgress;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasStartedLearning => _hasStartedLearning;

  double get overallProgress => _userProgress?.overallProgress ?? 0.0;
  Map<String, int> get skills => _userProgress?.skills ?? {};
  int get totalWords => _userProgress?.total ?? 0;
  Map<String, int> get weeklyActivity => _userProgress?.days ?? {};

  LearningProgressProvider(this._repository);

  /// Fetch user progress from repository
  Future<void> fetchProgress() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _userProgress = await _repository.fetchHomeProgress();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error fetching progress: $e');
    }
  }

  /// Update a specific skill score
  void updateSkill(String skillName, int newScore) {
    if (_userProgress != null) {
      final updatedSkills = Map<String, int>.from(_userProgress!.skills);
      updatedSkills[skillName] = newScore;

      _userProgress = UserProgress(
        overallProgress: _userProgress!.overallProgress,
        skills: updatedSkills,
        total: _userProgress!.total,
        days: _userProgress!.days,
      );
      notifyListeners();
    }
  }

  /// Update multiple skills at once
  void updateSkills(Map<String, int> newSkills) {
    if (_userProgress != null) {
      final updatedSkills = Map<String, int>.from(_userProgress!.skills);
      updatedSkills.addAll(newSkills);

      _userProgress = UserProgress(
        overallProgress: _userProgress!.overallProgress,
        skills: updatedSkills,
        total: _userProgress!.total,
        days: _userProgress!.days,
      );
      notifyListeners();
    }
  }

  /// Increment total words learned
  void incrementTotalWords(int count) {
    if (_userProgress != null) {
      _userProgress = UserProgress(
        overallProgress: _userProgress!.overallProgress,
        skills: _userProgress!.skills,
        total: _userProgress!.total + count,
        days: _userProgress!.days,
      );
      notifyListeners();
    }
  }

  /// Update daily activity
  void updateDailyActivity(String day, int count) {
    if (_userProgress != null) {
      final updatedDays = Map<String, int>.from(_userProgress!.days);
      updatedDays[day] = count;

      _userProgress = UserProgress(
        overallProgress: _userProgress!.overallProgress,
        skills: _userProgress!.skills,
        total: _userProgress!.total,
        days: updatedDays,
      );
      notifyListeners();
    }
  }

  /// Mark that user has started learning
  void startLearning() {
    _hasStartedLearning = true;
    notifyListeners();
  }

  /// Calculate overall progress based on skills
  void recalculateProgress() {
    if (_userProgress != null && _userProgress!.skills.isNotEmpty) {
      final skillValues = _userProgress!.skills.values;
      final average = skillValues.reduce((a, b) => a + b) / skillValues.length;

      _userProgress = UserProgress(
        overallProgress: average,
        skills: _userProgress!.skills,
        total: _userProgress!.total,
        days: _userProgress!.days,
      );
      notifyListeners();
    }
  }

  /// Reset progress (for testing or user reset)
  void resetProgress() {
    _userProgress = null;
    _hasStartedLearning = false;
    _error = null;
    notifyListeners();
  }

  /// Refresh progress data
  Future<void> refresh() async {
    await fetchProgress();
  }
}
