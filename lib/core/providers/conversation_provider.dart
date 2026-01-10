import 'package:flutter/foundation.dart';
import 'package:language_app/core/utils/mock_data.dart';

/// Manages conversation state and business logic
class ConversationProvider extends ChangeNotifier {
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

  /// Load conversation from data source
  Future<void> loadConversation() async {
    final messageData = MockData.conversationMessages;

    _suggestedVocab = List<Map<String, dynamic>>.from(
      MockData.conversationThread['suggested_vocab'],
    );
    _messages = List<Map<String, dynamic>>.from(messageData['messages']);
    _messageCount = _messages.where((m) => m['role'] == 'user').length;

    notifyListeners();
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

    notifyListeners();

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
        notifyListeners();
      } else {
        debugPrint("Conversation finished. User can check results.");
      }
    });
  }

  /// Start recording
  void startRecording() {
    _isRecording = true;
    notifyListeners();
  }

  /// Stop recording and send voice message
  void stopRecording() {
    _isRecording = false;
    notifyListeners();

    // Send voice message after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      sendMessage("", isVoice: true);
    });
  }

  /// Cancel recording without sending
  void cancelRecording() {
    _isRecording = false;
    notifyListeners();
  }

  /// Reset conversation state
  void resetConversation() {
    _messages.clear();
    _suggestedVocab.clear();
    _messageCount = 0;
    _isRecording = false;
    notifyListeners();
  }

  /// Add a suggested vocab word to the conversation
  void addSuggestedVocab(Map<String, dynamic> vocab) {
    _suggestedVocab.add(vocab);
    notifyListeners();
  }

  /// Remove a suggested vocab word
  void removeSuggestedVocab(String vocabId) {
    _suggestedVocab.removeWhere((v) => v['vocab_id'] == vocabId);
    notifyListeners();
  }
}
