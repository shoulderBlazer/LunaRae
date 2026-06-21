import 'package:flutter/foundation.dart';
import 'ad_service.dart';

/// Manages interstitial ad frequency during story generation.
/// Shows an interstitial ad on every 3rd generated story.
class StoryAdManager {
  static int _storyGenerationCount = 0;

  /// Increment the generation counter and check if an interstitial should be shown.
  /// Returns true if an interstitial should be shown (every 3rd generation).
  static bool shouldShowGenerationInterstitial() {
    _storyGenerationCount++;
    debugPrint('[StoryAdManager] Story generation count: $_storyGenerationCount');
    
    final shouldShow = _storyGenerationCount % 3 == 0;
    debugPrint('[StoryAdManager] Should show generation interstitial: $shouldShow');
    return shouldShow;
  }


  /// Show interstitial ad during story generation if appropriate.
  /// [onAdComplete] is called after the ad is dismissed (or immediately if ad not ready).
  /// Returns true if ad was shown, false if user should continue immediately.
  static Future<bool> showGenerationInterstitial({required VoidCallback onAdComplete}) async {
    debugPrint('[StoryAdManager] showGenerationInterstitial called');
    debugPrint('[StoryAdManager] Interstitial ready: ${AdService.isInterstitialAdReady}');
    
    if (!AdService.isInterstitialAdReady) {
      debugPrint('[StoryAdManager] Skipping generation interstitial - ad not ready');
      onAdComplete();
      return false;
    }

    debugPrint('[StoryAdManager] Showing generation interstitial');
    
    final wasShown = AdService.showInterstitialAdAfterStory(
      onDismissed: () {
        debugPrint('[StoryAdManager] Preloading next interstitial');
        AdService.loadInterstitialAd();
        onAdComplete();
      },
    );

    if (!wasShown) {
      debugPrint('[StoryAdManager] Skipping generation interstitial - show failed');
      onAdComplete();
    }

    return wasShown;
  }

  /// Get the current generation count (for testing/debugging).
  static int get generationCount => _storyGenerationCount;


  /// Reset the generation counter (for testing).
  static void resetCounter() {
    _storyGenerationCount = 0;
    debugPrint('[StoryAdManager] Generation counter reset');
  }
}
