// lib/screens/story_generator_screen.dart
// Screen 1 — CREATE STORY (PROMPT SCREEN)

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/theme.dart';
import '../services/font_size_provider.dart';
import 'story_view_screen.dart';
import 'privacy_screen.dart';
import 'terms_screen.dart';
import '../services/story_service.dart';
import '../services/analytics_service.dart';
import '../config/api_keys.dart';
import '../widgets/banner_ad_widget.dart' show BannerAdWithFooter;
import '../widgets/dreamy_widgets.dart' show DreamyBackground, DreamyCard, DreamyInput, DreamyPrimaryButton, DreamySecondaryButton, MoonLoadingIndicator, DreamyPageRoute;
import '../widgets/frosted_header.dart';

class StoryGeneratorScreen extends StatefulWidget {
  const StoryGeneratorScreen({super.key});

  @override
  State<StoryGeneratorScreen> createState() => _StoryGeneratorScreenState();
}

class _StoryGeneratorScreenState extends State<StoryGeneratorScreen> {
  final TextEditingController promptController = TextEditingController();
  bool _isLoading = false;
  StoryService? _storyService;
  final GlobalKey _headerKey = GlobalKey();
  double _headerHeight = 0;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenPromptOpened();
    _storyService = StoryService(ApiKeys.openAiKey);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeader());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Force rebuild when orientation changes
    setState(() {});
  }

  void _measureHeader() {
    final renderBox = _headerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && mounted) {
      final height = renderBox.size.height;
      if (height != _headerHeight) {
        setState(() => _headerHeight = height);
      }
    }
  }

  @override
  void dispose() {
    promptController.dispose();
    _storyService?.dispose();
    super.dispose();
  }

  /// Creates a story summary title from the user's prompt
  String _createStoryTitle(String prompt) {
    // Capitalize first letter and add ellipsis if too long
    if (prompt.isEmpty) return '';
    
    String title = prompt;
    
    // Capitalize first letter
    title = title[0].toUpperCase() + title.substring(1);
    
    // Truncate if too long (max ~50 chars for display)
    if (title.length > 50) {
      title = '${title.substring(0, 47)}...';
    }
    
    return title;
  }

  Future<void> _generateStory() async {
    FocusScope.of(context).unfocus();

    if (promptController.text.trim().isEmpty) return;

    AnalyticsService.logStoryGeneratePressed();
    setState(() => _isLoading = true);

    if (_storyService == null) {
      _storyService = StoryService(ApiKeys.openAiKey);
    }

    try {
      final story = await _storyService!.generateStory(promptController.text.trim());
      
      if (!mounted) return;
      
      // Create a summary title from the prompt
      final summaryTitle = _createStoryTitle(promptController.text.trim());
      
      Navigator.push(
        context,
        DreamyPageRoute(
          page: StoryViewScreen(
            content: story,
            storyTitle: summaryTitle,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().contains('OPENAI_API_KEY')
          ? (kReleaseMode
              ? 'App build is missing the OpenAI API key. Please contact support.'
              : 'Missing OPENAI_API_KEY. Run/build with --dart-define=OPENAI_API_KEY=...')
          : 'Unable to create story. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: LunaTheme.primary(context),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontSizeProvider = context.watch<FontSizeProvider>();
    final scaledBodyStyle = LunaTheme.body(context).copyWith(
      fontSize: 16 * fontSizeProvider.scaleFactor,
    );
    final scaledHintStyle = LunaTheme.hintText(context).copyWith(
      fontSize: 16 * fontSizeProvider.scaleFactor,
    );
    final footerHeight = BannerAdWithFooter.calculateFooterHeight(context);
    
    // Fixed gap between header and card
    const dynamicGap = 24.0;
    
    // Schedule header measurement after layout
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeader());
    
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      bottomNavigationBar: BannerAdWithFooter(footerLinks: const _FooterLinks()),
      body: OrientationBuilder(
        builder: (context, orientation) {
          return GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: DreamyBackground(
              child: Stack(
                children: [
                  // Main content
                  SafeArea(
                    top: false,
                    bottom: false,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isLandscape = orientation == Orientation.landscape;
                        
                        // Available height = total - header - footer - margins
                        final availableHeight = constraints.maxHeight - _headerHeight - footerHeight;
                        // Card area: top margin (dynamicGap) + card + bottom margin (dynamicGap)
                        final cardMaxHeight = availableHeight - dynamicGap - dynamicGap;
                        // Use compact mode when space is tight (based on text scale factor)
                        final textScale = MediaQuery.of(context).textScaler.scale(1.0);
                        final useCompact = textScale > 1.2 || cardMaxHeight < 550;
                        final useExtraCompact = textScale > 1.5 || cardMaxHeight < 450;
                        
                        // Orientation-aware padding and constraints
                        final horizontalPadding = 24.0;
                        final cardMaxWidth = double.infinity;
                    
                    if (isLandscape) {
                      // Landscape single card layout
                      return Padding(
                        padding: EdgeInsets.only(
                          left: horizontalPadding,
                          right: horizontalPadding,
                          top: _headerHeight + dynamicGap,
                          bottom: dynamicGap,
                        ),
                        child: IntrinsicHeight(
                            child: DreamyCard(
                              child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Left side - Logo
                                Expanded(
                                  flex: 1,
                                  child: Center(
                                    child: Image.asset(
                                      'assets/images/lunarae_logo_1024x1024.png',
                                      fit: BoxFit.contain,
                                      height: constraints.maxHeight * 0.4,
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(width: 32),
                                
                                // Right side - Form content
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Prompt helper title - hidden in extra compact
                                      if (!useExtraCompact)
                                        Text(
                                          'Create me magical story about:',
                                          style: scaledBodyStyle.copyWith(
                                            fontSize: 15 * fontSizeProvider.scaleFactor,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      
                                      if (!useExtraCompact)
                                        const SizedBox(height: 16),
                                      
                                      // Prompt Input - pill-shaped, fewer lines when compact
                                      _ScaledDreamyInput(
                                        controller: promptController,
                                        hintText: "A sleepy unicorn who can't find her stars…",
                                        hintStyle: scaledHintStyle,
                                        inputStyle: scaledBodyStyle,
                                        onSubmitted: _isLoading ? null : _generateStory,
                                        maxLines: useExtraCompact ? 1 : (useCompact ? 2 : 3),
                                      ),
                                      
                                      SizedBox(height: useExtraCompact ? 8 : 16),
                                      
                                      // Primary Button
                                      _ScaledDreamyPrimaryButton(
                                        text: "Create My Bedtime Story",
                                        textStyle: LunaTheme.buttonText(context).copyWith(
                                          fontSize: 17 * fontSizeProvider.scaleFactor,
                                        ),
                                        onPressed: _isLoading ? null : _generateStory,
                                        isLoading: _isLoading,
                                        compact: useCompact || useExtraCompact,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    } else {
                      // Portrait layout (original)
                      return SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: horizontalPadding,
                            right: horizontalPadding,
                            top: _headerHeight + dynamicGap,
                            bottom: dynamicGap,
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: cardMaxHeight < 400 ? 400 : cardMaxHeight,
                            ),
                            child: IntrinsicHeight(
                              child: DreamyCard(
                                child: Column(
                                  children: [
                                    // Logo - flexible, shrinks freely
                                    Flexible(
                                      flex: 3,
                                      child: Image.asset(
                                        'assets/images/lunarae_logo_1024x1024.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    
                                    SizedBox(height: useExtraCompact ? 4 : 8),
                                    
                                    // Prompt helper title - hidden in extra compact
                                    if (!useExtraCompact)
                                      Text(
                                        'Create me magical story about:',
                                        style: scaledBodyStyle.copyWith(
                                          fontSize: 15 * fontSizeProvider.scaleFactor,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    
                                    if (!useExtraCompact)
                                      const SizedBox(height: 8),
                                    
                                    // Prompt Input - pill-shaped, fewer lines when compact
                                    _ScaledDreamyInput(
                                      controller: promptController,
                                      hintText: "A sleepy unicorn who can't find her stars…",
                                      hintStyle: scaledHintStyle,
                                      inputStyle: scaledBodyStyle,
                                      onSubmitted: _isLoading ? null : _generateStory,
                                      maxLines: useExtraCompact ? 1 : (useCompact ? 2 : 3),
                                    ),
                                    
                                    SizedBox(height: useExtraCompact ? 4 : 8),
                                    
                                    // Primary Button
                                    _ScaledDreamyPrimaryButton(
                                      text: "Create My Bedtime Story",
                                      textStyle: LunaTheme.buttonText(context).copyWith(
                                        fontSize: 17 * fontSizeProvider.scaleFactor,
                                      ),
                                      onPressed: _isLoading ? null : _generateStory,
                                      isLoading: _isLoading,
                                      compact: useCompact || useExtraCompact,
                                    ),
                                    
                                    SizedBox(height: useExtraCompact ? 2 : 4),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
              // Frosted header overlay
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: FrostedHeader(
                  key: _headerKey,
                  showBranding: false,
                  trailing: _FontSizeButton(),
                ),
              ),
            ],
          ),
        ),
        );
      },
    ),
    );
  }
}

/// Nearly invisible footer links for legal pages
class _FooterLinks extends StatelessWidget {
  const _FooterLinks();

  @override
  Widget build(BuildContext context) {
    // Light color for dark footer background
    final linkColor = Colors.white.withOpacity(0.7);
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
          text: 'T&Cs',
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

/// Font size button for the header
class _FontSizeButton extends StatelessWidget {
  const _FontSizeButton();

  @override
  Widget build(BuildContext context) {
    final fontSizeProvider = context.watch<FontSizeProvider>();
    
    return GestureDetector(
      onTap: () => showFontSizeSelector(context, fontSizeProvider),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: LunaTheme.primary(context).withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: LunaTheme.primary(context).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          Icons.text_fields,
          color: LunaTheme.primary(context),
          size: 22,
        ),
      ),
    );
  }
}

/// Scaled version of DreamyInput that accepts custom text styles
class _ScaledDreamyInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextStyle hintStyle;
  final TextStyle inputStyle;
  final int maxLines;
  final VoidCallback? onSubmitted;
  
  const _ScaledDreamyInput({
    required this.controller,
    required this.hintText,
    required this.hintStyle,
    required this.inputStyle,
    this.maxLines = 3,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: LunaTheme.inputBackground(context),
        borderRadius: BorderRadius.circular(
          maxLines > 1 ? 20 : LunaTheme.radiusInput,
        ),
        border: Border.all(
          color: LunaTheme.primary(context).withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: null,
        minLines: 1,
        textInputAction: TextInputAction.newline,
        keyboardType: TextInputType.multiline,
        onSubmitted: onSubmitted != null ? (_) => onSubmitted!() : null,
        style: inputStyle.copyWith(
          color: LunaTheme.textPrimary(context),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: hintStyle,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20, 
            vertical: 32,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}

/// Scaled version of DreamyPrimaryButton that accepts custom text style
class _ScaledDreamyPrimaryButton extends StatefulWidget {
  final String text;
  final TextStyle textStyle;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool compact;
  
  const _ScaledDreamyPrimaryButton({
    required this.text,
    required this.textStyle,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.compact = false,
  });

  @override
  State<_ScaledDreamyPrimaryButton> createState() => _ScaledDreamyPrimaryButtonState();
}

class _ScaledDreamyPrimaryButtonState extends State<_ScaledDreamyPrimaryButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = LunaTheme.isDarkMode(context);
    
    return GestureDetector(
      onTapDown: widget.onPressed != null && !widget.isLoading 
          ? (_) => _controller.forward() 
          : null,
      onTapUp: widget.onPressed != null && !widget.isLoading 
          ? (_) {
              _controller.reverse();
              widget.onPressed?.call();
            } 
          : null,
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: widget.compact ? 12 : 18, 
            horizontal: widget.compact ? 16 : 24,
          ),
          decoration: BoxDecoration(
            gradient: LunaTheme.buttonGradient(context),
            borderRadius: BorderRadius.circular(LunaTheme.radiusButton),
            boxShadow: [
              BoxShadow(
                color: LunaTheme.primary(context).withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? MoonLoadingIndicator(
                    size: 24,
                    color: isDark ? LunaTheme.darkCard : LunaTheme.lightCard,
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            color: isDark ? LunaTheme.darkCard : LunaTheme.lightCard,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                        ],
                        Text(
                          widget.text,
                          style: widget.textStyle,
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
