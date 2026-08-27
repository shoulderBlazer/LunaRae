import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Product IDs for Story Weaver subscriptions
class SubscriptionProductIds {
  static const String monthly = 'com.lunarae.mobile.storyweaver.monthly';
  static const String yearly = 'com.lunarae.mobile.storyweaver.yearly';
  
  static const List<String> all = [monthly, yearly];
}

/// Subscription status enum
enum SubscriptionStatus {
  notSubscribed,
  active,
  expired,
  pending,
  unknown,
}

/// Subscription tier enum
enum SubscriptionTier {
  free,
  storyWeaver,
  storyLibrary, // Future
}

/// Product ID to tier mapping
class SubscriptionTierMapping {
  static const Map<String, SubscriptionTier> productTierMap = {
    SubscriptionProductIds.monthly: SubscriptionTier.storyWeaver,
    SubscriptionProductIds.yearly: SubscriptionTier.storyWeaver,
    // Future: Add storylibrary.monthly and storylibrary.yearly
    // 'com.lunarae.mobile.storylibrary.monthly': SubscriptionTier.storyLibrary,
    // 'com.lunarae.mobile.storylibrary.yearly': SubscriptionTier.storyLibrary,
  };

  static SubscriptionTier tierFromProductId(String productId) {
    return productTierMap[productId] ?? SubscriptionTier.free;
  }
}

/// Subscription details
class SubscriptionDetails {
  final String productId;
  final SubscriptionStatus status;
  final DateTime? expiryDate;
  final String? transactionId;
  
  SubscriptionDetails({
    required this.productId,
    required this.status,
    this.expiryDate,
    this.transactionId,
  });
  
  bool get isActive => status == SubscriptionStatus.active;
}


/// Service to handle Apple subscriptions for Story Weaver
class SubscriptionService extends ChangeNotifier {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  // Product details
  ProductDetails? _monthlyProduct;
  ProductDetails? _yearlyProduct;
  bool _productsLoaded = false;
  
  // Subscription state
  SubscriptionDetails? _currentSubscription;
  bool _isInitialized = false;
  
  // Debug flag to prevent automatic subscription restore
  bool _debugSkipRestore = false;
  
  // Daily story tracking
  SharedPreferences? _prefs;
  static const String _dailyStoryCountKey = 'daily_story_count';
  static const String _dailyResetDateKey = 'daily_reset_date';
  
  // Getters
  ProductDetails? get monthlyProduct => _monthlyProduct;
  ProductDetails? get yearlyProduct => _yearlyProduct;
  bool get productsLoaded => _productsLoaded;
  SubscriptionDetails? get currentSubscription => _currentSubscription;
  bool get isSubscribed => _currentSubscription?.isActive ?? false;
  bool get isInitialized => _isInitialized;

  String get currentSubscriptionName {
    if (!isSubscribed) {
      return 'Free Plan';
    }

    debugPrint('[SubscriptionService] currentSubscriptionName - productId: ${_currentSubscription?.productId}');
    debugPrint('[SubscriptionService] currentSubscriptionName - monthly ID: ${SubscriptionProductIds.monthly}');
    debugPrint('[SubscriptionService] currentSubscriptionName - yearly ID: ${SubscriptionProductIds.yearly}');

    switch (currentTier) {
      case SubscriptionTier.storyWeaver:
        if (_currentSubscription?.productId == SubscriptionProductIds.monthly) {
          debugPrint('[SubscriptionService] Detected as Monthly');
          return 'Story Weaver Monthly';
        }
        if (_currentSubscription?.productId == SubscriptionProductIds.yearly) {
          debugPrint('[SubscriptionService] Detected as Yearly');
          return 'Story Weaver Yearly';
        }
        debugPrint('[SubscriptionService] Unknown product ID, defaulting to Story Weaver');
        return 'Story Weaver';

      case SubscriptionTier.storyLibrary:
        return 'Story Library';

      case SubscriptionTier.free:
        return 'Free Plan';
      }
    }
  
