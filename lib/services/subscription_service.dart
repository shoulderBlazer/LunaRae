import 'dart:async';
import 'dart:convert';
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
enum SubscriptionStatus { notSubscribed, active, expired, pending, unknown }

/// Result of an App Store purchase or restore action.
///
/// A successful result is only produced after StoreKit sends an update through
/// [InAppPurchase.purchaseStream]; `buyNonConsumable` starting successfully is
/// not itself proof of entitlement.
enum SubscriptionActionResult {
  success,
  canceled,
  error,
  timedOut,
  unavailable,
  noActiveSubscription,
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

  bool get isActive =>
      status == SubscriptionStatus.active &&
      expiryDate != null &&
      expiryDate!.isAfter(DateTime.now().toUtc());
}

class _StoreKitTransactionData {
  final bool wasDecoded;
  final String? productId;
  final DateTime? expiryDate;
  final String? revocationDate;

  const _StoreKitTransactionData({
    this.wasDecoded = false,
    this.productId,
    this.expiryDate,
    this.revocationDate,
  });
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
  Completer<SubscriptionActionResult>? _purchaseActionCompleter;
  String? _purchaseProductId;
  bool _isPurchasePending = false;
  Future<void> _purchaseUpdateQueue = Future<void>.value();

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
  bool get isPurchaseInProgress => _purchaseActionCompleter != null;
  bool get isPurchasePending => _isPurchasePending;

  String get currentSubscriptionName {
    if (!isSubscribed) {
      return 'Free Plan';
    }

    switch (currentTier) {
      case SubscriptionTier.storyWeaver:
        if (_currentSubscription?.productId == SubscriptionProductIds.monthly) {
          return 'Story Weaver Monthly';
        }
        if (_currentSubscription?.productId == SubscriptionProductIds.yearly) {
          return 'Story Weaver Yearly';
        }
        return 'Story Weaver';

      case SubscriptionTier.storyLibrary:
        return 'Story Library';

      case SubscriptionTier.free:
        return 'Free Plan';
    }
  }

  /// Check if user is subscribed to monthly plan
  bool get isSubscribedToMonthly {
    return isSubscribed &&
        _currentSubscription?.productId == SubscriptionProductIds.monthly;
  }

  /// Check if user is subscribed to yearly plan
  bool get isSubscribedToYearly {
    return isSubscribed &&
        _currentSubscription?.productId == SubscriptionProductIds.yearly;
  }

  // Computed properties
  SubscriptionTier get currentTier {
    // On Android, always return free tier since subscriptions are disabled
    // This enforces the 2 stories per day limit even in debug mode
    if (!Platform.isIOS) {
      return SubscriptionTier.free;
    }

    if (_currentSubscription?.isActive == true &&
        _currentSubscription!.productId.isNotEmpty) {
      return SubscriptionTierMapping.tierFromProductId(
        _currentSubscription!.productId,
      );
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

    // Initialize SharedPreferences (needed on all platforms for daily story tracking)
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint(
        '[SubscriptionService] Error initializing SharedPreferences: $e',
      );
      // Continue without SharedPreferences - app will use defaults
    }

    // Reset daily count if needed (needed on all platforms)
    await resetDailyCountIfNeeded();

    // Only initialize in-app purchases on iOS
    if (!Platform.isIOS) {
      _isInitialized = true;
      return;
    }

    // Check if in-app purchases are available
    final bool isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      debugPrint('[SubscriptionService] In-app purchases not available');
      _isInitialized = true;
      return;
    }

