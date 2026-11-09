import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error_text.dart';
import '../../core/session.dart';
import '../../models/user.dart';
import '../../shared/ui.dart';
import '../sponsors/sponsors_list_screen.dart';
import 'my_submissions_screen.dart';
import 'profile_repository.dart';

({String label, IconData icon, Color color}) trustLevel(int score) {
  if (score >= 1000) return (label: 'Community champion', icon: Icons.diamond_outlined, color: const Color(0xFF0891B2));
  if (score >= trustedThreshold) return (label: 'Verified contributor', icon: Icons.verified, color: AppColors.working);
  if (score >= 250) return (label: 'Trusted', icon: Icons.star_outline, color: AppColors.pending);
  if (score >= 100) return (label: 'Contributor', icon: Icons.handshake_outlined, color: AppColors.sponsor);
  return (label: 'Newcomer', icon: Icons.eco_outlined, color: AppColors.muted);
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final profile = session.profile;
    final stats = ref.watch(myStatsProvider);
    final board = ref.watch(leaderboardProvider);

    Future<void> refresh() async {
      ref.invalidate(myStatsProvider);
      ref.invalidate(leaderboardProvider);
      await ref.read(sessionProvider.notifier).refreshProfile();
    }

    final score = stats.value?.trustScore ?? profile?.trustScore ?? 0;
    final level = trustLevel(score);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Profile')),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: level.color.withValues(alpha: 0.15),
                    child: Icon(level.icon, color: level.color, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(profile?.username ?? '…',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                      Text(level.label, style: TextStyle(color: level.color, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  Text('$score',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900, color: AppColors.primary)),
                  const Text(' pts', style: TextStyle(color: AppColors.muted)),
                ]),
                const SizedBox(height: 16),
                if (score < trustedThreshold) ...[
                  LinearProgressIndicator(
                    value: score / trustedThreshold,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${trustedThreshold - score} points until your additions go live instantly',
                    style: const TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ] else
                  const Text('Your additions and reports go live instantly.',
                      style: TextStyle(color: AppColors.working, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          stats.when(
            data: (s) => Row(children: [
              _Stat(value: s.coolersApproved, label: 'Coolers added'),
              _Stat(value: s.confirmations, label: 'Confirmations'),
              _Stat(value: s.photos, label: 'Photos'),
            ]),
            loading: () => const SizedBox(height: 72),
            error: (e, _) => Text(errorText(e), style: const TextStyle(color: AppColors.muted)),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: const Text('My submissions'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const MySubmissionsScreen())),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.volunteer_activism_outlined),
                title: const Text('Sponsors'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const SponsorsListScreen())),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.broken),
                title: const Text('Log out', style: TextStyle(color: AppColors.broken)),
                onTap: () async {
                  await ref.read(sessionProvider.notifier).logout();
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
            ]),
          ),
          const SizedBox(height: 20),
          Text('Top contributors',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          board.when(
            data: (entries) => Card(
              child: Column(children: [
                for (final e in entries) _LeaderRow(entry: e, isMe: e.username == profile?.username),
              ]),
            ),
            loading: () => const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            )),
            error: (e, _) => Text(errorText(e), style: const TextStyle(color: AppColors.muted)),
          ),
        ]),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(children: [
              Text('$value',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            ]),
          ),
        ),
      );
}

class _LeaderRow extends StatelessWidget {
  const _LeaderRow({required this.entry, required this.isMe});

  final LeaderboardEntry entry;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    const medals = {1: Color(0xFFF59E0B), 2: Color(0xFF94A3B8), 3: Color(0xFFB45309)};
    return ListTile(
      tileColor: isMe ? AppColors.primary.withValues(alpha: 0.08) : null,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: medals[entry.rank] ?? AppColors.line,
        child: Text('${entry.rank}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: medals.containsKey(entry.rank) ? Colors.white : AppColors.ink,
            )),
      ),
      title: Text(isMe ? '${entry.username} (you)' : entry.username),
      trailing: Text('${entry.trustScore} pts', style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}
