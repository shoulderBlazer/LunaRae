import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/theme.dart';
import 'screens/story_generator_screen.dart';
import 'services/ad_service.dart';
import 'services/analytics_service.dart';
import 'services/crashlytics_service.dart';
import 'services/font_size_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Crashlytics
  await CrashlyticsService.initialize();
  
  // Set up global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    CrashlyticsService.recordError(
      details.exception,
      details.stack,
      fatal: true,
      information: {
        'context': 'FlutterError.onError',
        'library': details.library,
      },
    );
  };
  
  // Enable all four orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  await AdService.initialize();
  await AnalyticsService.logAppOpened();
  runApp(const LunaRaeApp());
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
        themeMode: ThemeMode.system, // Automatically adapts to system light/dark mode
        home: const StoryGeneratorScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
} 