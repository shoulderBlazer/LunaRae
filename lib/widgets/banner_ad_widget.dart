import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';
import '../services/ads_ready_service.dart';
import '../theme/theme.dart';

/// Dreamy styled banner ad widget with rounded container and "Advertisement" label
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isLoadingAd = false;

  @override
  void initState() {
    super.initState();
    // Listen for ads ready signal
    AdsReadyService.addListener(_onAdsReady);
    
    // Load ad immediately if ads are already ready
    if (AdsReadyService.isReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadAd();
      });
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    AdsReadyService.removeListener(_onAdsReady);
    super.dispose();
  }

  void _onAdsReady() {
    debugPrint('[BannerAdWidget] Ads ready signal received');
    if (mounted) {
      _loadAd();
    }
  }

  Future<void> _loadAd() async {
    debugPrint('[BannerAdWidget] _loadAd called');
    
    // Guard against multiple banner loads
    if (_isLoadingAd || _bannerAd != null) {
      debugPrint('[BannerAdWidget] Skipping _loadAd - _isLoadingAd: $_isLoadingAd, _bannerAd: ${_bannerAd != null}');
      return;
    }

    _isLoadingAd = true;

    try {
      debugPrint('[BannerAdWidget] Calling AdService.createBannerAdScreen1()');
      _bannerAd = AdService.createBannerAdScreen1(
        onLoaded: () {
          debugPrint('[BannerAdWidget] onLoaded callback fired');
          if (mounted) {
            debugPrint('[BannerAdWidget] Calling setState to set _isAdLoaded = true');
            setState(() => _isAdLoaded = true);
          }
        },
        onFailed: (error) {
          // Fail silently - just log for debugging
          debugPrint('[BannerAdWidget] Banner ad failed to load: ${error.message}');
        },
      );
      debugPrint('[BannerAdWidget] _bannerAd assigned: ${_bannerAd != null}');
      if (_bannerAd != null) {
        debugPrint('[BannerAdWidget] Calling banner.load()');
        _bannerAd?.load();
      } else {
        debugPrint('[BannerAdWidget] _bannerAd is null, skipping load()');
      }
    } finally {
      _isLoadingAd = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[BannerAdWidget] build() called - _isAdLoaded: $_isAdLoaded, _bannerAd: ${_bannerAd != null}');
    
    if (!_isAdLoaded || _bannerAd == null) {
      debugPrint('[BannerAdWidget] Returning SizedBox.shrink() (ad not loaded)');
      return const SizedBox.shrink();
    }

    final isDark = LunaTheme.isDarkMode(context);

    debugPrint('[BannerAdWidget] Building AdWidget');
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          color: (isDark ? LunaTheme.darkGradientStart : LunaTheme.lightPrimary).withValues(alpha: 0.9),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: _bannerAd!.size.height.toDouble(),
              child: Center(
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Banner ad with footer links above it - for use in bottomNavigationBar
class BannerAdWithFooter extends StatefulWidget {
  final Widget footerLinks;
  
  const BannerAdWithFooter({super.key, required this.footerLinks});
  
  /// Calculate the total footer height including text scale for dynamic layouts
  static double calculateFooterHeight(BuildContext context) {
    return _BannerAdWithFooterState.calculateFooterHeight(context);
  }

  @override
  State<BannerAdWithFooter> createState() => _BannerAdWithFooterState();
}

class _BannerAdWithFooterState extends State<BannerAdWithFooter> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isLoadingAd = false;
  
  // Fixed height to prevent layout shift - standard banner is 50px
  static const double _reservedAdHeight = 50.0;
  
  /// Calculate the total footer height including text scale for dynamic layouts
  static double calculateFooterHeight(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final textScaler = mediaQuery.textScaler;
    
    // Footer link text base height (fontSize 10 + padding)
    final footerLinksHeight = textScaler.scale(10) + 12; // 6px vertical padding * 2
    
    // Fixed components
    const bannerHeight = _reservedAdHeight;
    const bottomPadding = 8.0; // minimum SafeArea bottom
    
    // SafeArea bottom inset
    final safeAreaBottom = mediaQuery.padding.bottom;
    
    return footerLinksHeight + bannerHeight + bottomPadding + safeAreaBottom;
  }

  @override
  void initState() {
    super.initState();
    // Listen for ads ready signal
    AdsReadyService.addListener(_onAdsReady);
    
    // Load ad immediately if ads are already ready
    if (AdsReadyService.isReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadAd();
      });
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    AdsReadyService.removeListener(_onAdsReady);
    super.dispose();
  }

  void _onAdsReady() {
    debugPrint('[BannerAdWithFooter] Ads ready signal received');
    if (mounted) {
      _loadAd();
    }
  }

  Future<void> _loadAd() async {
    debugPrint('[BannerAdWithFooter] _loadAd called');
    
    // Guard against multiple banner loads
    if (_isLoadingAd || _bannerAd != null) {
      debugPrint('[BannerAdWithFooter] Skipping _loadAd - _isLoadingAd: $_isLoadingAd, _bannerAd: ${_bannerAd != null}');
      return;
    }

    _isLoadingAd = true;

    try {
      debugPrint('[BannerAdWithFooter] Calling AdService.createBannerAdScreen1()');
      // Use Screen 1 banner ID via AdMobConfig
      _bannerAd = AdService.createBannerAdScreen1(
        onLoaded: () {
          debugPrint('[BannerAdWithFooter] onLoaded callback fired');
          if (mounted) {
            debugPrint('[BannerAdWithFooter] Calling setState to set _isAdLoaded = true');
            setState(() => _isAdLoaded = true);
          }
        },
        onFailed: (error) {
          // Fail silently - just log for debugging, no user-facing error
          debugPrint('[BannerAdWithFooter] Banner ad failed to load: ${error.message}');
          // Keep reserved space to prevent layout shift
        },
      );
      debugPrint('[BannerAdWithFooter] _bannerAd assigned: ${_bannerAd != null}');
      if (_bannerAd != null) {
        debugPrint('[BannerAdWithFooter] Calling banner.load()');
        _bannerAd?.load();
      } else {
        debugPrint('[BannerAdWithFooter] _bannerAd is null, skipping load()');
      }
    } finally {
      _isLoadingAd = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = LunaTheme.isDarkMode(context);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          color: (isDark ? LunaTheme.darkGradientStart : LunaTheme.lightPrimary).withValues(alpha: 0.9),
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Footer links
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: widget.footerLinks,
                ),
                // Banner ad with fixed reserved height to prevent layout shift
                SizedBox(
                  width: double.infinity,
                  height: _reservedAdHeight,
                  child: _isAdLoaded && _bannerAd != null
                      ? Center(child: AdWidget(ad: _bannerAd!))
                      : const SizedBox.shrink(), // Empty placeholder, same height
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Inline dreamy banner ad for use inside scrollable content
class InlineBannerAdWidget extends StatefulWidget {
  const InlineBannerAdWidget({super.key});

  @override
  State<InlineBannerAdWidget> createState() => _InlineBannerAdWidgetState();
}

class _InlineBannerAdWidgetState extends State<InlineBannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isLoadingAd = false;

  @override
  void initState() {
    super.initState();
    // Listen for ads ready signal
    AdsReadyService.addListener(_onAdsReady);
    
    // Load ad immediately if ads are already ready
    if (AdsReadyService.isReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadAd();
      });
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    AdsReadyService.removeListener(_onAdsReady);
    super.dispose();
  }

  void _onAdsReady() {
    debugPrint('[InlineBannerAdWidget] Ads ready signal received');
    if (mounted) {
      _loadAd();
    }
  }

  Future<void> _loadAd() async {
    debugPrint('[InlineBannerAdWidget] _loadAd called');
    
    // Guard against multiple banner loads
    if (_isLoadingAd || _bannerAd != null) {
      debugPrint('[InlineBannerAdWidget] Skipping _loadAd - _isLoadingAd: $_isLoadingAd, _bannerAd: ${_bannerAd != null}');
      return;
    }

    _isLoadingAd = true;

    try {
      debugPrint('[InlineBannerAdWidget] Calling AdService.createBannerAdScreen2()');
      // Use Screen 2 banner ID for inline/secondary placement
      _bannerAd = AdService.createBannerAdScreen2(
        onLoaded: () {
          debugPrint('[InlineBannerAdWidget] onLoaded callback fired');
          if (mounted) {
            debugPrint('[InlineBannerAdWidget] Calling setState to set _isAdLoaded = true');
            setState(() => _isAdLoaded = true);
          }
        },
        onFailed: (error) {
          // Fail silently - just log for debugging
          debugPrint('[InlineBannerAdWidget] Banner ad failed to load: ${error.message}');
        },
      );
      debugPrint('[InlineBannerAdWidget] _bannerAd assigned: ${_bannerAd != null}');
      if (_bannerAd != null) {
        debugPrint('[InlineBannerAdWidget] Calling banner.load()');
        _bannerAd?.load();
      } else {
        debugPrint('[InlineBannerAdWidget] _bannerAd is null, skipping load()');
      }
    } finally {
      _isLoadingAd = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded || _bannerAd == null) {
      return const SizedBox(height: 90);
    }

    final isDark = LunaTheme.isDarkMode(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Advertisement',
            style: LunaTheme.adLabel(context),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: LunaTheme.cardColor(context).withValues(alpha: isDark ? 0.6 : 0.8),
              borderRadius: BorderRadius.circular(LunaTheme.radiusAd),
              border: Border.all(
                color: LunaTheme.primary(context).withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Opacity(
              opacity: isDark ? 0.85 : 1.0,
              child: SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner ad with footer for Story Output screen (Screen 2)
/// Features: fade-in animation, visual separator, respects scrolling
class StoryOutputBannerAd extends StatefulWidget {
  final Widget footerLinks;
  
  const StoryOutputBannerAd({super.key, required this.footerLinks});
  
  /// Calculate the total footer height including text scale for dynamic layouts
  static double calculateFooterHeight(BuildContext context) {
    return _StoryOutputBannerAdState.calculateFooterHeight(context);
  }

  @override
  State<StoryOutputBannerAd> createState() => _StoryOutputBannerAdState();
}

class _StoryOutputBannerAdState extends State<StoryOutputBannerAd>
    with SingleTickerProviderStateMixin {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isLoadingAd = false;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  // Fixed height to prevent layout shift - standard banner is 50px
  static const double _reservedAdHeight = 50.0;
  
  /// Calculate the total footer height including text scale for dynamic layouts
  static double calculateFooterHeight(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final textScaler = mediaQuery.textScaler;
    
    // Check if this is a tablet to ensure consistent footer height across platforms
    final screenWidth = mediaQuery.size.width;
    final isTablet = screenWidth > 600 || (Theme.of(context).platform == TargetPlatform.android && screenWidth > 400);
    
    // Footer link text base height (fontSize 10 + padding)
    final footerLinksHeight = isTablet ? 10 + 12 : textScaler.scale(10) + 12; // Use fixed height for tablets
    
    // Fixed components
    const separatorHeight = 5.0; // 1px line + 4px spacing
    const bannerHeight = _reservedAdHeight;
    const bottomPadding = 8.0; // minimum SafeArea bottom
    
    // SafeArea bottom inset - use fixed value for tablets to ensure consistency
    final safeAreaBottom = isTablet ? 0.0 : mediaQuery.padding.bottom;
    
    return separatorHeight + footerLinksHeight + bannerHeight + bottomPadding + safeAreaBottom;
  }

  @override
  void initState() {
    super.initState();
    
    // Setup fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    
    // Listen for ads ready signal
    AdsReadyService.addListener(_onAdsReady);
    
    // Load ad immediately if ads are already ready
    if (AdsReadyService.isReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadAd();
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _bannerAd?.dispose();
    AdsReadyService.removeListener(_onAdsReady);
    super.dispose();
  }

  void _onAdsReady() {
    debugPrint('[StoryOutputBannerAd] Ads ready signal received');
    if (mounted) {
      _loadAd();
    }
  }

  Future<void> _loadAd() async {
    debugPrint('[StoryOutputBannerAd] _loadAd called');
    
    // Guard against multiple banner loads
    if (_isLoadingAd || _bannerAd != null) {
      debugPrint('[StoryOutputBannerAd] Skipping _loadAd - _isLoadingAd: $_isLoadingAd, _bannerAd: ${_bannerAd != null}');
      return;
    }

    _isLoadingAd = true;

    try {
      debugPrint('[StoryOutputBannerAd] Calling AdService.createBannerAdScreen2()');
      // Use Screen 2 banner ID for Story Output screen
      _bannerAd = AdService.createBannerAdScreen2(
        onLoaded: () {
          debugPrint('[StoryOutputBannerAd] onLoaded callback fired');
          if (mounted) {
            debugPrint('[StoryOutputBannerAd] Calling setState to set _isAdLoaded = true');
            setState(() => _isAdLoaded = true);
            // Start fade-in animation when ad loads
            _fadeController.forward();
          }
        },
        onFailed: (error) {
          // Fail silently - just log for debugging, no user-facing error
          debugPrint('[StoryOutputBannerAd] Banner ad failed to load: ${error.message}');
        },
      );
      debugPrint('[StoryOutputBannerAd] _bannerAd assigned: ${_bannerAd != null}');
      if (_bannerAd != null) {
        debugPrint('[StoryOutputBannerAd] Calling banner.load()');
        _bannerAd?.load();
      } else {
        debugPrint('[StoryOutputBannerAd] _bannerAd is null, skipping load()');
      }
    } finally {
      _isLoadingAd = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[StoryOutputBannerAd] build() called - _isAdLoaded: $_isAdLoaded, _bannerAd: ${_bannerAd != null}, mounted: $mounted');
    final isDark = LunaTheme.isDarkMode(context);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          color: (isDark ? LunaTheme.darkGradientStart : LunaTheme.lightPrimary).withValues(alpha: 0.9),
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Visual separator from story content
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        LunaTheme.primary(context).withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Footer links
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: widget.footerLinks,
                ),
                // Banner ad with fade-in animation and fixed reserved height
                SizedBox(
                  width: double.infinity,
                  height: _reservedAdHeight,
                  child: _isAdLoaded && _bannerAd != null
                      ? FadeTransition(
                          opacity: _fadeAnimation,
                          child: Center(
                            child: Builder(
                              builder: (context) {
                                debugPrint('[StoryOutputBannerAd] Building AdWidget with BannerAd');
                                return AdWidget(ad: _bannerAd!);
                              },
                            ),
                          ),
                        )
                      : Builder(
                          builder: (context) {
                            debugPrint('[StoryOutputBannerAd] Returning SizedBox.shrink() - _isAdLoaded: $_isAdLoaded, _bannerAd: ${_bannerAd != null}');
                            return const SizedBox.shrink(); // Empty placeholder, same height
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
