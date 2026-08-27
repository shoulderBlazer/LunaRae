import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'dart:ui';

import 'theme/theme.dart';
import 'screens/story_generator_screen.dart';
import 'services/ad_service.dart';
import 'services/ads_ready_service.dart';
import 'services/consent_service.dart';
import 'services/font_size_provider.dart';
import 'services/firebase_analytics_service.dart';
import 'services/subscription_service.dart';
import 'firebase_options.dart';

import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation early (safe to block here)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Start app immediately
  runApp(const LunaRaeApp());

  // Initialize non-critical services in background
  _initializeServices();
}

/// Runs non-blocking startup tasks safely
void _initializeServices() {
  // Prevent any async errors from crashing the app
  Future(() async {
    try {
      // Initialize Firebase in background
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Enable Analytics debug mode for development
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
      
      // Initialize Analytics
      await FirebaseAnalyticsService().initialize();

      // Test event for iOS Analytics verification - use service wrapper
      await FirebaseAnalyticsService().logEvent(
        name: 'ios_startup_test',
        parameters: {
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      debugPrint('ios_startup_test sent via service');

      // Configure Crashlytics
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(
          error,
          stack,
          fatal: true,
        );
        return true;
      };

      // Set custom Crashlytics keys
      await FirebaseCrashlytics.instance.setCustomKey('app_version', '1.0.8');
      await FirebaseCrashlytics.instance.setCustomKey('build_number', '34');
      await FirebaseCrashlytics.instance.setCustomKey('current_screen', 'story_generator');

      // Initialize UMP consent and AdService in background
      await ConsentService.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('ConsentService init timed out (continuing safely)');
        },
      );

      await AdService.initialize().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('AdService init timed out (continuing safely)');
        },
      );

      // Mark ads as ready so banner widgets can be created
      AdsReadyService.markReady();

      // Initialize subscription service
      await SubscriptionService().initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('SubscriptionService init timed out (continuing safely)');
        },
      );
    } catch (e) {
      debugPrint('Service init failed: $e');
    }
  });
}

class LunaRaeApp extends StatelessWidget {
  const LunaRaeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FontSizeProvider()),
        ChangeNotifierProvider.value(value: SubscriptionService()),
      ],
      child: MaterialApp(
        title: 'LunaRae',
        theme: LunaTheme.lightTheme(),
        darkTheme: LunaTheme.darkTheme(),
        themeMode: ThemeMode.system,
        home: const StoryGeneratorScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
