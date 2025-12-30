import '../../models/learning_models.dart';
import '../../utils/mock_data.dart';

abstract class ILearningRepository {
  Future<UserProgress> fetchHomeProgress();
  Future<LessonStep> fetchNextStep(String lessonId);
  Future<ConversationStep> fetchConversation(String id);
}

class MockLearningRepository implements ILearningRepository {
  @override
  Future<UserProgress> fetchHomeProgress() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    return UserProgress.fromJson(MockData.homeProgress);
  }

  @override
  Future<LessonStep> fetchNextStep(String lessonId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Logic to return Vocabulary 1 or Vocabulary 2 based on the ID
    if (lessonId == "lesson_2") {
      return _fetchListeningStep();
    }
    

    // Default: Vocabulary 1 (Sentence Completion)
    return LessonStep(
      id: "step_1",
      type: "complete_mc",
      question: "Die Katze frisst _______",
      choices: [
        Choice(id: "1", text: "Katze", isCorrect: false),
        Choice(id: "2", text: "Frisst", isCorrect: false),
        Choice(id: "3", text: "Hähnchen", isCorrect: true),
        Choice(id: "4", text: "Die", isCorrect: false),
      ],
    );
  }

  // Private helper for the Vocabulary 2 UI (Listening Grid)
  LessonStep _fetchListeningStep() {
    return LessonStep(
      id: "st_1",
      type: "listening_mc", // triggers the Word Grid UI
      question: "Select the right word",
      audio: "cat", // String for Text-to-Speech
      choices: [
        Choice(id: "c1", text: "Cat", isCorrect: true),
        Choice(id: "c2", text: "Cap", isCorrect: false),
        Choice(id: "c3", text: "Car", isCorrect: false),
        Choice(id: "c4", text: "Can", isCorrect: false),
      ],
    );
  }
  @override
  Future<ConversationStep> fetchConversation(String id) async {
      await Future.delayed(const Duration(milliseconds: 600));

      // Now using the mock data for conversation step
      return ConversationStep(
        id: MockData.conversationStep['step_id'],
        prompt: MockData.conversationStep['prompt'],
        correctAnswer: MockData.conversationStep['correct_answer'],
      );
    }
}
