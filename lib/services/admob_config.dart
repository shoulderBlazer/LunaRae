import 'package:flutter/foundation.dart';
import 'dart:io';

class AdMobConfig {
  AdMobConfig._();

  // Production IDs
  static const String _androidBannerScreen1 = 'ca-app-pub-5203847313376900/9777735905';
  static const String _androidBannerScreen2 = 'ca-app-pub-5203847313376900/9937518005';
  static const String _androidInterstitialAfterStory = 'ca-app-pub-5203847313376900/2843935547';
  
  static const String _iosBannerScreen1 = 'ca-app-pub-5203847313376900/4034277024';
  static const String _iosBannerScreen2 = 'ca-app-pub-5203847313376900/7904690535';
  static const String _iosInterstitialAfterStory = 'ca-app-pub-5203847313376900/9590033641';

  // Test IDs
  static const String _testAndroidBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testAndroidInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testIosBanner = 'ca-app-pub-3940256099942544/2934735716';
  static const String _testIosInterstitial = 'ca-app-pub-3940256099942544/4411468910';

  // Getters
  static String get bannerAdIdScreen1 {
    if (kDebugMode) return kIsWeb ? '' : (Platform.isAndroid ? _testAndroidBanner : _testIosBanner);
    return kIsWeb ? '' : (Platform.isAndroid ? _androidBannerScreen1 : _iosBannerScreen1);
  }

  static String get bannerAdIdScreen2 {
    if (kDebugMode) return kIsWeb ? '' : (Platform.isAndroid ? _testAndroidBanner : _testIosBanner);
    return kIsWeb ? '' : (Platform.isAndroid ? _androidBannerScreen2 : _iosBannerScreen2);
  }

  static String get interstitialAdIdAfterStory {
    if (kDebugMode) return kIsWeb ? '' : (Platform.isAndroid ? _testAndroidInterstitial : _testIosInterstitial);
    return kIsWeb ? '' : (Platform.isAndroid ? _androidInterstitialAfterStory : _iosInterstitialAfterStory);
  }
}
