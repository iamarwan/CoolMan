// The app's frame: the map plus two more tabs, as in the Nwasy design.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/locale.dart';
import '../map/map_screen.dart';
import '../profile/my_submissions_screen.dart';
import '../profile/profile_screen.dart';

class HomeTabController extends Notifier<int> {
  @override
  int build() => 0;

  void go(int index) => state = index;
}

/// 0 = map, 1 = my reports, 2 = account.
final homeTabProvider = NotifierProvider<HomeTabController, int>(HomeTabController.new);

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final tab = ref.watch(homeTabProvider);
    return Scaffold(
      // The map stays alive behind the other tabs, so it never reloads.
      body: IndexedStack(
        index: tab,
        children: const [MapScreen(), MySubmissionsScreen(), ProfileScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: ref.read(homeTabProvider.notifier).go,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.location_on_outlined),
            selectedIcon: const Icon(Icons.location_on),
            label: l.navMap,
          ),
          NavigationDestination(
            icon: const Icon(Icons.verified_outlined),
            selectedIcon: const Icon(Icons.verified),
            label: l.navReports,
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_circle_outlined),
            selectedIcon: const Icon(Icons.account_circle),
            label: l.navAccount,
          ),
        ],
      ),
    );
  }
}
