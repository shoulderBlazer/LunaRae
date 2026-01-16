import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme.dart';
import '../services/font_size_provider.dart';
import '../widgets/banner_ad_widget.dart' show StoryOutputBannerAd;
import '../widgets/dreamy_widgets.dart';
import '../widgets/frosted_header.dart';
import 'terms_screen.dart';
import 'story_generator_screen.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
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
                                'Privacy Policy for LunaRae',
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
                                      'LunaRae ("we," "our," or "us") respects your privacy. This Privacy Policy explains how your information is collected, used, and protected when you use the LunaRae mobile application ("the App").\n\n'
                                      'By using LunaRae, you agree to the collection and use of information in accordance with this policy.',
                                      style: scaledBodyStyle.copyWith(height: 1.6),
                                    ),
                                    const SizedBox(height: 20),
                                    _SectionTitle(title: '1. Information We Collect'),
                                    const SizedBox(height: 12),
                                    Text(
                                      'a. User-Submitted Content',
                                      style: scaledBodyStyle.copyWith(
                                        fontWeight: FontWeight.w600,
                                        height: 1.6,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'When you use LunaRae to generate a story:\n'
                                      '• The text you enter (story prompts) is sent securely to our AI provider (OpenAI) in order to generate your bedtime story.\n\n'
                                      'You should not include personal information such as:\n'
                                      '• Real names\n'
                                      '• Home addresses\n'
                                      '• Email addresses\n'
                                      '• Phone numbers\n'
                                      '• Any sensitive personal data\n\n'
                                      'We do not require accounts and do not collect personal identity data.',
                                      style: scaledBodyStyle.copyWith(height: 1.6),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'b. Automatically Collected Information',
                                      style: scaledBodyStyle.copyWith(
                                        fontWeight: FontWeight.w600,
                                        height: 1.6,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'We may collect non-personal usage data such as:\n'
                                      '• App usage events\n'
                                      '• Device type and operating system\n'
                                      '• Crash reports\n'
                                      '• Performance metrics\n\n'
                                      'This data is used only to improve app performance and reliability.',
                                      style: scaledBodyStyle.copyWith(height: 1.6),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'c. Advertising Data',
                                      style: scaledBodyStyle.copyWith(
                                        fontWeight: FontWeight.w600,
                                        height: 1.6,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'The free version of LunaRae displays ads through Google AdMob. Ad providers may collect:\n'
                                      '• Device identifiers\n'
                                      '• Approximate location (non-precise)\n'
                                      '• Ad interaction data\n\n'
                                      'LunaRae does not control how third-party ad platforms use their data. Please refer to Google\'s Privacy Policy for details.',
                                      style: scaledBodyStyle.copyWith(height: 1.6),
                                    ),
                                    const SizedBox(height: 20),
                                    _SectionTitle(title: '2. How We Use Your Information'),
                                    const SizedBox(height: 8),
                                    Text(
                                      'We use collected data only to:\n'
                                      '• Generate bedtime stories using AI\n'
                                      '• Improve app functionality and performance\n'
                                      '• Display advertisements in the free version\n'
                                      '• Monitor app stability and crash behavior\n\n'
                                      'We do not sell user data.\n'
                                      'We do not track personal identity.\n'
                                      'We do not build user profiles.',
                                      style: scaledBodyStyle.copyWith(height: 1.6),
                                    ),
                                    const SizedBox(height: 20),
                                    _SectionTitle(title: '3. Use of OpenAI Technology'),
                                    const SizedBox(height: 8),
                                    Text(
                                      'LunaRae uses OpenAI technology to generate its bedtime stories. This means:\n'
                                      '• The story prompt you enter is sent securely to OpenAI\'s servers for processing.\n'
                                      '• OpenAI processes the content only to generate the story response.\n'
                                      '• LunaRae does not train its own AI models using your data.\n'
                                      '• LunaRae does not sell or reuse your prompts for AI training purposes.\n'
                                      '• LunaRae is not affiliated with, endorsed by, or partnered with OpenAI.\n\n'
                                      'You can review OpenAI\'s Privacy Policy here:\n'
                                      'https://www.openai.com/privacy',
                                      style: scaledBodyStyle.copyWith(height: 1.6),
                                    ),
                                    const SizedBox(height: 20),
                                    _SectionTitle(title: '4. Children\'s Privacy'),
                                    const SizedBox(height: 8),
                                    Text(
                                      'LunaRae is designed with child-friendly content in mind. However:\n'
                                      '• The app does not knowingly collect personal information from children.\n'
                                      '• Parents and guardians are encouraged to supervise use.\n'
                                      '• Users should never enter real personal details into story prompts.',
                                      style: scaledBodyStyle.copyWith(height: 1.6),
                                    ),
                                    const SizedBox(height: 20),
                                    _SectionTitle(title: '5. Data Storage & Security'),
                                    const SizedBox(height: 8),
                                    Text(
                                      'We take reasonable technical measures to protect user data. Story prompts are processed temporarily to generate results and are not permanently stored by LunaRae.\n\n'
                                      'However, no digital system is 100% secure.',
                                      style: scaledBodyStyle.copyWith(height: 1.6),
                                    ),
                                    const SizedBox(height: 20),
                                    _SectionTitle(title: '6. Your Rights Under GDPR'),
                                    const SizedBox(height: 8),
                                    Text(
                                      'If you are located in the European Economic Area (EEA), you have the right to:\n'
                                      '• Request deletion of data\n'
                                      '• Request access to stored data\n'
                                      '• Request correction of inaccurate data\n\n'
                                      'Because we do not store personal identity information, most data is anonymized and cannot be linked to individuals.',
                                      style: scaledBodyStyle.copyWith(height: 1.6),
                                    ),
                                    const SizedBox(height: 20),
                                    _SectionTitle(title: '7. Third-Party Services'),
                                    const SizedBox(height: 8),
                                    Text(
                                      'LunaRae uses the following third-party services:\n'
                                      '• OpenAI (story generation)\n'
                                      '• Google AdMob (advertising)\n'
                                      '• Firebase Analytics & Crash Reporting (performance monitoring)\n\n'
                                      'Each provider has its own privacy policy.',
                                      style: scaledBodyStyle.copyWith(height: 1.6),
                                    ),
                                    const SizedBox(height: 20),
                                    _SectionTitle(title: '8. Changes to This Privacy Policy'),
                                    const SizedBox(height: 8),
                                    Text(
                                      'We may update this Privacy Policy occasionally. Any updates will be reflected inside the app.\n\n'
                                      'Continued use of LunaRae after updates indicates acceptance of the revised policy.',
                                      style: scaledBodyStyle.copyWith(height: 1.6),
                                    ),
                                    const SizedBox(height: 20),
                                    _SectionTitle(title: '9. Contact Information'),
                                    const SizedBox(height: 8),
                                    Text(
                                      'If you have questions about this Privacy Policy, you may contact:\n\n'
                                      '📧 support@lunarae.app\n'
                                      '(Replace with your final support email before publishing)',
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
        Text(
          'Privacy Policy',
          style: textStyle.copyWith(
            color: linkColor,
            fontWeight: FontWeight.w600,
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