import 'package:flutter/foundation.dart';

/// Global service to track when ads are ready to be requested
/// This ensures banner widgets are only created after ConsentService and AdService are initialized
class AdsReadyService {
  static final ValueNotifier<bool> adsReady = ValueNotifier<bool>(false);
  
  /// Mark ads as ready (called after ConsentService and AdService initialization)
  static void markReady() {
    if (adsReady.value) {
      debugPrint('[AdsReadyService] Ads already marked as ready, skipping duplicate call');
      return;
    }
    debugPrint('[AdsReadyService] Marking ads as ready');
    adsReady.value = true;
  }
  
  /// Reset ads ready state (for testing)
  static void reset() {
    debugPrint('[AdsReadyService] Resetting ads ready state');
    adsReady.value = false;
  }
  
  /// Check if ads are ready
  static bool get isReady => adsReady.value;
  
  /// Listen to ads ready changes
  static void addListener(VoidCallback listener) {
    adsReady.addListener(listener);
  }
  
  /// Remove listener
  static void removeListener(VoidCallback listener) {
    adsReady.removeListener(listener);
  }
}
