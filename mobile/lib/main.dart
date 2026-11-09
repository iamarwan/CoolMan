// Start-up rule: nothing here waits on the network. The only await is local
// storage (bounded to 3 s), during which Android shows the native splash.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/cache_store.dart';
import 'core/providers.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('FlutterError: ${details.exceptionAsString()}');
    };
    if (kReleaseMode) {
      // A broken widget shows a readable message instead of a grey box.
      ErrorWidget.builder = (_) => const Material(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Something went wrong on this screen.', textAlign: TextAlign.center),
              ),
            ),
          );
    }

    final cache = await CacheStore.open();
    runApp(ProviderScope(
      overrides: [cacheStoreProvider.overrideWithValue(cache)],
      // Network errors are shown to the user with a retry button instead of
      // silently retrying in the background.
      retry: (_, _) => null,
      child: const SabilApp(),
    ));
  }, (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
  });
}
