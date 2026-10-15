// lib/screens/map/cooler_info.dart
//
// Plain functions that turn a cooler's data into words, colours and icons:
// the cups line ("Out of cup supplies") and how fresh the last check is.

import 'package:flutter/material.dart';

import '../../core/theme.dart';

IconData cupsIcon(bool? hasCups) {
  if (hasCups == null) return Icons.help_outline_rounded;
  return hasCups ? Icons.coffee_rounded : Icons.coffee_outlined;
}

Color cupsColor(bool? hasCups) {
  if (hasCups == null) return AppColors.slate500;
  return hasCups ? AppColors.success : AppColors.danger;
}

String cupsLabel(bool? hasCups, String? cupsType) {
  if (hasCups == null) return 'Unreported cups stock';
  if (!hasCups) return 'Out of cup supplies';
  if (cupsType == 'Communal') return 'Dispensing Reusable Cups';
  if (cupsType == 'Disposable') return 'Dispensing Disposable Stock';
  return 'Cups available';
}

StalenessInfo stalenessInfo(String lastVerifiedAt) {
  final verified = DateTime.tryParse(lastVerifiedAt);
  if (verified == null) return const StalenessInfo('Unknown status freshness', Colors.grey);
  final days = DateTime.now().difference(verified).inDays;
  if (days <= 3) {
    return StalenessInfo(
        days == 0 ? 'Verified today' : 'Verified $days day${days == 1 ? '' : 's'} ago',
        AppColors.success);
  }
  if (days <= 14) return StalenessInfo('Stale: $days days ago', AppColors.warning);
  if (days <= 30) return StalenessInfo('Stale: $days days ago', AppColors.danger);
  final weeks = (days / 7).floor();
  return StalenessInfo(
      '$weeks weeks ago — requires fresh verification', AppColors.danger);
}

class StalenessInfo {
  final String text;
  final Color color;
  const StalenessInfo(this.text, this.color);
}
