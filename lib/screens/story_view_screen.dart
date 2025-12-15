// lib/screens/story_view_screen.dart
// Screen 2 — YOUR STORY (OUTPUT SCREEN)

import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../widgets/banner_ad_widget.dart' show StoryOutputBannerAd;
import '../widgets/dreamy_widgets.dart';
import '../widgets/frosted_header.dart';
import '../services/analytics_service.dart';
import '../services/ad_service.dart';
import 'privacy_screen.dart';
import 'terms_screen.dart';

class StoryViewScreen extends StatefulWidget {
  final String content;
  final String? storyTitle;

  const StoryViewScreen({
    super.key,
    required this.content,
    this.storyTitle,
  });

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  // Track if interstitial has been shown for this story (one per story)
  bool _hasShownInterstitial = false;
  bool _isNavigating = false;
  
  // Track if user has scrolled to bottom of story (triggers once per session)
  bool _hasReachedStoryBottom = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenStoryOpened();
    
    // Fade-in animation for story appearance (250-300ms)
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 280),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
    
    // Pre-load interstitial ad after screen renders (never block story display)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdService.loadInterstitialAd();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  /// Handle "Create Another Story" button tap
  /// Shows interstitial (if not already shown), then navigates back
  void _onCreateAnotherStory() {
    // Prevent double-tap
    if (_isNavigating) return;
    _isNavigating = true;
    
    // Try to show interstitial, then navigate back
    _showInterstitialOnce(onComplete: _navigateBack);
  }
  
  void _navigateBack() {
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
  
  /// Called once when user scrolls to the true bottom of the story content
  void _onStoryScrolledToBottom() {
    if (_hasReachedStoryBottom) return;
    _hasReachedStoryBottom = true;
    
    // Log analytics event for story completion
    AnalyticsService.logStoryScrolledToBottom();
    
    // Show interstitial ad after 5 second delay (gives user time to read ending)
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        _showInterstitialOnce();
      }
    });
  }
  
  /// Shows interstitial ad only once per story session
  /// [onComplete] is called after ad dismisses (or immediately if already shown/not ready)
  void _showInterstitialOnce({VoidCallback? onComplete}) {
    if (_hasShownInterstitial) {
      // Already shown this session, just run callback
      onComplete?.call();
      return;
    }
    
    final adShown = AdService.showInterstitialAdAfterStory(
      onDismissed: onComplete,
    );
    
    if (adShown) {
      // Only mark as shown if ad was actually displayed
      _hasShownInterstitial = true;
      AnalyticsService.logAdInterstitialShown();
    }
    // Note: if ad not ready, showInterstitialAdAfterStory already calls onComplete
  }

  @override
  Widget build(BuildContext context) {
    final hasContent = widget.content.isNotEmpty;
    
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      bottomNavigationBar: StoryOutputBannerAd(footerLinks: const _FooterLinks()),
      body: DreamyBackground(
        child: Stack(
          children: [
            // Main content
            SafeArea(
              top: false,
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: MediaQuery.of(context).padding.top + 55,
                    bottom: 120,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      // Large centered Story Card
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: DreamyCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Story title header
                              Center(
                                child: Text(
                                  'Your LunaRae generated story is about:',
                                  style: LunaTheme.appTitle(context).copyWith(
                                    fontSize: 18,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              // Story summary title
                              if (widget.storyTitle != null && widget.storyTitle!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  widget.storyTitle!,
                                  style: LunaTheme.body(context).copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: LunaTheme.primary(context),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                              const SizedBox(height: 24),
                              // Divider with soft styling
                              Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      LunaTheme.primary(context).withOpacity(0.3),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Story content or empty state
                              hasContent
                                  ? _StoryContent(
                                      content: widget.content,
                                      onScrolledToBottom: _onStoryScrolledToBottom,
                                    )
                                  : _EmptyState(),
                              const SizedBox(height: 32),
                              // Back button - shows interstitial ad then navigates
                              DreamyPrimaryButton(
                                text: "Create Another Story",
                                onPressed: _onCreateAnotherStory,
                              ),
                              const SizedBox(height: 16),
                              // OpenAI attribution
                              Center(
                                child: Text(
                                  'Uses OpenAI technology',
                                  style: LunaTheme.body(context).copyWith(
                                    fontSize: 10,
                                    color: LunaTheme.primary(context).withOpacity(0.5),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            // Frosted header overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: FrostedHeader(
                title: 'LunaRae',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Story content with comfortable reading styling
class _StoryContent extends StatefulWidget {
  final String content;
  final VoidCallback? onScrolledToBottom;
  
  const _StoryContent({
    required this.content,
    this.onScrolledToBottom,
  });

  @override
  State<_StoryContent> createState() => _StoryContentState();
}

class _StoryContentState extends State<_StoryContent> {
  late ScrollController _scrollController;
  bool _hasTriggeredBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_hasTriggeredBottom) return;
    
    final position = _scrollController.position;
    // Check if scrolled to the true bottom (within 1 pixel tolerance)
    if (position.pixels >= position.maxScrollExtent - 1) {
      _hasTriggeredBottom = true;
      widget.onScrolledToBottom?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        thickness: 4,
        radius: const Radius.circular(4),
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(
              widget.content,
              style: LunaTheme.storyBody(context),
            ),
          ),
        ),
      ),
    );
  }
}

/// Empty state with magical message
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.auto_awesome,
              size: 48,
              color: LunaTheme.primary(context).withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Your bedtime story will appear\nhere like magic ✨',
              textAlign: TextAlign.center,
              style: LunaTheme.body(context).copyWith(
                fontStyle: FontStyle.italic,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nearly invisible footer links for legal pages
class _FooterLinks extends StatelessWidget {
  const _FooterLinks();

  @override
  Widget build(BuildContext context) {
    // Soft gray/lavender for near-invisibility
    final linkColor = LunaTheme.primary(context);
    const textStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w400,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _FooterLink(
          text: 'Privacy Policy',
          color: linkColor,
          style: textStyle,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PrivacyScreen()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '·',
            style: textStyle.copyWith(color: linkColor),
          ),
        ),
        _FooterLink(
          text: 'Terms & Conditions',
          color: linkColor,
          style: textStyle,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TermsScreen()),
          ),
        ),
      ],
    );
  }
}

/// Tappable link with underline on tap only
class _FooterLink extends StatefulWidget {
  final String text;
  final Color color;
  final TextStyle style;
  final VoidCallback onTap;

  const _FooterLink({
    required this.text,
    required this.color,
    required this.style,
    required this.onTap,
  });

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isTapped = true),
      onTapUp: (_) => setState(() => _isTapped = false),
      onTapCancel: () => setState(() => _isTapped = false),
      onTap: widget.onTap,
      child: Text(
        widget.text,
        style: widget.style.copyWith(
          color: widget.color,
          decoration: _isTapped ? TextDecoration.underline : TextDecoration.none,
          decorationColor: widget.color,
        ),
      ),
    );
  }
} 