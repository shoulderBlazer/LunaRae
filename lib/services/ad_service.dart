import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'admob_config.dart';
import 'consent_service.dart';
import 'story_ad_manager.dart';

class AdService {
  static bool _isInitialized = false;
  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialAdReady = false;
  static bool _isConsentReady = false;

  /// Initialize AdMob SDK
  static Future<void> initialize() async {
    if (_isInitialized || kIsWeb) return;
    
    // Wait for consent to be ready before initializing ads
    await ConsentService.initialize();
    _isConsentReady = true;
    
    await MobileAds.instance.initialize();
    _isInitialized = true;
    
  }

  /// Get AdRequest with consent status
  static AdRequest _getAdRequest() {
    // Google's UMP SDK handles personalized vs non-personalized ads internally
    // based on user consent. We only need to check if ads can be requested.
    // The UMP SDK automatically applies the correct ad type based on consent.
    debugPrint('[AdService] Requesting ads (UMP SDK handles consent-based personalization)');
    return const AdRequest();
  }

  /// Create a banner ad for Screen 1
  static BannerAd? createBannerAdScreen1({
    required Function() onLoaded,
    required Function(LoadAdError) onFailed,
  }) {
    if (kIsWeb) {
      onFailed(LoadAdError(1, 'web', 'Web platform not supported', null));
      return null;
    }
    
    // Check consent before creating ad
    if (!ConsentService.canRequestAds) {
      debugPrint('[AdService] Cannot request ads - consent not granted');
      onFailed(LoadAdError(1, 'consent', 'Consent not granted for ads', null));
      return null;
    }
    
    debugPrint('[AdService] Creating BannerAd for Screen 1');
    final bannerAd = BannerAd(
      adUnitId: AdMobConfig.bannerAdIdScreen1,
      size: AdSize.banner,
      request: _getAdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('[AdService] BannerAd onAdLoaded fired for Screen 1');
          onLoaded();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[AdService] BannerAd onAdFailedToLoad fired for Screen 1: ${error.message}');
          ad.dispose();
          onFailed(error);
        },
      ),
    );
    debugPrint('[AdService] BannerAd object created for Screen 1');
    return bannerAd;
  }

  /// Create a banner ad for Screen 2
  static BannerAd? createBannerAdScreen2({
    required Function() onLoaded,
    required Function(LoadAdError) onFailed,
  }) {
    if (kIsWeb) {
      onFailed(LoadAdError(1, 'web', 'Web platform not supported', null));
      return null;
    }
    
    // Check consent before creating ad
    if (!ConsentService.canRequestAds) {
      debugPrint('[AdService] Cannot request ads - consent not granted');
      onFailed(LoadAdError(1, 'consent', 'Consent not granted for ads', null));
      return null;
    }
    
    debugPrint('[AdService] Creating BannerAd for Screen 2');
    final bannerAd = BannerAd(
      adUnitId: AdMobConfig.bannerAdIdScreen2,
      size: AdSize.banner,
      request: _getAdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('[AdService] BannerAd onAdLoaded fired for Screen 2');
          onLoaded();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[AdService] BannerAd onAdFailedToLoad fired for Screen 2: ${error.message}');
          ad.dispose();
          onFailed(error);
        },
      ),
    );
    debugPrint('[AdService] BannerAd object created for Screen 2');
    return bannerAd;
  }

  /// Legacy method for backwards compatibility - uses Screen 1 banner
  static BannerAd? createBannerAd({
    required Function() onLoaded,
    required Function(LoadAdError) onFailed,
  }) {
    return createBannerAdScreen1(onLoaded: onLoaded, onFailed: onFailed);
  }

  // Callback to invoke when interstitial is dismissed
  static VoidCallback? _onInterstitialDismissed;

  /// Load the interstitial ad (call this ahead of time)
  static void loadInterstitialAd() {
    debugPrint('[AdService] loadInterstitialAd called');
    debugPrint('[AdService] Interstitial available: $_interstitialAd != null');
    
    if (kIsWeb) {
      debugPrint('[AdService] Web platform, skipping interstitial load');
      return;
    }
    
    // Check consent before loading ad
    if (!ConsentService.canRequestAds) {
      debugPrint('[AdService] Cannot load interstitial ad - consent not granted');
      return;
    }
    
    // Don't load if already loading or ready
    if (_isInterstitialAdReady && _interstitialAd != null) {
      debugPrint('[AdService] Interstitial already loaded and ready, skipping load');
      return;
    }
    
    debugPrint('[AdService] Loading interstitial ad...');
    InterstitialAd.load(
      adUnitId: AdMobConfig.interstitialAdIdAfterStory,
      request: _getAdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          debugPrint('[AdService] Interstitial loaded');
          
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('[AdService] Interstitial dismissed');
              ad.dispose();
              debugPrint('[AdService] Interstitial disposed');
              _isInterstitialAdReady = false;
              _interstitialAd = null;
              debugPrint('[AdService] Interstitial available: $_interstitialAd != null');
              
              // Invoke callback after ad is dismissed
              _onInterstitialDismissed?.call();
              _onInterstitialDismissed = null;
              
              // Pre-load the next interstitial for future use
              debugPrint('[AdService] Preloading next interstitial');
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('[AdService] Interstitial failed to show: ${error.message}');
              ad.dispose();
              debugPrint('[AdService] Interstitial disposed');
              _isInterstitialAdReady = false;
              _interstitialAd = null;
              debugPrint('[AdService] Interstitial available: $_interstitialAd != null');
              
              // Still invoke callback so user can continue
              _onInterstitialDismissed?.call();
              _onInterstitialDismissed = null;
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdService] Interstitial failed to load: ${error.message}');
          _isInterstitialAdReady = false;
          _interstitialAd = null;
          debugPrint('[AdService] Interstitial available: $_interstitialAd != null');
        },
      ),
    );
  }

  /// Show the interstitial ad after story with a callback when dismissed
  /// [onDismissed] is called after the ad closes (or immediately if ad not ready)
  /// Returns true if ad was shown, false if user should continue immediately
  static bool showInterstitialAdAfterStory({VoidCallback? onDismissed}) {
    debugPrint('[AdService] showInterstitialAdAfterStory called');
    debugPrint('[AdService] Interstitial available: $_interstitialAd != null');
    debugPrint('[AdService] Interstitial ready: $_isInterstitialAdReady');
    
    if (kIsWeb) {
      debugPrint('[AdService] Web platform, skipping interstitial show');
      onDismissed?.call();
      return false;
    }
    
    if (_isInterstitialAdReady && _interstitialAd != null) {
      _onInterstitialDismissed = onDismissed;
      debugPrint('[AdService] Interstitial shown');
      _interstitialAd!.show();
      return true;
    } else {
      debugPrint('[AdService] Interstitial not ready, allowing user to continue');
      // Ad not ready - invoke callback immediately so user can continue
      onDismissed?.call();
      // Load for next time
      loadInterstitialAd();
      return false;
    }
  }

  /// Check if interstitial ad is ready to show
  static bool get isInterstitialAdReady => _isInterstitialAdReady;

  /// Dispose of any loaded ads
  static void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialAdReady = false;
  }
}
