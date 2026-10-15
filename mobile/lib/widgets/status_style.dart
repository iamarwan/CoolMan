// lib/widgets/status_style.dart
//
// How a cooler's status (Working / Empty / Broken) looks: its colour, its icon,
// and the little rounded "pill" label. Written once and used by every screen.

import 'package:flutter/material.dart';

import '../core/theme.dart';

Color statusColor(String status) => switch (status) {
      'Working' => AppColors.success,
      'Empty' => AppColors.slate500,
      'Broken' => AppColors.danger,
      _ => Colors.blue,
    };

IconData statusIcon(String status) => switch (status) {
      'Working' => Icons.water_drop,
      'Empty' => Icons.water_drop_outlined,
      'Broken' => Icons.report,
      _ => Icons.help_outline,
    };

/// A small rounded label, e.g. "Working". [isPending] draws it bolder to show
/// a change that is still waiting for an admin.
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool isPending;

  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.isPending = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isPending ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: isPending ? 0.6 : 0.3),
          width: isPending ? 1.5 : 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
