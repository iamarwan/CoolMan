import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error_text.dart';
import '../../core/locale.dart';
import '../../core/session.dart';
import '../../models/user.dart';
import '../../shared/ui.dart';
import 'profile_repository.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final board = ref.watch(leaderboardProvider);
    final me = ref.watch(sessionProvider).profile;
    final myRank = ref.watch(myStatsProvider).value?.rank;

    return Scaffold(
      appBar: AppBar(title: Text(l.leaderboard)),
      body: board.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(errorText(l, e)))),
        data: (entries) {
          final inList = entries.any((e) => e.username == me?.username);
          return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 28), children: [
            Text(l.topContributors, style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 12),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                for (var i = 0; i < entries.length; i++) ...[
                  if (i > 0) const Divider(indent: 64),
                  _LeaderRow(entry: entries[i], isMe: entries[i].username == me?.username),
                ],
              ]),
            ),
            if (me != null && !inList && myRank != null) ...[
              const SizedBox(height: 12),
              AppCard(
                color: AppColors.primaryContainer,
                padding: EdgeInsets.zero,
                child: _LeaderRow(
                  entry: LeaderboardEntry(rank: myRank, username: me.username, trustScore: me.trustScore),
                  isMe: true,
                ),
              ),
            ],
          ]);
        },
      ),
    );
  }
}

class _LeaderRow extends StatelessWidget {
  const _LeaderRow({required this.entry, required this.isMe});

  final LeaderboardEntry entry;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    const medals = {1: Color(0xFFD97706), 2: Color(0xFF64748B), 3: Color(0xFF9A5B13)};
    final medal = medals[entry.rank];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: medal ?? AppColors.surfaceLow,
          child: Text('${entry.rank}',
              style: TextStyle(fontWeight: FontWeight.w700, color: medal == null ? AppColors.ink : Colors.white)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            isMe ? l.you(entry.username) : entry.username,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: isMe ? FontWeight.w700 : FontWeight.w600, fontSize: 15),
          ),
        ),
        Text(l.pointsValue(entry.trustScore), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
      ]),
    );
  }
}
