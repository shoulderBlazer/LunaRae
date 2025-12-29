import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'analytics_service.dart';

class StoryService {
  final String apiKey;
  late final http.Client _client;
  
  StoryService(this.apiKey) {
    _client = _createOptimizedClient();
  }

  http.Client _createOptimizedClient() {
    // Create a custom client with timeout configuration
    return http.Client();
  }

  Future<String> generateStory(String input) async {
    if (apiKey.isEmpty) {
      throw Exception('OpenAI API key is not configured. Please add OPENAI_API_KEY to your .env file.');
    }

    final url = Uri.parse("https://api.openai.com/v1/chat/completions");

    try {
      // Pre-encode JSON to avoid blocking during request
      final requestBody = jsonEncode({
        "model": "gpt-4o-mini",
        "messages": [
          {
            "role": "system",
            "content":
                "You are LunaRae, a gentle storyteller who writes calm, happy bedtime stories for children ages 2 to 10. "
                "Stories must avoid fear, danger, sadness, violence, and villains. "
                "Every story should be relaxing, positive, kind, imaginative, and end with peaceful sleep."
          },
          {
            "role": "user",
            "content": "Create a short bedtime story about: $input"
          }
        ],
        "max_tokens": 700,
        "temperature": 0.7,
      });

      final response = await _client.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey",
          "Connection": "keep-alive",
          "Accept": "application/json",
          "Accept-Encoding": "gzip, deflate, br",
          "User-Agent": "LunaRae-iOS/1.0",
        },
        body: requestBody,
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () => throw TimeoutException("Request timeout", Duration(seconds: 30)),
      );

      if (response.statusCode == 200) {
        // Async JSON decoding to avoid blocking
        final data = await compute(_decodeJson, response.body);

        try {
          final story = data["choices"][0]["message"]["content"]?.trim() ??
              "🌙 A soft and peaceful dream…";
          
          // Log success with story length
          await AnalyticsService.logStoryGenerateSuccess(storyLength: story.length);
          
          return story;
        } catch (e) {
          await AnalyticsService.logStoryGenerateFailed('Parse error: $e');
          return "🌙 A soft and peaceful dream…";
        }
      } else {
        // Log OpenAI API error
        await AnalyticsService.logOpenAIError(
          statusCode: response.statusCode,
          errorBody: response.body,
        );
        throw Exception("Failed to generate story: ${response.body}");
      }
    } catch (e) {
      if (e is! Exception || !e.toString().contains('Failed to generate story')) {
        // Log unexpected errors (network issues, etc.)
        await AnalyticsService.logStoryGenerateFailed(e.toString());
        await AnalyticsService.recordError(e, StackTrace.current, reason: 'Story generation error');
      }
      rethrow;
    }
  }
  
  void dispose() {
    _client.close();
  }
}

// Helper function for compute
Future<Map<String, dynamic>> _decodeJson(String jsonString) async {
  return jsonDecode(jsonString);
}
