class UserProfile {
  const UserProfile({required this.id, required this.username, required this.trustScore});

  final String id;
  final String username;
  final int trustScore;

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        id: j['id'] as String,
        username: j['username'] as String,
        trustScore: j['trust_score'] as int? ?? 0,
      );

  UserProfile withScore(int score) => UserProfile(id: id, username: username, trustScore: score);
}

class LeaderboardEntry {
  const LeaderboardEntry({required this.rank, required this.username, required this.trustScore});

  final int rank;
  final String username;
  final int trustScore;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(
        rank: j['rank'] as int,
        username: j['username'] as String,
        trustScore: j['trust_score'] as int? ?? 0,
      );
}

class UserStats {
  const UserStats({
    required this.trustScore,
    required this.trustedThreshold,
    required this.coolersAdded,
    required this.coolersApproved,
    required this.confirmations,
    required this.photos,
    this.rank,
  });

  final int trustScore;
  final int trustedThreshold;
  final int coolersAdded;
  final int coolersApproved;
  final int confirmations;
  final int photos;
  final int? rank;

  factory UserStats.fromJson(Map<String, dynamic> j) => UserStats(
        trustScore: j['trust_score'] as int? ?? 0,
        trustedThreshold: j['trusted_threshold'] as int? ?? 500,
        coolersAdded: j['coolers_added'] as int? ?? 0,
        coolersApproved: j['coolers_approved'] as int? ?? 0,
        confirmations: j['confirmations'] as int? ?? 0,
        photos: j['photos'] as int? ?? 0,
        rank: j['rank'] as int?,
      );
}
