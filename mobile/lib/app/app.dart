import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/locale.dart';
import '../core/providers.dart';
import '../core/session.dart';
import '../features/home/home_shell.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../l10n/app_localizations.dart';
import 'theme.dart';

class NwasyApp extends ConsumerWidget {
  const NwasyApp({super.key, this.home});

  /// Optional override, used by tests.
  final Widget? home;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      // English + Arabic. Arabic switches the whole app to right-to-left.
      locale: ref.watch(localeProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: buildTheme(),
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
      _showOnboarding ? const OnboardingScreen() : const HomeShell();
}