    // Listen to purchase updates
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
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
  }

  /// Load subscription products from App Store
  Future<void> loadProducts() async {
    // Only load products on iOS (Android uses free plan only)
    if (!Platform.isIOS) {
      return;
    }

    final Set<String> productIds = SubscriptionProductIds.all.toSet();
    final ProductDetailsResponse response = await _inAppPurchase
        .queryProductDetails(productIds);

    if (response.error != null) {
      debugPrint(
        '[SubscriptionService] Error loading products: ${response.error}',
      );
      return;
    }

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint(
        '[SubscriptionService] Products not found: ${response.notFoundIDs}',
      );
    }

    for (var product in response.productDetails) {
      if (product.id == SubscriptionProductIds.monthly) {
        _monthlyProduct = product;
      } else if (product.id == SubscriptionProductIds.yearly) {
        _yearlyProduct = product;
      }
    }

    _productsLoaded = true;
    notifyListeners();
  }

  /// Purchase monthly subscription
  Future<SubscriptionActionResult> purchaseMonthly() async {
    if (_monthlyProduct == null) {
      debugPrint('[SubscriptionService] Monthly product not loaded');
      return SubscriptionActionResult.unavailable;
    }

    return _purchaseProduct(_monthlyProduct!);
  }

  /// Purchase yearly subscription
  Future<SubscriptionActionResult> purchaseYearly() async {
    if (_yearlyProduct == null) {
      debugPrint('[SubscriptionService] Yearly product not loaded');
      return SubscriptionActionResult.unavailable;
    }

    return _purchaseProduct(_yearlyProduct!);
  }

  /// Internal purchase method
  Future<SubscriptionActionResult> _purchaseProduct(
    ProductDetails product,
  ) async {
    if (_purchaseActionCompleter != null) {
      return SubscriptionActionResult.error;
    }

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    final completer = Completer<SubscriptionActionResult>();
    _purchaseActionCompleter = completer;
    _purchaseProductId = product.id;
    _isPurchasePending = false;
    notifyListeners();

    try {
      final bool started = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
      if (!started) {
        _completePurchaseAction(SubscriptionActionResult.error);
      }
    } catch (e) {
      debugPrint('[SubscriptionService] Purchase error: $e');
      _completePurchaseAction(SubscriptionActionResult.error);
    }

    return completer.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () {
        debugPrint(
          '[SubscriptionService] Timed out waiting for purchase update',
        );
        _completePurchaseAction(SubscriptionActionResult.timedOut);
        return SubscriptionActionResult.timedOut;
      },
    );
  }

  /// Restore purchases
  Future<SubscriptionActionResult> restorePurchases() async {
    if (!Platform.isIOS) {
      return SubscriptionActionResult.unavailable;
    }

    try {
      await _inAppPurchase.restorePurchases();

      // The generic in_app_purchase API delivers restored transactions through
      // purchaseStream and does not expose a separate restore-complete event.
      // Give queued stream updates a chance to finish before reporting the
      // StoreKit-derived entitlement result to the caller.
      await Future<void>.delayed(const Duration(seconds: 2));
      await _purchaseUpdateQueue;
      return isSubscribed
          ? SubscriptionActionResult.success
          : SubscriptionActionResult.noActiveSubscription;
    } catch (e) {
      debugPrint('[SubscriptionService] Restore purchases error: $e');
      return SubscriptionActionResult.error;
    }
  }

  /// Handle purchase updates
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    // Sort purchases to prioritize yearly subscriptions
    final sortedPurchases = List<PurchaseDetails>.from(purchaseDetailsList);
    sortedPurchases.sort((a, b) {
      // Put yearly subscriptions first
      if (a.productID == SubscriptionProductIds.yearly &&
          b.productID != SubscriptionProductIds.yearly) {
        return -1;
      }
      if (a.productID != SubscriptionProductIds.yearly &&
          b.productID == SubscriptionProductIds.yearly) {
        return 1;
      }
      return 0;
    });

    _purchaseUpdateQueue = _purchaseUpdateQueue
        .then((_) async {
          for (final PurchaseDetails purchaseDetails in sortedPurchases) {
            await _handlePurchase(purchaseDetails);
          }
        })
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint(
            '[SubscriptionService] Error processing purchase update: $error',
          );
        });
  }

  /// Handle individual purchase
  Future<void> _handlePurchase(PurchaseDetails purchaseDetails) async {
    switch (purchaseDetails.status) {
      case PurchaseStatus.pending:
        // Do not replace an existing entitlement while an upgrade or renewal is
        // pending. The terminal stream update determines the final state.
        _isPurchasePending = true;
        notifyListeners();
        break;

      case PurchaseStatus.purchased:
        await _completePurchaseIfNeeded(purchaseDetails);
        final transactionData = _activeSubscriptionTransactionData(
          purchaseDetails,
        );
        if (transactionData == null) {
          debugPrint(
            '[SubscriptionService] Ignoring inactive or unverifiable purchased '
            'subscription: ${purchaseDetails.productID}',
          );
          _completePurchaseAction(
            SubscriptionActionResult.error,
            purchaseDetails.productID,
          );
          break;
        }

        _updateSubscriptionStatus(
          productId: purchaseDetails.productID,
          status: SubscriptionStatus.active,
          expiryDate: transactionData.expiryDate,
          transactionId: purchaseDetails.purchaseID,
        );
        _completePurchaseAction(
          SubscriptionActionResult.success,
          purchaseDetails.productID,
        );
        break;

      case PurchaseStatus.restored:
        await _completePurchaseIfNeeded(purchaseDetails);
        final transactionData = _activeSubscriptionTransactionData(
          purchaseDetails,
        );
        if (transactionData == null) {
          debugPrint(
            '[SubscriptionService] Ignoring inactive or unverifiable restored '
            'subscription: ${purchaseDetails.productID}',
          );
          break;
        }

        _updateSubscriptionStatus(
          productId: purchaseDetails.productID,
          status: SubscriptionStatus.active,
          expiryDate: transactionData.expiryDate,
          transactionId: purchaseDetails.purchaseID,
        );
        _completePurchaseAction(
          SubscriptionActionResult.success,
          purchaseDetails.productID,
        );
        break;

      case PurchaseStatus.error:
        debugPrint(
          '[SubscriptionService] Purchase error: ${purchaseDetails.error}',
        );
        // An unsuccessful purchase attempt must not revoke an already-active
        // monthly or yearly entitlement.
        await _completePurchaseIfNeeded(purchaseDetails);
        _completePurchaseAction(
          SubscriptionActionResult.error,
          purchaseDetails.productID,
        );
        break;

      case PurchaseStatus.canceled:
        // Cancelling the purchase sheet is not the same as cancelling an
        // existing subscription in App Store settings.
        await _completePurchaseIfNeeded(purchaseDetails);
        _completePurchaseAction(
          SubscriptionActionResult.canceled,
          purchaseDetails.productID,
        );
        break;
    }
  }

  /// StoreKit 2 supplies a locally verified JWS for subscription transactions.
  /// A transaction is not an entitlement unless its subscription expiry is
  /// still in the future.
  _StoreKitTransactionData? _activeSubscriptionTransactionData(
    PurchaseDetails purchaseDetails,
  ) {
    if (!SubscriptionProductIds.all.contains(purchaseDetails.productID)) {
      return null;
    }

    final data = _readStoreKitTransactionData(purchaseDetails);
    final now = DateTime.now().toUtc();
    final isActive =
        data.wasDecoded &&
        data.productId == purchaseDetails.productID &&
        data.revocationDate == null &&
        data.expiryDate != null &&
        data.expiryDate!.isAfter(now);
    return isActive ? data : null;
  }

  _StoreKitTransactionData _readStoreKitTransactionData(
    PurchaseDetails purchaseDetails,
  ) {
    try {
      final parts = purchaseDetails.verificationData.serverVerificationData
          .split('.');
      if (parts.length != 3) {
        return const _StoreKitTransactionData();
      }
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map<String, dynamic>) {
        return const _StoreKitTransactionData();
      }
      final rawExpiresDate = payload['expiresDate'];
      final expiresMilliseconds = rawExpiresDate is int
          ? rawExpiresDate
          : int.tryParse(rawExpiresDate?.toString() ?? '');
      return _StoreKitTransactionData(
        wasDecoded: true,
        productId: payload['productId']?.toString(),
        expiryDate: expiresMilliseconds == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                expiresMilliseconds,
                isUtc: true,
              ),
        revocationDate: payload['revocationDate']?.toString(),
      );
    } catch (_) {
      return const _StoreKitTransactionData();
    }
  }

  /// Finish a StoreKit transaction after the purchase stream has delivered it.
  Future<void> _completePurchaseIfNeeded(
    PurchaseDetails purchaseDetails,
  ) async {
    try {
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    } catch (e) {
      debugPrint('[SubscriptionService] Error completing purchase: $e');
    }
  }

  void _completePurchaseAction(
    SubscriptionActionResult result, [
    String? productId,
  ]) {
    if (_purchaseActionCompleter == null ||
        (productId != null && productId != _purchaseProductId)) {
      return;
    }

    final completer = _purchaseActionCompleter!;
    _purchaseActionCompleter = null;
    _purchaseProductId = null;
    _isPurchasePending = false;
    if (!completer.isCompleted) {
      completer.complete(result);
    }
    notifyListeners();
  }

  /// Update subscription status
  void _updateSubscriptionStatus({
    required String productId,
    required SubscriptionStatus status,
    DateTime? expiryDate,
    String? transactionId,
  }) {
    // If upgrading from monthly to yearly, prefer the yearly subscription
    if (status == SubscriptionStatus.active &&
        productId == SubscriptionProductIds.yearly) {
      _currentSubscription = SubscriptionDetails(
        productId: productId,
        status: status,
        expiryDate: expiryDate,
        transactionId: transactionId,
      );
    } else if (status == SubscriptionStatus.active &&
        productId == SubscriptionProductIds.monthly) {
      // Only set monthly if we don't already have an active yearly subscription.
      if (!(_currentSubscription?.productId == SubscriptionProductIds.yearly &&
          _currentSubscription?.isActive == true)) {
        _currentSubscription = SubscriptionDetails(
          productId: productId,
          status: status,
          expiryDate: expiryDate,
          transactionId: transactionId,
        );
      }
    } else if (status == SubscriptionStatus.notSubscribed) {
      // Only clear subscription if it matches the product being cancelled
      if (_currentSubscription?.productId == productId) {
        _currentSubscription = null;
      }
    } else {
      _currentSubscription = SubscriptionDetails(
        productId: productId,
        status: status,
        expiryDate: expiryDate,
        transactionId: transactionId,
      );
    }

    notifyListeners();
  }

  /// Check subscription status on app launch
  Future<void> checkSubscriptionStatus() async {
    // On Android, set to not subscribed (free plan)
    if (!Platform.isIOS) {
      _updateSubscriptionStatus(
        productId: '',
        status: SubscriptionStatus.notSubscribed,
      );
      return;
    }

    final result = await restorePurchases();
    if (result == SubscriptionActionResult.noActiveSubscription) {
      _updateSubscriptionStatus(
        productId: '',
        status: SubscriptionStatus.notSubscribed,
      );
    }
  }

  /// Force refresh subscription status by restoring purchases
  /// Useful after upgrades or when subscription status might have changed
  Future<SubscriptionActionResult> refreshSubscriptionStatus() async {
    // On Android, ensure we're on free plan
    if (!Platform.isIOS) {
      _updateSubscriptionStatus(
        productId: '',
        status: SubscriptionStatus.notSubscribed,
      );
      return SubscriptionActionResult.unavailable;
    }

    // Clear current subscription temporarily to force refresh
    _currentSubscription = null;
    notifyListeners();

    // Restore purchases to get the current StoreKit entitlement.
    final result = await restorePurchases();

    // If no subscription found after restore, mark as not subscribed
    if (result == SubscriptionActionResult.noActiveSubscription) {
      _updateSubscriptionStatus(
        productId: '',
        status: SubscriptionStatus.notSubscribed,
      );
    }

    return result;
  }

  /// Stream done callback
  void _updateStreamOnDone() {
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

      await _prefs!.setInt(_dailyStoryCountKey, newCount);

      notifyListeners();
    } catch (e) {
      debugPrint('[SubscriptionService] Failed to record generated story: $e');
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
      await _prefs!.setInt(_dailyResetDateKey, _dateToYyyyMmDd(DateTime.now()));

      notifyListeners();
    } catch (e) {
      debugPrint('[SubscriptionService] Failed to reset daily story count: $e');
    }
  }

  /// Dispose the service
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
