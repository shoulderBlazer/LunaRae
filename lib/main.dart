import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/theme.dart';
import 'screens/story_generator_screen.dart';
import 'services/ad_service.dart';
import 'services/analytics_service.dart';
import 'services/font_size_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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