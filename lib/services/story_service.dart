import 'dart:convert';
import 'dart:async';
import 'dart:io';
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
      await AnalyticsService.logStoryGenerateFailed('Missing OPENAI_API_KEY (build misconfigured)');
      throw Exception(
        'OPENAI_API_KEY is not configured for this build. Provide it at build time using --dart-define=OPENAI_API_KEY=... (e.g. in Codemagic).',
      );
    }

    final url = Uri.parse("https://api.openai.com/v1/chat/completions");

    try {
      // Pre-encode JSON to avoid blocking during request
      final requestBody = jsonEncode({
        "model": "gpt-4o-mini",
        "messages": [
          {
            "role": "system",
            "content": "You are LunaRae, a gentle storyteller for children ages 2-10. Write calm, happy bedtime stories avoiding fear, danger, sadness, and violence. Stories should be positive, kind, imaginative, and end peacefully."
          },
          {
            "role": "user",
            "content": "Short bedtime story about: $input"
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
          "Accept": "application/json",
        },
        body: requestBody,
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () => throw TimeoutException("Request timeout", Duration(seconds: 30)),
      );

      if (response.statusCode == 200) {
        // Standard JSON decoding for better compatibility
        final data = jsonDecode(response.body);

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
    } on TimeoutException catch (e) {
      await AnalyticsService.logStoryGenerateFailed('Timeout: $e');
      throw Exception("Request timed out. Please check your connection and try again.");
    } on SocketException catch (e) {
      await AnalyticsService.logStoryGenerateFailed('Network error: $e');
      throw Exception("Network error. Please check your internet connection.");
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
