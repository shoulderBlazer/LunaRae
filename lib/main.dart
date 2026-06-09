import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'theme/theme.dart';
import 'screens/story_generator_screen.dart';
import 'services/ad_service.dart';
import 'services/font_size_provider.dart';

import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation early (safe to block here)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Start app immediately (CRITICAL FIX for Play Store rejection)
  runApp(const LunaRaeApp());

  // Initialize non-critical services in background
  _initializeServices();
}

/// Runs non-blocking startup tasks safely
void _initializeServices() {
  // Prevent any async errors from crashing the app
  Future(() async {
    try {
      await AdService.initialize().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('AdService init timed out (continuing safely)');
        },
      );
    } catch (e) {
      debugPrint('AdService init failed: $e');
    }
  });
}

class LunaRaeApp extends StatelessWidget {
  const LunaRaeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FontSizeProvider(),
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
