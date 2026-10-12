// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'my_submissions_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _api = ApiService();

  UserProfile? _profile;
  List<LeaderboardEntry> _leaderboard = [];
  bool _loadingProfile = true;
  bool _loadingLeaderboard = true;
  String? _profileError;
  String? _leaderboardError;

  static const int _autoApproveThreshold = 500;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _fetchLeaderboard();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _loadingProfile = true;
      _profileError = null;
    });
    try {
      final profile = await _api.getUserProfile();
      setState(() {
        _profile = profile;
        _loadingProfile = false;
      });
    } catch (e) {
      setState(() {
        _profileError = 'Could not load profile.';
        _loadingProfile = false;
      });
    }
  }

  Future<void> _fetchLeaderboard() async {
    setState(() {
      _loadingLeaderboard = true;
      _leaderboardError = null;
    });
    try {
      final board = await _api.getLeaderboard();
      setState(() {
        _leaderboard = board;
        _loadingLeaderboard = false;
      });
    } catch (e) {
      setState(() {
        _leaderboardError = 'Could not load leaderboard.';
        _loadingLeaderboard = false;
      });
    }
  }

  Future<void> _logout() async {
    await ApiService.clearUserToken();
    if (mounted) Navigator.of(context).pop();
  }

  static _TrustLevel _trustLevel(int score) {
    if (score >= 1000) {
      return const _TrustLevel('Community Champion', '💎', Color(0xFF00BCD4));
    }
    if (score >= _autoApproveThreshold) {
      return const _TrustLevel('Verified Reporter', '🏆', Color(0xFF4CAF50));
    }
    if (score >= 250) {
      return const _TrustLevel('Trusted', '⭐', Color(0xFF2196F3));
    }
    if (score >= 100) {
      return const _TrustLevel('Contributor', '🤝', Color(0xFF9C27B0));
    }
    return const _TrustLevel('Newcomer', '🌱', Color(0xFF607D8B));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.5),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF0F766E),
        onRefresh: () async {
          await Future.wait([_fetchProfile(), _fetchLeaderboard()]);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildProfileCard(),
            const SizedBox(height: 24),
            _buildLeaderboardCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    if (_loadingProfile) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF0F766E)),
        ),
      );
    }

    if (_profileError != null || _profile == null) {
      return _ErrorCard(
          message: _profileError ?? 'Unknown error.', onRetry: _fetchProfile);
    }

    final profile = _profile!;
    final level = _trustLevel(profile.trustScore);
    final isAutoApproved = profile.trustScore >= _autoApproveThreshold;

    final milestones = [100, 250, _autoApproveThreshold, 1000];
    int nextMilestone = milestones.firstWhere(
      (m) => m > profile.trustScore,
      orElse: () => profile.trustScore + 1,
    );
    final prevMilestone = milestones
        .lastWhere((m) => m <= profile.trustScore, orElse: () => 0);
    final progress = nextMilestone == prevMilestone
        ? 1.0
        : (profile.trustScore - prevMilestone) /
            (nextMilestone - prevMilestone);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white30, width: 2),
                ),
                child: Center(
                  child: Text(
                    profile.username.isNotEmpty
                        ? profile.username[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.username,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(level.emoji,
                              style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 4),
                          Text(
                            level.label,
                            style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Trust Points Earned',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              Text(
                '${profile.trustScore} pts',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5),
              ),
            ],
          ),
          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isAutoApproved
                ? '🚀 Submissions auto-approved instantly!'
                : '${_autoApproveThreshold - profile.trustScore} pts until instant auto-approvals',
            style: TextStyle(
                fontSize: 12,
                color: Colors.teal.shade50,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const MySubmissionsScreen())),
              icon: const Icon(Icons.list_alt_rounded,
                  color: Colors.white, size: 18),
              label: const Text('My Submissions Dashboard',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                const Icon(Icons.leaderboard_rounded,
                    color: Color(0xFF0F766E), size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Community Leaderboard',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const Spacer(),
                if (_loadingLeaderboard)
                  const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F766E))),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          if (_leaderboardError != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: _ErrorCard(
                  message: _leaderboardError!,
                  onRetry: _fetchLeaderboard),
            )
          else if (!_loadingLeaderboard && _leaderboard.isEmpty)
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
              itemCount: _leaderboard.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 20, endIndent: 20, color: Color(0xFFF1F5F9)),
              itemBuilder: (_, i) {
                final entry = _leaderboard[i];
                final isMe = _profile?.username == entry.username;
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

class _TrustLevel {
  final String label;
  final String emoji;
  final Color color;

  const _TrustLevel(this.label, this.emoji, this.color);
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
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
          );

    return Container(
      color:
          isCurrentUser ? const Color(0xFF0F766E).withValues(alpha: 0.04) : null,
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
                  ? const Color(0xFFCCFBF1)
                  : const Color(0xFFF1F5F9),
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
                        ? const Color(0xFF0F766E)
                        : const Color(0xFF475569),
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
                        ? const Color(0xFF0F766E)
                        : const Color(0xFF334155),
                  ),
                ),
                if (isCurrentUser) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCFBF1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('You',
                        style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF0F766E),
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
                color: Color(0xFF0F766E)),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade300, size: 36),
          const SizedBox(height: 8),
          Text(message,
              style: TextStyle(
                  color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
