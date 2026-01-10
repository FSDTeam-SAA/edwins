import 'package:language_app/core/viewmodels/base_viewmodel.dart';
import 'package:language_app/core/utils/mock_data.dart';

/// ViewModel for Conversation feature following MVVM pattern
/// Manages conversation state and business logic
class ConversationViewModel extends BaseViewModel {
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _suggestedVocab = [];
  bool _isRecording = false;
  int _messageCount = 0;
  final int _maxMessages = 5;

  // Getters
  List<Map<String, dynamic>> get messages => List.unmodifiable(_messages);
  List<Map<String, dynamic>> get suggestedVocab =>
      List.unmodifiable(_suggestedVocab);
  bool get isRecording => _isRecording;
  int get messageCount => _messageCount;
  int get maxMessages => _maxMessages;
  bool get isConversationComplete => _messageCount >= _maxMessages;
  double get progress => _messageCount / _maxMessages;

  /// Load conversation data
  Future<void> loadConversation() async {
    await executeAsync(
      () async {
        final messageData = MockData.conversationMessages;

        _suggestedVocab = List<Map<String, dynamic>>.from(
          MockData.conversationThread['suggested_vocab'],
        );
        _messages = List<Map<String, dynamic>>.from(messageData['messages']);
        _messageCount = _messages.where((m) => m['role'] == 'user').length;

        safeNotifyListeners();
      },
      errorMessage: 'Failed to load conversation',
    );
  }

  /// Send a message (text or voice)
  void sendMessage(String text, {bool isVoice = false}) {
    if (text.trim().isEmpty && !isVoice) return;

    _messages.add({
      "id": "m_user_${DateTime.now().millisecondsSinceEpoch}",
      "role": "user",
      "text": text,
      "is_voice": isVoice,
      "audio": isVoice ? "assets/audio/user_voice.mp3" : null,
      "created_at": DateTime.now().toIso8601String(),
    });
    _messageCount++;

    safeNotifyListeners();

    // Trigger avatar response
    _getAvatarResponse();
  }

  /// Get avatar response based on conversation progress
  void _getAvatarResponse() {
    Future.delayed(const Duration(milliseconds: 1000), () {
      int currentAvatarCount =
          _messages.where((m) => m['role'] == 'avatar').length;

      final response = MockData.getNextConversationStep(currentAvatarCount);

      if (response != null) {
        _messages.add(response);
        safeNotifyListeners();
      }
    });
  }

  /// Start recording
  void startRecording() {
    _isRecording = true;
    safeNotifyListeners();
  }

  /// Stop recording and send voice message
  void stopRecording() {
    _isRecording = false;
    safeNotifyListeners();

    Future.delayed(const Duration(milliseconds: 300), () {
      sendMessage("", isVoice: true);
    });
  }

  /// Cancel recording without sending
  void cancelRecording() {
    _isRecording = false;
    safeNotifyListeners();
  }

  /// Reset conversation state
  void resetConversation() {
    _messages.clear();
    _suggestedVocab.clear();
    _messageCount = 0;
    _isRecording = false;
    clearError();
    safeNotifyListeners();
  }

  /// Add a suggested vocab word
  void addSuggestedVocab(Map<String, dynamic> vocab) {
    _suggestedVocab.add(vocab);
    safeNotifyListeners();
  }

  /// Remove a suggested vocab word
  void removeSuggestedVocab(String vocabId) {
    _suggestedVocab.removeWhere((v) => v['vocab_id'] == vocabId);
    safeNotifyListeners();
  }
}
