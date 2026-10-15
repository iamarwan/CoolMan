// lib/models/user_profile.dart

class UserProfile {
  final String id;
  final String username;
  final int trustScore;

  const UserProfile({
    required this.id,
    required this.username,
    required this.trustScore,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'],
        username: json['username'],
        trustScore: json['trust_score'] as int,
      );
}
