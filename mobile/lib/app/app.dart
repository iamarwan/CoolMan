import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../core/session.dart';
import '../features/map/map_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../shared/ui.dart';

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
        colorSchemeSeed: AppColors.primary,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        cardTheme: const CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            side: BorderSide(color: AppColors.line),
          ),
        ),
      ),
      home: home ?? const _Root(),
    );
  }
}

/// Picks the first screen from local state (synchronous, instant) and starts
/// restoring the saved login in the background.
class _Root extends ConsumerStatefulWidget {
  const _Root();

  @override
  ConsumerState<_Root> createState() => _RootState();
}

class _RootState extends ConsumerState<_Root> {
  late final bool _showOnboarding =
      !ref.read(cacheStoreProvider).getBool(onboardingDoneKey);

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(sessionProvider.notifier).restore());
  }

  @override
  Widget build(BuildContext context) =>
      _showOnboarding ? const OnboardingScreen() : const MapScreen();
}