  /// Check if user is subscribed to monthly plan
  bool get isSubscribedToMonthly {
    return isSubscribed && _currentSubscription?.productId == SubscriptionProductIds.monthly;
  }
  
  /// Check if user is subscribed to yearly plan
  bool get isSubscribedToYearly {
    return isSubscribed && _currentSubscription?.productId == SubscriptionProductIds.yearly;
  }
  
  // Computed properties
  SubscriptionTier get currentTier {
    // On Android, always return free tier since subscriptions are disabled
    // This enforces the 2 stories per day limit even in debug mode
    if (!Platform.isIOS) {
      debugPrint('[SubscriptionService] Android platform - enforcing free tier with 2 stories/day limit');
      return SubscriptionTier.free;
    }
    
    if (_currentSubscription?.isActive == true && _currentSubscription!.productId.isNotEmpty) {
      return SubscriptionTierMapping.tierFromProductId(_currentSubscription!.productId);
    }
    return SubscriptionTier.free;
  }
  
  int? get dailyLimit => getDailyLimit(currentTier);
  
  bool get adsEnabled => currentTier == SubscriptionTier.free;
  
  bool get fastGenerationEnabled => currentTier != SubscriptionTier.free;
  
  /// Check if subscriptions are available on this platform
  /// Subscriptions are only available on iOS - Android users are always on free plan
  bool get isSubscriptionsAvailable => Platform.isIOS;
  
  bool get hasUnlimitedStories => dailyLimit == null;

  int get storiesUsedToday {
    try {
      return _prefs?.getInt(_dailyStoryCountKey) ?? 0;
    } catch (e) {
      debugPrint('[SubscriptionService] Error reading story count: $e');
      return 0;
    }
  }
  
  int? get storiesRemainingToday {
    if (hasUnlimitedStories) return null;
    final limit = dailyLimit;
    if (limit == null) return null;
    final used = storiesUsedToday;
    final remaining = limit - used;
    return remaining > 0 ? remaining : 0;
  }
  
  /// Initialize the subscription service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    debugPrint('[SubscriptionService] Initializing...');
    
    // Initialize SharedPreferences (needed on all platforms for daily story tracking)
    try {
      _prefs = await SharedPreferences.getInstance();
      debugPrint('[SubscriptionService] SharedPreferences initialized');
    } catch (e) {
      debugPrint('[SubscriptionService] Error initializing SharedPreferences: $e');
      // Continue without SharedPreferences - app will use defaults
    }
    
    // Reset daily count if needed (needed on all platforms)
    await resetDailyCountIfNeeded();
    
    // Only initialize in-app purchases on iOS
    if (!Platform.isIOS) {
      debugPrint('[SubscriptionService] Not iOS platform, skipping in-app purchase initialization');
      _isInitialized = true;
      _logEntitlementState();
      return;
    }
    
