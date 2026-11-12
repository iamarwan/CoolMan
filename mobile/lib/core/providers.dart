// App-wide providers.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'cache_store.dart';
import 'location_service.dart';
import 'session.dart';

/// Opened in main() before runApp and injected with overrideWithValue.
final cacheStoreProvider = Provider<CacheStore>(
  (ref) => throw UnimplementedError('cacheStoreProvider must be overridden'),
);

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    tokenProvider: () => ref.read(sessionProvider).token,
    // Expired or revoked login: log out so the next action asks to log in again.
    onUnauthorized: () => ref.read(sessionProvider.notifier).logout(),
  ),
);

final locationServiceProvider = Provider<LocationService>((ref) => LocationService());
