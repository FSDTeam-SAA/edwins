import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/learning_models.dart';

class ApiService {
  final String baseUrl = "https://your-api-domain.com/v1";
  final String authToken; // Passed after Firebase Auth

  ApiService(this.authToken);

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $authToken',
  };

  // --- HOME DATA ---
  Future<UserProgress> getProgress() async {
    final response = await http.get(Uri.parse('$baseUrl/progress'), headers: _headers);
    if (response.statusCode == 200) {
      return UserProgress.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load progress');
    }
  }

  // --- LESSON LOOP ---
  Future<Map<String, dynamic>> startLesson(String lessonId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/lessons'),
      headers: _headers,
      body: jsonEncode({"lesson_id": lessonId}),
    );
    return jsonDecode(response.body);
  }

  Future<LessonStep> getNextStep(String lessonId) async {
    final response = await http.get(Uri.parse('$baseUrl/lessons/$lessonId/steps/next'), headers: _headers);
    return LessonStep.fromJson(jsonDecode(response.body));
  }

  Future<Map<String, dynamic>> submitAnswer(String lessonId, String stepId, Map<String, dynamic> answer) async {
    final response = await http.post(
      Uri.parse('$baseUrl/lessons/$lessonId/steps/$stepId/answer'),
      headers: _headers,
      body: jsonEncode(answer),
    );
    return jsonDecode(response.body);
  }
}