    // Check if in-app purchases are available
    final bool isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      debugPrint('[SubscriptionService] In-app purchases not available');
      _isInitialized = true;
      _logEntitlementState();
      return;
    }
    
    // Listen to purchase updates
    final Stream<List<PurchaseDetails>> purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: _updateStreamOnDone,
      onError: _updateStreamOnError,
    );
    
    // Load products
    await loadProducts();
    
    // Check existing subscription status
    await checkSubscriptionStatus();
    
    _isInitialized = true;
    debugPrint('[SubscriptionService] Initialization complete');
    _logEntitlementState();
  }
  
  /// Load subscription products from App Store
  Future<void> loadProducts() async {
    // Only load products on iOS (Android uses free plan only)
    if (!Platform.isIOS) {
      debugPrint('[SubscriptionService] Not iOS platform, skipping product load');
      return;
    }
    
    debugPrint('[SubscriptionService] Loading products...');
    
    final Set<String> productIds = SubscriptionProductIds.all.toSet();
    final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(productIds);
    
    if (response.error != null) {
      debugPrint('[SubscriptionService] Error loading products: ${response.error}');
      return;
    }
    
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('[SubscriptionService] Products not found: ${response.notFoundIDs}');
    }
    
    for (var product in response.productDetails) {
      if (product.id == SubscriptionProductIds.monthly) {
        _monthlyProduct = product;
        debugPrint('[SubscriptionService] Monthly product loaded: ${product.title}');
      } else if (product.id == SubscriptionProductIds.yearly) {
        _yearlyProduct = product;
        debugPrint('[SubscriptionService] Yearly product loaded: ${product.title}');
      }
    }
    
    _productsLoaded = true;
    notifyListeners();
  }
  
  /// Purchase monthly subscription
  Future<bool> purchaseMonthly() async {
    if (_monthlyProduct == null) {
      debugPrint('[SubscriptionService] Monthly product not loaded');
      return false;
    }
    
    return _purchaseProduct(_monthlyProduct!);
  }
  
  /// Purchase yearly subscription
  Future<bool> purchaseYearly() async {
    if (_yearlyProduct == null) {
      debugPrint('[SubscriptionService] Yearly product not loaded');
      return false;
    }
    
    return _purchaseProduct(_yearlyProduct!);
  }
  
  /// Internal purchase method
  Future<bool> _purchaseProduct(ProductDetails product) async {
    debugPrint('[SubscriptionService] Purchasing: ${product.id}');
    
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    
    try {
      final bool success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      debugPrint('[SubscriptionService] Purchase initiated: $success');
      return success;
    } catch (e) {
      debugPrint('[SubscriptionService] Purchase error: $e');
      return false;
    }
  }
  
  /// Restore purchases
  Future<void> restorePurchases() async {
    debugPrint('[SubscriptionService] Restoring purchases...');
    
    try {
      await _inAppPurchase.restorePurchases();
      debugPrint('[SubscriptionService] Restore purchases initiated');
    } catch (e) {
      debugPrint('[SubscriptionService] Restore purchases error: $e');
    }
  }
  
  /// Debug method to clear subscription state (for sandbox testing)
  /// Call this to reset subscription status during development
  Future<void> debugClearSubscription() async {
    debugPrint('[SubscriptionService] DEBUG: Clearing subscription state');
    
    _currentSubscription = null;
    _debugSkipRestore = true; // Prevent automatic restore
    
    // Clear daily story count as well
    if (_prefs != null) {
      await _prefs?.setInt(_dailyStoryCountKey, 0);
      await _prefs?.setInt(_dailyResetDateKey, _dateToYyyyMmDd(DateTime.now()));
    }
    
    notifyListeners();
    debugPrint('[SubscriptionService] DEBUG: Subscription state cleared, automatic restore disabled');
  }
  
  /// Debug method to re-enable subscription restore (for sandbox testing)
  /// Call this after clearing subscription to test subscription flow again
  Future<void> debugEnableRestore() async {
    debugPrint('[SubscriptionService] DEBUG: Re-enabling subscription restore');
    _debugSkipRestore = false;
    notifyListeners();
    debugPrint('[SubscriptionService] DEBUG: Subscription restore re-enabled');
  }
  
  /// Handle purchase updates
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    debugPrint('[SubscriptionService] _onPurchaseUpdate received ${purchaseDetailsList.length} purchases');
    
    // DIAGNOSTIC: Log detailed information about each purchase
    for (final PurchaseDetails purchase in purchaseDetailsList) {
      debugPrint('[SubscriptionService] PurchaseDetails:');
      debugPrint('  Product ID: ${purchase.productID}');
      debugPrint('  Status: ${purchase.status}');
      debugPrint('  Purchase ID: ${purchase.purchaseID}');
      debugPrint('  Transaction Date: ${purchase.transactionDate}');
      debugPrint('  Pending Complete Purchase: ${purchase.pendingCompletePurchase}');
      debugPrint('  Error: ${purchase.error}');
    }
    
    // Sort purchases to prioritize yearly subscriptions
    final sortedPurchases = List<PurchaseDetails>.from(purchaseDetailsList);
    sortedPurchases.sort((a, b) {
      // Put yearly subscriptions first
      if (a.productID == SubscriptionProductIds.yearly && b.productID != SubscriptionProductIds.yearly) {
        return -1;
      }
      if (a.productID != SubscriptionProductIds.yearly && b.productID == SubscriptionProductIds.yearly) {
        return 1;
      }
      return 0;
    });
    
    for (final PurchaseDetails purchaseDetails in sortedPurchases) {
      debugPrint('[SubscriptionService] Processing purchase: ${purchaseDetails.productID}, status: ${purchaseDetails.status}');
      _handlePurchase(purchaseDetails);
    }
  }
  
  /// Handle individual purchase
  Future<void> _handlePurchase(PurchaseDetails purchaseDetails) async {
    debugPrint('[SubscriptionService] Handling purchase: ${purchaseDetails.productID}, status: ${purchaseDetails.status}');
    
    switch (purchaseDetails.status) {
      case PurchaseStatus.pending:
        debugPrint('[SubscriptionService] Purchase pending');
        _updateSubscriptionStatus(
          productId: purchaseDetails.productID,
          status: SubscriptionStatus.pending,
          transactionId: purchaseDetails.purchaseID,
        );
        break;
        
      case PurchaseStatus.purchased:
        debugPrint('[SubscriptionService] New purchase successful');

        if (Platform.isIOS) {
          await _verifyAndFinishPurchase(purchaseDetails);
        }

        _updateSubscriptionStatus(
          productId: purchaseDetails.productID,
          status: SubscriptionStatus.active,
          transactionId: purchaseDetails.purchaseID,
        );
        break;

      case PurchaseStatus.restored:
        debugPrint(
          '[SubscriptionService] Restored purchase received: '
          '${purchaseDetails.productID}',
        );

        // A restored transaction is historical purchase information.
        // Do NOT automatically treat it as an active subscription here.
        //
        // The subscription must be validated before we grant the entitlement.
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }

        debugPrint(
          '[SubscriptionService] Restored transaction NOT automatically '
          'marked active: ${purchaseDetails.productID}',
        );
        break;

      case PurchaseStatus.error:
        debugPrint('[SubscriptionService] Purchase error: ${purchaseDetails.error}');
        _updateSubscriptionStatus(
          productId: purchaseDetails.productID,
          status: SubscriptionStatus.unknown,
          transactionId: purchaseDetails.purchaseID,
        );
        
        // Finish transaction even on error
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
        break;
        
      case PurchaseStatus.canceled:
        debugPrint('[SubscriptionService] Purchase canceled');
        _updateSubscriptionStatus(
          productId: purchaseDetails.productID,
          status: SubscriptionStatus.notSubscribed,
          transactionId: purchaseDetails.purchaseID,
        );
        
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
        break;
    }
  }
  
  /// Verify and finish purchase on iOS
  Future<void> _verifyAndFinishPurchase(PurchaseDetails purchaseDetails) async {
    try {
      // In production, you should verify the purchase with your backend
      // For now, we'll trust the local receipt (as per Apple's guidelines for simple apps)
      
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
        debugPrint('[SubscriptionService] Purchase completed');
      }
    } catch (e) {
      debugPrint('[SubscriptionService] Error completing purchase: $e');
    }
  }
  
  /// Update subscription status
  void _updateSubscriptionStatus({
    required String productId,
    required SubscriptionStatus status,
    String? transactionId,
  }) {
    // If upgrading from monthly to yearly, prefer the yearly subscription
    if (status == SubscriptionStatus.active && productId == SubscriptionProductIds.yearly) {
      debugPrint('[SubscriptionService] Yearly subscription detected, setting as current');
      _currentSubscription = SubscriptionDetails(
        productId: productId,
        status: status,
        transactionId: transactionId,
      );
    } else if (status == SubscriptionStatus.active && productId == SubscriptionProductIds.monthly) {
      // Only set monthly if we don't already have a yearly subscription
      if (_currentSubscription?.productId != SubscriptionProductIds.yearly) {
        debugPrint('[SubscriptionService] Monthly subscription detected, setting as current');
        _currentSubscription = SubscriptionDetails(
          productId: productId,
          status: status,
          transactionId: transactionId,
        );
      } else {
        debugPrint('[SubscriptionService] Monthly subscription detected but keeping yearly as current');
      }
    } else if (status == SubscriptionStatus.notSubscribed) {
      // Only clear subscription if it matches the product being cancelled
      if (_currentSubscription?.productId == productId) {
        debugPrint('[SubscriptionService] Subscription cancelled: $productId');
        _currentSubscription = null;
      } else {
        debugPrint('[SubscriptionService] Ignoring cancellation for different product: $productId vs ${_currentSubscription?.productId}');
      }
    } else {
      debugPrint('[SubscriptionService] Subscription updated: $productId, $status');
      _currentSubscription = SubscriptionDetails(
        productId: productId,
        status: status,
        transactionId: transactionId,
      );
    }

    debugPrint('[SubscriptionService] Final subscription state: ${_currentSubscription?.productId}, ${_currentSubscription?.status}');
    
    notifyListeners();
  }
  
  /// Check subscription status on app launch
  Future<void> checkSubscriptionStatus() async {
    // On Android, set to not subscribed (free plan)
    if (!Platform.isIOS) {
      debugPrint('[SubscriptionService] Android platform - setting to free plan');
      _updateSubscriptionStatus(
        productId: '',
        status: SubscriptionStatus.notSubscribed,
      );
      return;
    }
    
    debugPrint('[SubscriptionService] Checking subscription status...');
    
    // Skip restore if debug flag is set (for sandbox testing)
    if (_debugSkipRestore) {
      debugPrint('[SubscriptionService] DEBUG: Skipping subscription restore due to debug flag');
      _updateSubscriptionStatus(
        productId: '',
        status: SubscriptionStatus.notSubscribed,
      );
      return;
    }
    
    // Trigger restorePurchases() to let StoreKit deliver any updated transaction states
    // Note: We don't rely on restored transactions to set active status (see _handlePurchase)
    // This is primarily to ensure any pending transactions are completed
    debugPrint('[SubscriptionService] Triggering purchase restore for transaction completion');
    await restorePurchases();
    
    // The subscription state is now based on:
    // 1. Any purchase events received via the purchase stream (only PurchaseStatus.purchased sets active)
    // 2. Restored transactions are NOT automatically treated as active (see _handlePurchase)
    // 3. Users must manually restore purchases after app restart to regain access
  }
  
  /// Force refresh subscription status by restoring purchases
  /// Useful after upgrades or when subscription status might have changed
  Future<void> refreshSubscriptionStatus() async {
    debugPrint('[SubscriptionService] Force refreshing subscription status...');
    debugPrint('[SubscriptionService] Current subscription before refresh: ${_currentSubscription?.productId}');

    // On Android, ensure we're on free plan
    if (!Platform.isIOS) {
      debugPrint('[SubscriptionService] Android platform - ensuring free plan');
      _updateSubscriptionStatus(
        productId: '',
        status: SubscriptionStatus.notSubscribed,
      );
      return;
    }

    // Clear current subscription temporarily to force refresh
    _currentSubscription = null;
    notifyListeners();

    // Restore purchases to get latest status
    // Note: This will deliver restored transactions, but they won't automatically set the subscription as active
    // (see _handlePurchase for PurchaseStatus.restored handling)
    await restorePurchases();

    // Wait for restore to complete and process all purchases
    await Future.delayed(const Duration(milliseconds: 2000));

    // If no subscription found after restore, mark as not subscribed
    if (_currentSubscription == null) {
      _updateSubscriptionStatus(
        productId: '',
        status: SubscriptionStatus.notSubscribed,
      );
    }

    debugPrint('[SubscriptionService] Subscription status refreshed: ${_currentSubscription?.productId}');
    debugPrint('[SubscriptionService] isSubscribedToYearly: $isSubscribedToYearly');
    debugPrint('[SubscriptionService] isSubscribedToMonthly: $isSubscribedToMonthly');
    debugPrint('[SubscriptionService] currentSubscriptionName: $currentSubscriptionName');
  }
  
  /// Stream done callback
  void _updateStreamOnDone() {
    debugPrint('[SubscriptionService] Purchase stream done');
    _subscription?.cancel();
  }
  
  /// Stream error callback
  void _updateStreamOnError(dynamic error) {
    debugPrint('[SubscriptionService] Purchase stream error: $error');
  }
  
  /// Get daily limit for a subscription tier
  int? getDailyLimit(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return 2;
      case SubscriptionTier.storyWeaver:
        return 5;
      case SubscriptionTier.storyLibrary:
        return null; // Unlimited
    }
  }
  
  /// Convert DateTime to YYYYMMDD integer using local timezone
  int _dateToYyyyMmDd(DateTime date) {
    final localDate = date.toLocal();
    return localDate.year * 10000 + localDate.month * 100 + localDate.day;
  }
  
  /// Reset daily story count if the calendar date has changed
  Future<void> resetDailyCountIfNeeded() async {
    if (_prefs == null) return;
    
    try {
      final today = _dateToYyyyMmDd(DateTime.now());
      final storedDate = _prefs?.getInt(_dailyResetDateKey);

      if (storedDate == null || storedDate != today) {
        debugPrint('[SubscriptionService] Resetting daily story count. Previous date: $storedDate, Today: $today');
        await _prefs?.setInt(_dailyStoryCountKey, 0);
        await _prefs?.setInt(_dailyResetDateKey, today);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[SubscriptionService] Error resetting daily count: $e');
      // Continue with existing count
    }
  }
  
  /// Get duration until next daily reset (midnight local time)
  Duration untilNextReset() {
    final now = DateTime.now().toLocal();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    return midnight.difference(now);
  }

    /// Returns true if the user can generate another story today.
  Future<bool> canGenerateStory() async {
    await resetDailyCountIfNeeded();

    final remaining = storiesRemainingToday;

    debugPrint(
      '[SubscriptionService] canGenerateStory -> used=$storiesUsedToday, remaining=$remaining, limit=$dailyLimit',
    );

    if (hasUnlimitedStories) {
      return true;
    }

    return remaining == null || remaining > 0;
  }

  /// Records that a story has been successfully generated.
  Future<void> recordStoryGenerated() async {
    if (_prefs == null) return;

    await resetDailyCountIfNeeded();

    try {
      final currentCount = storiesUsedToday;
      final newCount = currentCount + 1;

      debugPrint(
  '[SubscriptionService] Recording story -> current=$currentCount new=$newCount',
);

      await _prefs!.setInt(_dailyStoryCountKey, newCount);

      debugPrint(
        '[SubscriptionService] Story generated. Count: $newCount/${dailyLimit ?? "unlimited"}',
      );

      notifyListeners();
    } catch (e) {
      debugPrint(
        '[SubscriptionService] Failed to record generated story: $e',
      );
    }
  }

  /// Returns true when the user has reached today's story limit.
  Future<bool> hasReachedDailyLimit() async {
    return !(await canGenerateStory());
  }

  /// Resets today's story count back to zero.
  Future<void> resetDailyStoryCount() async {
    if (_prefs == null) return;

    try {
      await _prefs!.setInt(_dailyStoryCountKey, 0);
      await _prefs!.setInt(
        _dailyResetDateKey,
        _dateToYyyyMmDd(DateTime.now()),
      );

      debugPrint('[SubscriptionService] Daily story count manually reset');

      notifyListeners();
    } catch (e) {
      debugPrint(
        '[SubscriptionService] Failed to reset daily story count: $e',
      );
    }
  }
  
  /// Log current entitlement state for debugging
  void _logEntitlementState() {
    debugPrint('[SubscriptionService] Entitlement State:');
    debugPrint('  Current Tier: ${currentTier.name}');
    debugPrint('  Daily Limit: ${dailyLimit ?? "unlimited"}');
    debugPrint('  Stories Used Today: $storiesUsedToday');
    debugPrint('  Stories Remaining: ${storiesRemainingToday ?? "unlimited"}');
    debugPrint('  Ads Enabled: $adsEnabled');
    debugPrint('  Fast Generation Enabled: $fastGenerationEnabled');
  }
  
  /// Dispose the service
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
