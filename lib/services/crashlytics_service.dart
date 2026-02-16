import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashlyticsService {
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  static Future<void> initialize() async {
    await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
  }

  static Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    bool fatal = false,
    Map<String, dynamic>? information,
  }) async {
    await _crashlytics.recordError(
      exception,
      stack,
      fatal: fatal,
      information: information?.entries.map((e) => MapEntry(e.key, e.value.toString())).toList() ?? [],
    );
  }

  static Future<void> log(String message) async {
    await _crashlytics.log(message);
  }

  static Future<void> setUserIdentifier(String identifier) async {
    await _crashlytics.setUserIdentifier(identifier);
  }

  static Future<void> setCustomKey(String key, String value) async {
    await _crashlytics.setCustomKey(key, value);
  }

  static Future<void> testCrash() async {
    if (kDebugMode) {
      await _crashlytics.recordError(
        'Test crash from CrashlyticsService',
        StackTrace.current,
        fatal: false,
        information: [
          MapEntry('test', true),
          MapEntry('timestamp', DateTime.now().toIso8601String()),
        ],
      );
    }
  }

  static Future<void> forceCrash() async {
    if (kDebugMode) {
      throw Exception('Test fatal crash - this should appear in Crashlytics');
    }
  }
}
