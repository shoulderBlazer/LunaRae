// lib/screens/story_generator_screen.dart
// Screen 1 — CREATE STORY (PROMPT SCREEN)

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/theme.dart';
import 'story_view_screen.dart';
import 'privacy_screen.dart';
import 'terms_screen.dart';
import '../services/story_service.dart';
import '../services/analytics_service.dart';
import '../config/api_keys.dart';
import '../widgets/banner_ad_widget.dart' show BannerAdWithFooter;
import '../widgets/dreamy_widgets.dart';

class StoryGeneratorScreen extends StatefulWidget {
  const StoryGeneratorScreen({super.key});

  @override
  State<StoryGeneratorScreen> createState() => _StoryGeneratorScreenState();
}

class _StoryGeneratorScreenState extends State<StoryGeneratorScreen> {
  final TextEditingController promptController = TextEditingController();
  bool _isLoading = false;
  StoryService? _storyService;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenPromptOpened();
    _storyService = StoryService(ApiKeys.openAiKey);
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
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;
    
    return Scaffold(
      extendBody: true,
      bottomNavigationBar: BannerAdWithFooter(footerLinks: const _FooterLinks()),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: DreamyBackground(
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: screenHeight - topPadding,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      
                      // Centered Story Card
                      DreamyCard(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 600),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // App Logo
                              Image.asset(
                                'assets/images/lunarae_logo_1024x1024.png',
                                height: 260,
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Prompt helper title
                              Text(
                                'Create me magical story about:',
                                style: LunaTheme.body(context).copyWith(
                                  fontSize: 15,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Prompt Input - pill-shaped
                              DreamyInput(
                                controller: promptController,
                                hintText: "A sleepy unicorn who can't find her stars…",
                                onSubmitted: _isLoading ? null : _generateStory,
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Primary Button
                              DreamyPrimaryButton(
                                text: "Create My Bedtime Story",
                                onPressed: _isLoading ? null : _generateStory,
                                isLoading: _isLoading,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
