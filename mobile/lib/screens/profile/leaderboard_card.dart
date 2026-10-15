// lib/screens/profile/leaderboard_card.dart
//
// The Community Leaderboard card and its rows.

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../services/api_service.dart';
import 'profile_error_card.dart';

class LeaderboardCard extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<LeaderboardEntry> entries;
  final String? currentUsername;
  final VoidCallback onRetry;

  const LeaderboardCard({
    super.key,
    required this.loading,
    required this.error,
    required this.entries,
    required this.currentUsername,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.slate100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                const Icon(Icons.leaderboard_rounded,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Community Leaderboard',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.slate800),
                ),
                const Spacer(),
                if (loading)
                  const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.slate100),
          if (error != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: ProfileErrorCard(
                  message: error!,
                  onRetry: onRetry),
            )
          else if (!loading && entries.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                  child: Text('No participants recorded.',
                      style: TextStyle(color: Colors.grey))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 20, endIndent: 20, color: AppColors.slate100),
              itemBuilder: (_, i) {
                final entry = entries[i];
                final isMe = currentUsername == entry.username;
                return _LeaderboardRow(
                    entry: entry, isCurrentUser: isMe);
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isCurrentUser;

  const _LeaderboardRow(
      {required this.entry, required this.isCurrentUser});

  String _rankEmoji(int rank) => switch (rank) {
        1 => '🥇',
        2 => '🥈',
        3 => '🥉',
        _ => '#$rank',
      };

  @override
  Widget build(BuildContext context) {
    final rankWidget = entry.rank <= 3
        ? Text(_rankEmoji(entry.rank), style: const TextStyle(fontSize: 22))
        : Text(
            '#${entry.rank}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.slate400),
          );

    return Container(
      color:
          isCurrentUser ? AppColors.primary.withValues(alpha: 0.04) : null,
      padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Align(
              alignment: Alignment.center,
              child: rankWidget,
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? AppColors.teal100
                  : AppColors.slate100,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                entry.username.isNotEmpty
                    ? entry.username[0].toUpperCase()
                    : '?',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCurrentUser
                        ? AppColors.primary
                        : AppColors.slate600,
                    fontSize: 15),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Row(
              children: [
                Text(
                  entry.username,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isCurrentUser
                        ? AppColors.primary
                        : AppColors.slate700,
                  ),
                ),
                if (isCurrentUser) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.teal100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('You',
                        style: TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '${entry.trustScore} pts',
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
