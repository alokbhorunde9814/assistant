import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/api_config.dart';

class GeminiService {
  final String apiKey;

  GeminiService({String? apiKey}) : apiKey = apiKey ?? ApiConfig.geminiApiKey;

  Future<Map<String, dynamic>> generateFeedback(String textFilePath) async {
    try {
      // Read the text file
      final file = File(textFilePath);
      final text = await file.readAsString();

      // Initialize the model
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
      );

      // Create the prompt
      final prompt = '''
      Please analyze the following text extracted from a PDF document and provide feedback in the following format:

      SCORE: [Give a percentage score between 0-100]

      FEEDBACK POINTS:
      1. [First point]
      2. [Second point]
      3. [Third point]
      [Add more points as needed]

      SUGGESTED IMPROVEMENTS:
      [List specific improvements that could be made]

      DETAILED ANALYSIS:
      [Provide a detailed analysis of the content]

      Text to analyze:
      $text
      ''';

      // Generate content
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      final feedbackText = response.text ?? 'No feedback generated';

      // Parse the feedback into structured format
      final Map<String, dynamic> structuredFeedback = {
        'rawFeedback': feedbackText,
      };

      // Extract score
      final scoreMatch = RegExp(r'SCORE:\s*(\d+)').firstMatch(feedbackText);
      if (scoreMatch != null) {
        structuredFeedback['score'] = int.parse(scoreMatch.group(1)!);
      }

      // Extract feedback points
      final pointsMatch = RegExp(r'FEEDBACK POINTS:\s*([\s\S]*?)(?=SUGGESTED IMPROVEMENTS:)').firstMatch(feedbackText);
      if (pointsMatch != null) {
        final pointsText = pointsMatch.group(1)!;
        final points = pointsText.split('\n')
            .where((line) => line.trim().isNotEmpty && line.trim()[0].contains(RegExp(r'[0-9]')))
            .map((line) => line.replaceAll(RegExp(r'^\d+\.\s*'), '').trim())
            .toList();
        structuredFeedback['feedbackPoints'] = points;
      }

      // Extract suggested improvements
      final improvementsMatch = RegExp(r'SUGGESTED IMPROVEMENTS:\s*([\s\S]*?)(?=DETAILED ANALYSIS:)').firstMatch(feedbackText);
      if (improvementsMatch != null) {
        structuredFeedback['suggestedImprovements'] = improvementsMatch.group(1)!.trim();
      }

      // Print the feedback to terminal
      print('\n=== Gemini Feedback ===');
      print('Score: ${structuredFeedback['score']}%');
      print('\nFeedback Points:');
      (structuredFeedback['feedbackPoints'] as List?)?.forEach((point) => print('- $point'));
      print('\nSuggested Improvements:');
      print(structuredFeedback['suggestedImprovements']);
      print('\n=====================\n');

      return structuredFeedback;
    } catch (e) {
      print('Error generating feedback: $e');
      return {
        'error': 'Error generating feedback: $e',
        'rawFeedback': 'Error generating feedback: $e',
      };
    }
  }
} 