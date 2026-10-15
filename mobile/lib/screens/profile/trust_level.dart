// lib/screens/profile/trust_level.dart
//
// Trust levels (Newcomer ... Community Champion) and progress towards the next one.

import 'package:flutter/material.dart';

/// Score at which a user's submissions are approved instantly.
/// Keep in step with AUTO_APPROVE_THRESHOLD in backend/sabil/users/trust.py.
const int autoApproveThreshold = 500;

class TrustLevel {
  final String label;
  final String emoji;
  final Color color;

  const TrustLevel(this.label, this.emoji, this.color);
}

TrustLevel trustLevelFor(int score) {
  if (score >= 1000) {
    return const TrustLevel('Community Champion', '💎', Color(0xFF00BCD4));
  }
  if (score >= autoApproveThreshold) {
    return const TrustLevel('Verified Reporter', '🏆', Color(0xFF4CAF50));
  }
  if (score >= 250) {
    return const TrustLevel('Trusted', '⭐', Color(0xFF2196F3));
  }
  if (score >= 100) {
    return const TrustLevel('Contributor', '🤝', Color(0xFF9C27B0));
  }
  return const TrustLevel('Newcomer', '🌱', Color(0xFF607D8B));
}

/// 0.0 to 1.0: how far the score is between the previous and the next milestone.
double trustProgress(int score) {
  final milestones = [100, 250, autoApproveThreshold, 1000];
  final next = milestones.firstWhere((m) => m > score, orElse: () => score + 1);
  final previous = milestones.lastWhere((m) => m <= score, orElse: () => 0);
  if (next == previous) return 1.0;
  return ((score - previous) / (next - previous)).clamp(0.0, 1.0);
}
