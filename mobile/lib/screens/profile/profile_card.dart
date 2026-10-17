// lib/screens/profile/profile_card.dart
//
// The big teal card at the top of the profile: avatar, trust level, points, progress bar.

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/user_profile.dart';
import '../my_submissions_screen.dart';
import 'profile_error_card.dart';
import 'trust_level.dart';

class ProfileCard extends StatelessWidget {
  final bool loading;
  final String? error;
  final UserProfile? profile;
  final VoidCallback onRetry;

  const ProfileCard({
    super.key,
    required this.loading,
    required this.error,
    required this.profile,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.slate100),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (error != null || profile == null) {
      return ProfileErrorCard(message: error ?? 'Unknown error.', onRetry: onRetry);
    }

    final data = profile!;
    final level = trustLevelFor(data.trustScore);
    final isAutoApproved = data.trustScore >= autoApproveThreshold;
    final progress = trustProgress(data.trustScore);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.teal600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
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
                    data.username.isNotEmpty
                        ? data.username[0].toUpperCase()
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
                      data.username,
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
                '${data.trustScore} pts',
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
                : '${autoApproveThreshold - data.trustScore} pts until instant auto-approvals',
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
}
