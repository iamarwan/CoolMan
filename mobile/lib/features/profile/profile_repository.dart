import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../models/cooler.dart';
import '../../models/user.dart';
import '../cooler/cooler_repository.dart';

final myStatsProvider = FutureProvider.autoDispose<UserStats>((ref) async {
  final json = await ref.watch(apiClientProvider).get('/users/me/stats');
  return UserStats.fromJson(json as Map<String, dynamic>);
});

final leaderboardProvider = FutureProvider.autoDispose<List<LeaderboardEntry>>((ref) async {
  final list = await ref.watch(apiClientProvider).get('/users/leaderboard') as List;
  return [for (final e in list) LeaderboardEntry.fromJson(e as Map<String, dynamic>)];
});

final mySubmissionsProvider = FutureProvider.autoDispose<List<Cooler>>(
  (ref) => ref.watch(coolerRepositoryProvider).mine(),
);

final sponsorsProvider = FutureProvider.autoDispose<List<Sponsor>>(
  (ref) => ref.watch(coolerRepositoryProvider).sponsors(),
);
