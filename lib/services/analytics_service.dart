/// Stub analytics service - Firebase has been removed.
/// All methods are no-ops but maintain the same interface for compatibility.
class AnalyticsService {
  // App opened - call on app launch
  static Future<void> logAppOpened() async {}

  // Screen 1 viewed
  static Future<void> logScreenPromptOpened() async {}

  // Screen 2 viewed
  static Future<void> logScreenStoryOpened() async {}

  // Generate button tapped
  static Future<void> logStoryGeneratePressed() async {}

  // API returns story successfully
  static Future<void> logStoryGenerateSuccess({int? storyLength}) async {}

  // API throws error
  static Future<void> logStoryGenerateFailed(String errorMessage) async {}

  // Banner ad displayed
  static Future<void> logAdBannerShown() async {}

  // Interstitial ad displayed (after story)
  static Future<void> logAdInterstitialShown() async {}

  // User scrolled to the bottom of the story content
  static Future<void> logStoryScrolledToBottom() async {}

  // OpenAI quota hit (status 429)
  static Future<void> logApiQuotaError() async {}

  // General OpenAI API error logging
  static Future<void> logOpenAIError({
    required int statusCode,
    required String errorBody,
  }) async {}

  // Record non-fatal errors
  static Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {}

  // Log custom message
  static Future<void> log(String message) async {}
}
