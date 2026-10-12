// lib/main.dart

import 'services/api_service.dart';
import 'package:flutter/material.dart';
import 'screens/map_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.restoreSession();
  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
  runApp(SabilApp(showOnboarding: !onboardingComplete));
}

class SabilApp extends StatelessWidget {
  final bool showOnboarding;
  const SabilApp({super.key, this.showOnboarding = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sabil',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF0F766E), // Elegant Ocean Teal
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: showOnboarding ? const OnboardingScreen() : const MapScreen(),
    );
  }
}
