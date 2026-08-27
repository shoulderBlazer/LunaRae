import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/theme.dart';
import '../services/subscription_service.dart';
import '../services/font_size_provider.dart';
import '../widgets/dreamy_widgets.dart' show DreamyBackground, DreamyPrimaryButton, MoonLoadingIndicator;
import '../widgets/frosted_header.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isPurchasingMonthly = false;
  bool _isPurchasingYearly = false;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    
    // Listen to subscription changes
    SubscriptionService().addListener(_onSubscriptionChanged);
  }

  @override
  void dispose() {
    SubscriptionService().removeListener(_onSubscriptionChanged);
    super.dispose();
  }

  void _onSubscriptionChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _purchaseMonthly() async {
    if (_isPurchasingMonthly) return;
    
    setState(() => _isPurchasingMonthly = true);
    
    final success = await SubscriptionService().purchaseMonthly();
    
    if (mounted) {
      setState(() => _isPurchasingMonthly = false);
      
      if (success) {
        // Force refresh subscription status to ensure UI updates immediately
        await SubscriptionService().refreshSubscriptionStatus();
        _showSuccess('Successfully subscribed to monthly plan!');
      } else {
        _showError('Unable to complete purchase. Please try again.');
      }
    }
  }

  Future<void> _purchaseYearly() async {
    if (_isPurchasingYearly) return;
    
    setState(() => _isPurchasingYearly = true);
    
    final success = await SubscriptionService().purchaseYearly();
    
    if (mounted) {
      setState(() => _isPurchasingYearly = false);
      
      if (success) {
        // Force refresh subscription status to ensure UI updates immediately
        await SubscriptionService().refreshSubscriptionStatus();
        _showSuccess('Successfully upgraded to yearly plan!');
      } else {
        _showError('Unable to complete purchase. Please try again.');
      }
    }
  }

  Future<void> _restorePurchases() async {
    if (_isRestoring) return;
    
    setState(() => _isRestoring = true);
    
    await SubscriptionService().restorePurchases();
    
    // Wait a moment for restore to complete
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() => _isRestoring = false);
      
      if (SubscriptionService().isSubscribed) {
        _showSuccess('Your subscription has been restored!');
      } else {
        _showError('No active subscription found.');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showSuccess(String message) {
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
  }

  Future<void> _manageSubscription() async {
    final url = Uri.parse('https://apps.apple.com/account/subscriptions');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showError('Unable to open subscription management page.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontSizeProvider = context.watch<FontSizeProvider>();
    final subscriptionService = SubscriptionService();
    
    // Only show on iOS
    if (!Platform.isIOS) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Story Weaver Premium'),
        ),
        body: const Center(
          child: Text('Subscriptions are only available on iOS'),
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      floatingActionButton: null,
      body: DreamyBackground(
        child: Stack(
          children: [
            // Main content
            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
                  child: Column(
                    children: [
                      // Logo
                      Image.asset(
                        'assets/images/lunarae_logo_1024x1024.png',
                        height: 120,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Title
                      Text(
                        "LunaRae's Subscriptions",
                        style: LunaTheme.appTitle(context).copyWith(
                          fontSize: 28 * fontSizeProvider.scaleFactor,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Subtitle
                      Text(
                        'More stories. More calm. More imagination.',
                        style: LunaTheme.body(context).copyWith(
                          fontSize: 16 * fontSizeProvider.scaleFactor,
                          color: LunaTheme.textPrimary(context).withValues(alpha: 0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Loading indicator
                      if (_isLoadingProducts)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: SizedBox(
                              width: 32,
                              height: 32,
                              child: MoonLoadingIndicator(),
                            ),
                          ),
                        ),
                      
                      // Subscribed users - Current Plan card (shown above subscription options)
                      if (subscriptionService.isSubscribed) ...[
                        _CurrentPlanCard(
                          subscriptionName: subscriptionService.currentSubscriptionName,
                          fontSizeProvider: fontSizeProvider,
                          onManageSubscription: _manageSubscription,
                        ),
                        
                        // Placeholder for future Story Library upgrade card
                        // const SizedBox(height: 16),
                        // _StoryLibraryUpgradeCard(),
                        
                        const SizedBox(height: 16),
                      ],
                      
                      // Free plan users - Current Plan card
                      if (!subscriptionService.isSubscribed) ...[
                        _FreePlanCard(
                          fontSizeProvider: fontSizeProvider,
                        ),
                        
                        const SizedBox(height: 16),
                      ],
                      
                      // CHANGED: Show subscription options based on current subscription status
                      // - If subscribed to monthly: hide monthly card, show yearly card with "Upgrade" button
                      // - If subscribed to yearly: hide both cards (user is already on best plan)
                      // - If not subscribed: show both cards with "Subscribe" buttons
                      
                      // Show monthly card only if not subscribed to any plan
                      if (!subscriptionService.isSubscribed) ...[
                        _SubscriptionOption(
                          title: 'Story Weaver Plan - Monthly',
                          price: subscriptionService.monthlyProduct?.price ?? 'Loading...',
                          description: 'Billed monthly',
                          onTap: _isPurchasingMonthly ? null : _purchaseMonthly,
                          isLoading: _isPurchasingMonthly,
                          isPopular: false,
                          fontSizeProvider: fontSizeProvider,
                          buttonText: 'Subscribe',
                          features: [
                            '🌙 5 stories every day',
                            '🚫 No adverts',
                            '✨ More bedtime magic',
                          ],
                        ),

                        const SizedBox(height: 16),
                      ],

                      // Show yearly card if not subscribed to yearly (but show if on monthly to allow upgrade)
                      if (!subscriptionService.isSubscribedToYearly) ...[
                        _SubscriptionOption(
                          title: 'Story Weaver Plan - Yearly',
                          price: subscriptionService.yearlyProduct?.price ?? 'Loading...',
                          description: 'Best value - Save 20%',
                          onTap: _isPurchasingYearly ? null : _purchaseYearly,
                          isLoading: _isPurchasingYearly,
                          isPopular: true,
                          fontSizeProvider: fontSizeProvider,
                          buttonText: subscriptionService.isSubscribedToMonthly ? 'Upgrade' : 'Subscribe',
                          showBestValueBadge: subscriptionService.isSubscribedToMonthly, // Show gold badge when on monthly
                          features: [
                            '🌙 5 stories every day',
                            '🚫 No adverts',
                            '✨ More bedtime magic',
                          ],
                        ),
                      ],
                      
                      const SizedBox(height: 24),
                      
                      // Restore purchases button
                      _RestoreButton(
                        onTap: _isRestoring ? null : _restorePurchases,
                        isLoading: _isRestoring,
                        fontSizeProvider: fontSizeProvider,
                      ),
                      
                      // Debug: Clear subscription button (only in debug mode)
                      if (kDebugMode) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () async {
                            await SubscriptionService().debugClearSubscription();
                            if (mounted) {
                              _showSuccess('Subscription state cleared (debug)');
                            }
                          },
                          child: Text(
                            'DEBUG: Clear Subscription',
                            style: TextStyle(
                              color: Colors.red.withValues(alpha: 0.7),
                              fontSize: 12 * fontSizeProvider.scaleFactor,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await SubscriptionService().debugEnableRestore();
                            if (mounted) {
                              _showSuccess('Subscription restore re-enabled (debug)');
                            }
                          },
                          child: Text(
                            'DEBUG: Re-enable Restore',
                            style: TextStyle(
                              color: Colors.green.withValues(alpha: 0.7),
                              fontSize: 12 * fontSizeProvider.scaleFactor,
                            ),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 16),
                      
                      // Terms text
                      Text(
                        'Subscription auto-renews unless cancelled. Cancel anytime in App Store.',
                        style: LunaTheme.hintText(context).copyWith(
                          fontSize: 12 * fontSizeProvider.scaleFactor,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            
            // Frosted header
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: FrostedHeader(
                showBranding: false,
                trailing: _CloseButton(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: LunaTheme.primary(context).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: LunaTheme.primary(context).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Icon(
          Icons.close,
          color: LunaTheme.primary(context),
          size: 22,
        ),
      ),
    );
  }
}

class _SubscriptionOption extends StatelessWidget {
  final String title;
  final String price;
  final String description;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isPopular;
  final FontSizeProvider fontSizeProvider;
  final String buttonText; // CHANGED: Added to allow custom button text
  final bool showBestValueBadge; // CHANGED: Added to show gold 'Best Value' badge
  final List<String> features; // Added to show features

  const _SubscriptionOption({
    required this.title,
    required this.price,
    required this.description,
    required this.onTap,
    required this.isLoading,
    required this.isPopular,
    required this.fontSizeProvider,
    this.buttonText = 'Subscribe', // Default value
    this.showBestValueBadge = false, // Default value
    this.features = const [], // Default value
  });

  @override
  Widget build(BuildContext context) {
    final isDark = LunaTheme.isDarkMode(context);
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? LunaTheme.darkCard : LunaTheme.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPopular
              ? LunaTheme.primary(context)
              : LunaTheme.primary(context).withValues(alpha: 0.3),
          width: isPopular ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: LunaTheme.primary(context).withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (isPopular)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: showBestValueBadge ? const Color(0xFFFFD700) : LunaTheme.primary(context),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: Text(
                showBestValueBadge ? 'BEST VALUE' : 'MOST POPULAR',
                style: TextStyle(
                  color: showBestValueBadge 
                      ? Colors.black 
                      : (isDark ? LunaTheme.darkCard : LunaTheme.lightCard),
                  fontSize: 11 * fontSizeProvider.scaleFactor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: isPopular ? 16 : 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: LunaTheme.appTitle(context).copyWith(
                              fontSize: 20 * fontSizeProvider.scaleFactor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            price,
                            style: LunaTheme.body(context).copyWith(
                              fontSize: 18 * fontSizeProvider.scaleFactor,
                              color: LunaTheme.primary(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: LunaTheme.hintText(context).copyWith(
                              fontSize: 14 * fontSizeProvider.scaleFactor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 100,
                      height: 44,
                      child: DreamyPrimaryButton(
                        text: buttonText, // CHANGED: Use custom button text
                        onPressed: onTap,
                        isLoading: isLoading,
                        compact: true,
                      ),
                    ),
                  ],
                ),
                if (features.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...features.map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      feature,
                      style: LunaTheme.body(context).copyWith(
                        fontSize: 14 * fontSizeProvider.scaleFactor,
                      ),
                    ),
                  )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RestoreButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isLoading;
  final FontSizeProvider fontSizeProvider;

  const _RestoreButton({
    required this.onTap,
    required this.isLoading,
    required this.fontSizeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: LunaTheme.primary(context).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 16,
                height: 16,
                child: MoonLoadingIndicator(
                  size: 16,
                  color: LunaTheme.primary(context),
                ),
              )
            else
              Icon(
                Icons.restore,
                color: LunaTheme.primary(context),
                size: 18,
              ),
            const SizedBox(width: 8),
            Text(
              isLoading ? 'Restoring...' : 'Restore Purchases',
              style: TextStyle(
                color: LunaTheme.primary(context),
                fontSize: 14 * fontSizeProvider.scaleFactor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentPlanCard extends StatelessWidget {
  final String subscriptionName;
  final FontSizeProvider fontSizeProvider;
  final VoidCallback onManageSubscription;

  const _CurrentPlanCard({
    required this.subscriptionName,
    required this.fontSizeProvider,
    required this.onManageSubscription,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = LunaTheme.isDarkMode(context);
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? LunaTheme.darkCard : LunaTheme.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: LunaTheme.primary(context),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: LunaTheme.primary(context).withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with check icon
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Current Plan',
                  style: TextStyle(
                    color: LunaTheme.primary(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 16 * fontSizeProvider.scaleFactor,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Subscription name
            Text(
              subscriptionName,
              style: LunaTheme.appTitle(context).copyWith(
                fontSize: 24 * fontSizeProvider.scaleFactor,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Benefits list
            _BenefitItem(
              icon: Icons.check_circle,
              text: '🌙 5 stories every day',
              fontSizeProvider: fontSizeProvider,
            ),
            const SizedBox(height: 12),
            _BenefitItem(
              icon: Icons.check_circle,
              text: '🚫 No adverts',
              fontSizeProvider: fontSizeProvider,
            ),
            const SizedBox(height: 12),
            _BenefitItem(
              icon: Icons.check_circle,
              text: '✨ More bedtime magic',
              fontSizeProvider: fontSizeProvider,
            ),
            
            const SizedBox(height: 24),
            
            // Manage Subscription button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: DreamyPrimaryButton(
                text: 'Manage',
                onPressed: onManageSubscription,
                textStyle: LunaTheme.buttonText(context).copyWith(
                  fontSize: 18 * fontSizeProvider.scaleFactor,
                ),
                fitText: false,
                compact: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FreePlanCard extends StatelessWidget {
  final FontSizeProvider fontSizeProvider;

  const _FreePlanCard({
    required this.fontSizeProvider,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = LunaTheme.isDarkMode(context);
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? LunaTheme.darkCard : LunaTheme.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: LunaTheme.primary(context).withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: LunaTheme.primary(context).withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header badge like Most Popular
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: LunaTheme.primary(context).withValues(alpha: 0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Text(
              'CURRENT PLAN',
              style: TextStyle(
                color: isDark ? LunaTheme.darkCard : LunaTheme.lightCard,
                fontSize: 11 * fontSizeProvider.scaleFactor,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plan name
                Text(
                  'Free Plan',
                  style: LunaTheme.appTitle(context).copyWith(
                    fontSize: 18 * fontSizeProvider.scaleFactor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Benefits list
                Row(
                  children: [
                    Icon(
                      Icons.star_outline,
                      color: LunaTheme.primary(context),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '2 stories with ads',
                      style: LunaTheme.body(context).copyWith(
                        fontSize: 13 * fontSizeProvider.scaleFactor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final FontSizeProvider fontSizeProvider;

  const _BenefitItem({
    required this.icon,
    required this.text,
    required this.fontSizeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: LunaTheme.primary(context),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: LunaTheme.body(context).copyWith(
              fontSize: 15 * fontSizeProvider.scaleFactor,
            ),
          ),
        ),
      ],
    );
  }
}
