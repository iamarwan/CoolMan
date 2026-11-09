// lib/main.dart
//
// Start-up rule: draw the first frame immediately. Nothing here waits on the
// network, so the app can never get stuck on a blank launch screen.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/map_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/api_service.dart';

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('FlutterError: ${details.exceptionAsString()}');
    };
    // In release builds a broken widget shows a readable message instead of a
    // grey box.
    if (kReleaseMode) {
      ErrorWidget.builder = (details) => const Material(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Something went wrong on this screen.',
                    textAlign: TextAlign.center),
              ),
            ),
          );
    }
    runApp(const SabilApp());
  }, (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
  });
}

class SabilApp extends StatelessWidget {
  const SabilApp({super.key, this.home});

  /// Optional override, used by tests.
  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sabil',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF0F766E),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: home ?? const _Bootstrap(),
    );
  }
}

/// Loads local state (onboarding flag, saved login) with short timeouts, then
/// shows the right first screen. Login validation continues in the background.
class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  late Future<bool> _showOnboarding = _load();

  Future<bool> _load() async {
    // Never let local storage hold the UI hostage.
    unawaited(ApiService.restoreSession());
    try {
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 3));
      return !(prefs.getBool('onboarding_complete') ?? false);
    } catch (e) {
      debugPrint('Could not read preferences: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _showOnboarding,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const _SplashView();
        }
        if (snap.hasError) {
          return _StartupErrorView(
            error: snap.error.toString(),
            onRetry: () => setState(() => _showOnboarding = _load()),
          );
        }
        return snap.data == true ? const OnboardingScreen() : const MapScreen();
      },
    );
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0F766E),
      body: Center(
        child: Icon(Icons.water_drop_rounded, color: Colors.white, size: 72),
      ),
    );
  }
}

class _StartupErrorView extends StatelessWidget {
  const _StartupErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 56),
              const SizedBox(height: 16),
              const Text('The app could not start.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(error, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      ),
    );
  }
}
