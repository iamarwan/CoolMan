// lib/models/leaderboard_entry.dart

class LeaderboardEntry {
  final int rank;
  final String username;
  final int trustScore;

  const LeaderboardEntry({
    required this.rank,
    required this.username,
    required this.trustScore,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntry(
        rank: json['rank'] as int,
        username: json['username'],
        trustScore: json['trust_score'] as int,
      );
}
