import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme.dart';
import '../services/font_size_provider.dart';
import '../widgets/banner_ad_widget.dart' show StoryOutputBannerAd;
import '../widgets/dreamy_widgets.dart';
import '../widgets/frosted_header.dart';
import 'privacy_screen.dart';
import 'story_generator_screen.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _headerKey = GlobalKey();
  double _headerHeight = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeader());
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
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSizeProvider = context.watch<FontSizeProvider>();
    final scaledBodyStyle = LunaTheme.body(context).copyWith(
      fontSize: 16 * fontSizeProvider.scaleFactor,
    );
    final footerHeight = StoryOutputBannerAd.calculateFooterHeight(context);
    // Fixed gap between header and card
    const dynamicGap = 24.0;
    
    // Schedule header measurement after layout
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeader());
    
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
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Available height for card = total - header - footer - margins
                  final availableHeight = constraints.maxHeight - _headerHeight - footerHeight;
                  // Card area: top margin (dynamicGap) + card + bottom margin (dynamicGap)
                  final cardMaxHeight = availableHeight - dynamicGap - dynamicGap;
                  
                  return Padding(
                    padding: EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: _headerHeight + dynamicGap,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: cardMaxHeight,
                      ),
                      child: DreamyCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Center(
                              child: Text(
                                'Terms & Conditions for LunaRae',
                                style: LunaTheme.appTitle(context).copyWith(
                                  fontSize: 20,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Divider
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
                            // Scrollable Content
                            Expanded(
                              child: SingleChildScrollView(
                                controller: _scrollController,
                                physics: const BouncingScrollPhysics(),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Last updated: December 2025',
                                      style: scaledBodyStyle.copyWith(
                                        fontStyle: FontStyle.italic,
                                        fontSize: 12 * fontSizeProvider.scaleFactor,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'These Terms & Conditions govern your use of the LunaRae mobile application. By downloading, accessing, or using the app, you agree to be bound by these terms.',
                                      style: scaledBodyStyle.copyWith(height: 1.6),
                                    ),
                                    const SizedBox(height: 20),
                                    _SectionTitle(title: '1. About the App'),
                                    const SizedBox(height: 8),
                                    Text(
                                      'LunaRae is a bedtime story generator that creates gentle, positive stories using artificial intelligence. The app is intended for entertainment purposes only.\n\n'
                                      'All stories are:\n'
                                      '• Fictional\n'
                                      '• AI-generated\n'
                                      '• Not guaranteed to be factually accurate',
                                      style: scaledBodyStyle.copyWith(height: 1.6),
                                    ),
                                    const SizedBox(height: 20),
                                    _SectionTitle(title: '2. Use of the App'),
                                    const SizedBox(height: 8),
                                    Text(
                                      'You agree to use LunaRae responsibly and only for its intended purpose.\n\n'
                                      'You must not:\n'
                                      '• Use the app for harmful, abusive, or illegal purposes\n'
                                      '• Attempt to interfere with or disrupt the app\'s services\n'
                                      '• Attempt to reverse engineer, copy, or exploit the app\n\n'
                                      'We reserve the right to suspend or restrict access if misuse is detected.',
                                      style: scaledBodyStyle.copyWith(height: 1.6),
                                    ),
                                    const SizedBox(height: 20),
                                    _SectionTitle(title: '3. Advertisements'),
                                    const SizedBox(height: 8),
                                    Text(
                                      'The free version of LunaRae contains advertisements provided by third-party ad networks such as Google AdMob.\n\n'
                                      'We do not control the content of advertisements and are not responsible for any third-party products or services promoted within the app.',
                                      style: scaledBodyStyle.copyWith(height: 1.6),
                                    ),
                                    const SizedBox(height: 20),
                                    _SectionTitle(title: '4. AI-Generated Content'),
                                    const SizedBox(height: 8),
                                    Text(
                                      'LunaRae uses artificial intelligence to generate stories:\n'
                                      '• All story outputs are automatically generated\n'
                                      '• No guarantee is made regarding accuracy, interpretation, or educational value\n'
                                      '• LunaRae is not responsible for how stories are interpreted or used by users\n\n'
                                      'Parents and guardians are encouraged to supervise children while using the app.',
                                      style: scaledBodyStyle.copyWith(height: 1.6),
                                    ),
                                    const SizedBox(height: 20),
                                    _SectionTitle(title: '5. Use of OpenAI Technology'),
                                    const SizedBox(height: 8),
                                    Text(
                                      'LunaRae uses OpenAI technology to generate its stories.\n\n'
                                      'LunaRae is not affiliated with, endorsed by, partnered with, or sponsored by OpenAI. All AI content is generated automatically through licensed API usage.',
                                      style: scaledBodyStyle.copyWith(height: 1.6),
                                    ),
                                    const SizedBox(height: 20),
                                    _SectionTitle(title: '6. Service Availability'),
                                    const SizedBox(height: 8),
                                    Text(
                                      'We aim to keep LunaRae available at all times, but we do not guarantee:\n'
                                      '• Uninterrupted service\n'
                                      '• Error-free operation\n'
                                      '• Continuous availability of AI generation services\n\n'
                                      'Access may be suspended temporarily for maintenance, updates, or technical issues.',
                                      style: scaledBodyStyle.copyWith(height: 1.6),
                                    ),
                                    const SizedBox(height: 20),
                                    _SectionTitle(title: '7. Limitation of Liability'),
                                    const SizedBox(height: 8),
                                    Text(
                                      'To the maximum extent permitted by law:\n'
                                      '• LunaRae is provided "as is"\n'
                                      '• We are not liable for any direct or indirect damages arising from use of the app\n'
                                      '• We are not responsible for lost data, generated content, or service interruption',
                                      style: scaledBodyStyle.copyWith(height: 1.6),
                                    ),
                                    const SizedBox(height: 20),
                                    _SectionTitle(title: '8. Intellectual Property'),
                                    const SizedBox(height: 8),
                                    Text(
                                      'All app branding, layout, and interface design belong to LunaRae.\n\n'
                                      'Users may:\n'
                                      '• Read and enjoy generated stories\n'
                                      '• Share stories for personal, non-commercial use\n\n'
                                      'Users may not:\n'
                                      '• Resell generated content\n'
                                      '• Use generated stories for commercial purposes without permission',
                                      style: scaledBodyStyle.copyWith(height: 1.6),
                                    ),
                                    const SizedBox(height: 20),
                                    _SectionTitle(title: '9. Children\'s Use'),
                                    const SizedBox(height: 8),
                                    Text(
                                      'LunaRae is designed to produce child-friendly content but is intended to be used with parental guidance. Parents and guardians are responsible for monitoring children\'s usage.',
                                      style: scaledBodyStyle.copyWith(height: 1.6),
                                    ),
                                    const SizedBox(height: 20),
                                    _SectionTitle(title: '10. Changes to These Terms'),
                                    const SizedBox(height: 8),
                                    Text(
                                      'We may update these Terms & Conditions at any time. Continued use of the app after updates means you accept the new terms.',
                                      style: scaledBodyStyle.copyWith(height: 1.6),
                                    ),
                                    const SizedBox(height: 20),
                                    _SectionTitle(title: '11. Contact Information'),
                                    const SizedBox(height: 8),
                                    Text(
                                      'For any questions regarding these Terms & Conditions, contact:\n\n'
                                      'Email: support@lunarae.app\n'
                                      '(Replace with your real support email before release.)',
                                      style: scaledBodyStyle.copyWith(height: 1.6),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            DreamyPrimaryButton(
                              text: 'Generate Story',
                              onPressed: () {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (_) => const StoryGeneratorScreen()),
                                  (route) => false,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
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
                title: 'LunaRae',
                trailing: _FontSizeButton(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: LunaTheme.body(context).copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: LunaTheme.primary(context),
      ),
    );
  }
}

/// Footer links for legal pages
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
        Text(
          'T&Cs',
          style: textStyle.copyWith(
            color: linkColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

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