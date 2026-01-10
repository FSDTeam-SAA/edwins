import 'package:language_app/core/viewmodels/base_viewmodel.dart';
import 'package:language_app/core/models/learning_models.dart';
import 'package:language_app/core/data/repository.dart';

/// ViewModel for Learning Progress feature following MVVM pattern
/// Manages user progress and statistics
class LearningProgressViewModel extends BaseViewModel {
  final ILearningRepository _repository;

  UserProgress? _userProgress;
  bool _hasStartedLearning = false;

  // Getters
  UserProgress? get userProgress => _userProgress;
  bool get hasStartedLearning => _hasStartedLearning;

  double get overallProgress => _userProgress?.overallProgress ?? 0.0;
  Map<String, int> get skills => _userProgress?.skills ?? {};
  int get totalWords => _userProgress?.total ?? 0;
  Map<String, int> get weeklyActivity => _userProgress?.days ?? {};

  LearningProgressViewModel(this._repository);

  /// Fetch user progress from repository
  Future<void> fetchProgress() async {
    await executeAsync(
      () async {
        _userProgress = await _repository.fetchHomeProgress();
      },
      errorMessage: 'Failed to load progress',
    );
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
      safeNotifyListeners();
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
      safeNotifyListeners();
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
      safeNotifyListeners();
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
      safeNotifyListeners();
    }
  }

  /// Mark that user has started learning
  void startLearning() {
    _hasStartedLearning = true;
    safeNotifyListeners();
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
      safeNotifyListeners();
    }
  }

  /// Reset progress
  void resetProgress() {
    _userProgress = null;
    _hasStartedLearning = false;
    clearError();
    safeNotifyListeners();
  }

  /// Refresh progress data
  Future<void> refresh() async {
    await fetchProgress();
  }
}
