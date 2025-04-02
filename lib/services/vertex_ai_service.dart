import 'dart:convert';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class VertexAIService {
  static final VertexAIService _instance = VertexAIService._internal();
  factory VertexAIService() => _instance;
  VertexAIService._internal();

  late final ServiceAccountCredentials _credentials;
  late final AuthClient _client;
  late final String _projectId;
  bool _isInitialized = false;

  Future<void> initialize(Map<String, dynamic> credentialsMap) async {
    if (_isInitialized) return;

    try {
      _credentials = ServiceAccountCredentials.fromJson(credentialsMap);
      _projectId = credentialsMap['project_id'];
      
      _client = await clientViaServiceAccount(
        _credentials,
        [
          'https://www.googleapis.com/auth/cloud-platform',
        ],
      );
      
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize Vertex AI service: $e');
    }
  }

  Future<String> generateText(String prompt) async {
    if (!_isInitialized) {
      throw Exception('VertexAIService not initialized');
    }

    final endpoint = 'https://us-central1-aiplatform.googleapis.com/v1/projects/$_projectId/locations/us-central1/publishers/google/models/gemini-2.0-flash-001:generateContent';

    try {
      final response = await _client.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'contents': [{
            'role': 'user',
            'parts': [{
              'text': prompt
            }]
          }],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 1024,
            'topP': 0.8,
            'topK': 40
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          return data['candidates'][0]['content']['parts'][0]['text'];
        }
        throw Exception('No response from Vertex AI');
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Error from Vertex AI: ${errorData['error']?.toString() ?? response.body}');
      }
    } catch (e) {
      throw Exception('Error generating text: $e');
    }
  }

  void dispose() {
    if (_isInitialized) {
      _client.close();
    }
  }
} 