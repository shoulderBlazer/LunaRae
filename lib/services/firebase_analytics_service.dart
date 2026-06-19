import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Firebase Analytics service wrapper with typed event methods.
/// All methods are guarded to ensure Firebase is initialized before use.
/// Events are queued if Firebase is not yet initialized and flushed upon initialization.
class FirebaseAnalyticsService {
  static final FirebaseAnalyticsService _instance = FirebaseAnalyticsService._internal();
  factory FirebaseAnalyticsService() => _instance;
  FirebaseAnalyticsService._internal();

  FirebaseAnalytics? _analytics;
  bool _isInitialized = false;
  bool _isFlushing = false;

  // Event queue for storing events before Firebase initialization
  final List<_QueuedEvent> _eventQueue = [];
  static const int _maxQueueSize = 50;

  /// Initialize the analytics service. Call this after Firebase.initializeApp().
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('[Analytics] Initialization already complete, skipping duplicate call');
      return;
    }
    
    debugPrint('[Analytics] Initializing Firebase Analytics');
    
    try {
      if (Firebase.apps.isNotEmpty) {
        _analytics = FirebaseAnalytics.instance;
        _isInitialized = true;
        debugPrint('[Analytics] Firebase Analytics initialized successfully');
        
        // Flush queued events after initialization
        await _flushQueue();
      } else {
        debugPrint('[Analytics] Firebase apps not ready yet, will retry on next call');
      }
    } catch (e) {
      debugPrint('[Analytics] Initialization failed: $e');
      _isInitialized = false;
    }
  }

  /// Flush all queued events to Firebase Analytics.
  /// Idempotent and thread-safe.
  Future<void> _flushQueue() async {
    if (_isFlushing || _eventQueue.isEmpty) return;
    
    _isFlushing = true;
    
    try {
      // Copy queue atomically to avoid concurrent modification
      final eventsToFlush = List<_QueuedEvent>.from(_eventQueue);
      _eventQueue.clear();
      
      debugPrint('[Analytics] Flushing ${eventsToFlush.length} queued events');
      
      // Process events in FIFO order with single retry
      for (final event in eventsToFlush) {
        bool success = false;
        
        // First attempt
        try {
          if (event.isScreenView) {
            await _analytics!.logScreenView(
              screenName: event.screenName!,
              screenClass: event.screenName!,
            );
          } else {
            await _analytics!.logEvent(
              name: event.name,
              parameters: event.parameters.cast<String, Object>(),
            );
          }
          success = true;
          debugPrint('[Analytics] Event flushed: ${event.name}');
        } catch (e) {
          debugPrint('[Analytics] First attempt failed for ${event.name}: $e');
        }
        
        // Retry once if first attempt failed
        if (!success) {
          try {
            if (event.isScreenView) {
              await _analytics!.logScreenView(
                screenName: event.screenName!,
                screenClass: event.screenName!,
              );
            } else {
              await _analytics!.logEvent(
                name: event.name,
                parameters: event.parameters.cast<String, Object>(),
              );
            }
            success = true;
            debugPrint('[Analytics] Event flushed (retry): ${event.name}');
          } catch (e) {
            debugPrint('[Analytics] Failed to send event after retry: ${event.name}');
          }
        }
      }
      
      debugPrint('[Analytics] Flush completed');
    } catch (e) {
      debugPrint('[Analytics] Error flushing queue: $e');
    } finally {
      _isFlushing = false;
    }
  }

  /// Queue an event if Firebase is not initialized.
  void _queueEvent(String name, Map<String, Object?> parameters, {bool isScreenView = false, String? screenName}) {
    if (_isInitialized) return; // Don't queue if already initialized
    
    // Drop oldest event if queue is full
    if (_eventQueue.length >= _maxQueueSize) {
      _eventQueue.removeAt(0);
      debugPrint('[Analytics] Queue full (50 events), dropped oldest event: ${_eventQueue.first.name}');
    }
    
    _eventQueue.add(_QueuedEvent(
      name: name,
      parameters: parameters,
      timestamp: DateTime.now(),
      isScreenView: isScreenView,
      screenName: screenName,
    ));
    
    debugPrint('[Analytics] Event queued: $name (queue size: ${_eventQueue.length}/$_maxQueueSize)');
  }

  /// Guard method to ensure Firebase is initialized before making Analytics calls.
  bool _ensureInitialized() {
    if (!_isInitialized) {
      initialize();
    }
    return _isInitialized;
  }

  /// Log onboarding completed event
  Future<void> logOnboardingCompleted() async {
    final parameters = {
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    if (_ensureInitialized()) {
      await _analytics!.logEvent(
        name: 'onboarding_completed',
        parameters: parameters.cast<String, Object>(),
      );
    } else {
      _queueEvent('onboarding_completed', parameters);
    }
  }

  /// Log mood selected event
  Future<void> logMoodSelected(String mood) async {
    final parameters = {
      'mood': mood,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    if (_ensureInitialized()) {
      await _analytics!.logEvent(
        name: 'mood_selected',
        parameters: parameters.cast<String, Object>(),
      );
    } else {
      _queueEvent('mood_selected', parameters);
    }
  }

  /// Log journal created event
  Future<void> logJournalCreated({int? wordCount}) async {
    final parameters = {
      'word_count': wordCount,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    if (_ensureInitialized()) {
      await _analytics!.logEvent(
        name: 'journal_created',
        parameters: parameters.cast<String, Object>(),
      );
    } else {
      _queueEvent('journal_created', parameters);
    }
  }

  /// Log affirmation viewed event
  Future<void> logAffirmationViewed(String affirmationCategory) async {
    final parameters = {
      'category': affirmationCategory,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    if (_ensureInitialized()) {
      await _analytics!.logEvent(
        name: 'affirmation_viewed',
        parameters: parameters.cast<String, Object>(),
      );
    } else {
      _queueEvent('affirmation_viewed', parameters);
    }
  }

  /// Log AI chat opened event
  Future<void> logAiChatOpened() async {
    final parameters = {
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    if (_ensureInitialized()) {
      await _analytics!.logEvent(
        name: 'ai_chat_opened',
        parameters: parameters.cast<String, Object>(),
      );
    } else {
      _queueEvent('ai_chat_opened', parameters);
    }
  }

  /// Log AI chat message sent event
  Future<void> logAiChatMessageSent({int? messageLength}) async {
    final parameters = {
      'message_length': messageLength,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    if (_ensureInitialized()) {
      await _analytics!.logEvent(
        name: 'ai_chat_message_sent',
        parameters: parameters.cast<String, Object>(),
      );
    } else {
      _queueEvent('ai_chat_message_sent', parameters);
    }
  }

  /// Log subscription started event
  Future<void> logSubscriptionStarted(String tier, String duration) async {
    final parameters = {
      'tier': tier,
      'duration': duration,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    if (_ensureInitialized()) {
      await _analytics!.logEvent(
        name: 'subscription_started',
        parameters: parameters.cast<String, Object>(),
      );
    } else {
      _queueEvent('subscription_started', parameters);
    }
  }

  /// Log subscription renewed event
  Future<void> logSubscriptionRenewed(String tier) async {
    final parameters = {
      'tier': tier,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    if (_ensureInitialized()) {
      await _analytics!.logEvent(
        name: 'subscription_renewed',
        parameters: parameters.cast<String, Object>(),
      );
    } else {
      _queueEvent('subscription_renewed', parameters);
    }
  }

  /// Log screen view event
  Future<void> logScreenView(String screenName) async {
    if (_ensureInitialized()) {
      await _analytics!.logScreenView(
        screenName: screenName,
        screenClass: screenName,
      );
      
      // Update Crashlytics custom key for current screen
      try {
        await FirebaseCrashlytics.instance.setCustomKey('current_screen', screenName);
      } catch (e) {
        // Silently fail if Crashlytics is not initialized
      }
    } else {
      _queueEvent('screen_view', {}, isScreenView: true, screenName: screenName);
    }
  }

  /// Generic log event method for custom events
  Future<void> logEvent({
    required String name,
    Map<String, Object?>? parameters,
  }) async {
    final params = parameters ?? {};
    
    debugPrint('[Analytics] logEvent called: $name with params: $params');
    
    if (_ensureInitialized()) {
      try {
        await _analytics!.logEvent(
          name: name,
          parameters: params.cast<String, Object>(),
        );
        debugPrint('[Analytics] Event sent successfully: $name');
      } catch (e) {
        debugPrint('[Analytics] Failed to send event $name: $e');
      }
    } else {
      debugPrint('[Analytics] Analytics not initialized, queuing event: $name');
      _queueEvent(name, params);
    }
  }

  /// Set user property
  Future<void> setUserProperty(String name, String? value) async {
    if (_ensureInitialized()) {
      await _analytics!.setUserProperty(name: name, value: value);
    }
    // User properties are not queued as they are stateful
  }

  /// Set user ID for analytics
  Future<void> setUserId(String? id) async {
    if (_ensureInitialized()) {
      await _analytics!.setUserId(id: id);
    }
    // User ID is not queued as it is stateful
  }

  /// Temporary method to test Crashlytics
  /// Call this to verify Crashlytics is receiving crashes
  Future<void> testCrash() async {
    try {
      FirebaseCrashlytics.instance.crash();
    } catch (e) {
      // This should never be reached as crash() terminates the app
      rethrow;
    }
  }

  /// Update subscription tier in Crashlytics
  Future<void> updateSubscriptionTier(String tier) async {
    try {
      await FirebaseCrashlytics.instance.setCustomKey('subscription_tier', tier);
    } catch (e) {
      // Silently fail if Crashlytics is not initialized
    }
  }

  /// Debug method to get current queue size for verification
  int get queueSize => _eventQueue.length;

  /// Debug method to check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Debug method to manually trigger flush (for testing)
  Future<void> debugFlush() async {
    debugPrint('[Analytics] Manual flush triggered');
    await _flushQueue();
  }
}

/// Internal class to represent a queued analytics event.
class _QueuedEvent {
  final String name;
  final Map<String, Object?> parameters;
  final DateTime timestamp;
  final bool isScreenView;
  final String? screenName;

  _QueuedEvent({
    required this.name,
    required this.parameters,
    required this.timestamp,
    this.isScreenView = false,
    this.screenName,
  });
}
