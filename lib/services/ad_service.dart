import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'admob_config.dart';

class AdService {
  static bool _isInitialized = false;
  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialAdReady = false;

  /// Initialize AdMob SDK
  static Future<void> initialize() async {
    if (_isInitialized || kIsWeb) return;
    await MobileAds.instance.initialize();
    _isInitialized = true;
    
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
    return BannerAd(
      adUnitId: AdMobConfig.bannerAdIdScreen1,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => onLoaded(),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          onFailed(error);
        },
      ),
    );
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
    return BannerAd(
      adUnitId: AdMobConfig.bannerAdIdScreen2,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => onLoaded(),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          onFailed(error);
        },
      ),
    );
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
    if (kIsWeb) return;
    // Don't load if already loading or ready
    if (_isInterstitialAdReady && _interstitialAd != null) return;
    
    InterstitialAd.load(
      adUnitId: AdMobConfig.interstitialAdIdAfterStory,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          debugPrint('Interstitial ad loaded successfully');
          
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('Interstitial ad dismissed');
              ad.dispose();
              _isInterstitialAdReady = false;
              _interstitialAd = null;
              
              // Invoke callback after ad is dismissed
              _onInterstitialDismissed?.call();
              _onInterstitialDismissed = null;
              
              // Pre-load the next interstitial for future use
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Interstitial ad failed to show: ${error.message}');
              ad.dispose();
              _isInterstitialAdReady = false;
              _interstitialAd = null;
              
              // Still invoke callback so user can continue
              _onInterstitialDismissed?.call();
              _onInterstitialDismissed = null;
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial ad failed to load: ${error.message}');
          _isInterstitialAdReady = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  /// Show the interstitial ad after story with a callback when dismissed
  /// [onDismissed] is called after the ad closes (or immediately if ad not ready)
  /// Returns true if ad was shown, false if user should continue immediately
  static bool showInterstitialAdAfterStory({VoidCallback? onDismissed}) {
    if (kIsWeb) {
      onDismissed?.call();
      return false;
    }
    if (_isInterstitialAdReady && _interstitialAd != null) {
      _onInterstitialDismissed = onDismissed;
      _interstitialAd!.show();
      return true;
    } else {
      debugPrint('Interstitial ad not ready, allowing user to continue');
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
