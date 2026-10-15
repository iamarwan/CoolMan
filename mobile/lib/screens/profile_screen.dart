// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'profile/leaderboard_card.dart';
import 'profile/profile_card.dart';
import '../core/theme.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.5),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
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
        color: AppColors.primary,
        onRefresh: () async {
          await Future.wait([_fetchProfile(), _fetchLeaderboard()]);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ProfileCard(
              loading: _loadingProfile,
              error: _profileError,
              profile: _profile,
              onRetry: _fetchProfile,
            ),
            const SizedBox(height: 24),
            LeaderboardCard(
              loading: _loadingLeaderboard,
              error: _leaderboardError,
              entries: _leaderboard,
              currentUsername: _profile?.username,
              onRetry: _fetchLeaderboard,
            ),
          ],
        ),
      ),
    );
  }

}
