import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class ConsentService {
  static bool _isInitialized = false;
  static bool _canRequestAds = false;
  static bool _isConsentFormLoaded = false;
  static final Completer<void> _initializationCompleter = Completer<void>();

  /// Initialize UMP SDK and request consent information
  static Future<void> initialize() async {
    if (_isInitialized || kIsWeb) return;

    debugPrint('[Consent] Initializing UMP SDK');

    // Create consent request parameters
    final params = ConsentRequestParameters();

    // Request consent information update (callback-based API)
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        debugPrint('[Consent] Consent information updated successfully');
        _isInitialized = true;

        // Check if we can request ads (consent from previous session)
        _canRequestAds = await ConsentInformation.instance.canRequestAds();
        debugPrint('[Consent] Can request ads: $_canRequestAds');

        // Load and show consent form if required
        await _loadAndShowConsentFormIfRequired();

        // Mark initialization as complete
        if (!_initializationCompleter.isCompleted) {
          _initializationCompleter.complete();
        }
      },
      (FormError error) {
        debugPrint('[Consent] Error updating consent information: ${error.message}');
        // On error, check if we can request ads from previous session
        ConsentInformation.instance.canRequestAds().then((canRequest) {
          _canRequestAds = canRequest;
          _isInitialized = true;
          debugPrint('[Consent] Can request ads after error: $_canRequestAds');

          // Mark initialization as complete even on error
          if (!_initializationCompleter.isCompleted) {
            _initializationCompleter.complete();
          }
        });
      },
    );

    // Wait for initialization to complete
    return _initializationCompleter.future;
  }

  /// Load and show consent form if required
  static Future<void> _loadAndShowConsentFormIfRequired() async {
    try {
      await ConsentForm.loadAndShowConsentFormIfRequired((loadAndShowError) {
        if (loadAndShowError != null) {
          debugPrint('[Consent] Error loading/showing consent form: ${loadAndShowError.message}');
          return;
        }

        debugPrint('[Consent] Consent form handled successfully');
        _isConsentFormLoaded = true;

        // Update canRequestAds status after consent form
        ConsentInformation.instance.canRequestAds().then((canRequest) {
          _canRequestAds = canRequest;
          debugPrint('[Consent] Can request ads after consent form: $_canRequestAds');
        });
      });
    } catch (e) {
      debugPrint('[Consent] Exception loading consent form: $e');
    }
  }

  /// Check if ads can be requested
  static bool get canRequestAds => _canRequestAds;

  /// Check if consent service is initialized
  static bool get isInitialized => _isInitialized;

  /// Check if consent form has been loaded
  static bool get isConsentFormLoaded => _isConsentFormLoaded;

  /// Reset consent status (for testing only - remove in production)
  static Future<void> resetConsent() async {
    if (kDebugMode) {
      debugPrint('[Consent] Resetting consent status');
      await ConsentInformation.instance.reset();
      _canRequestAds = false;
      _isInitialized = false;
      _isConsentFormLoaded = false;
    }
  }

  /// Check if privacy options entry point is required
  static Future<PrivacyOptionsRequirementStatus> getPrivacyOptionsRequirementStatus() async {
    try {
      return await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
    } catch (e) {
      debugPrint('[Consent] Error getting privacy options requirement: $e');
      return PrivacyOptionsRequirementStatus.notRequired;
    }
  }

  /// Show privacy options form (for users to change consent)
  static Future<void> showPrivacyOptionsForm() async {
    try {
      await ConsentForm.loadAndShowConsentFormIfRequired((error) {
        if (error != null) {
          debugPrint('[Consent] Error showing privacy options: ${error.message}');
        } else {
          debugPrint('[Consent] Privacy options form shown successfully');
          // Update canRequestAds status after privacy options change
          ConsentInformation.instance.canRequestAds().then((canRequest) {
            _canRequestAds = canRequest;
            debugPrint('[Consent] Can request ads after privacy options: $_canRequestAds');
          });
        }
      });
    } catch (e) {
      debugPrint('[Consent] Exception showing privacy options: $e');
    }
  }
}
