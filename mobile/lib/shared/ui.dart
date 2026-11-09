// Shared look: colours, status styling, snackbars. Replaced by the brand
// theme in Phase 6.

import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/locale.dart';
import '../l10n/app_localizations.dart';
import '../models/cooler.dart';

class AppColors {
  static const primary = Color(0xFF0F766E);
  static const working = Color(0xFF059669);
  static const empty = Color(0xFFD97706);
  static const broken = Color(0xFFDC2626);
  static const pending = Color(0xFF2563EB);
  static const sponsor = Color(0xFF7C3AED);
  static const ink = Color(0xFF1E293B);
  static const muted = Color(0xFF64748B);
  static const surface = Color(0xFFF8FAFC);
  static const line = Color(0xFFE2E8F0);
}

extension CoolerStatusStyle on CoolerStatus {
  Color get color => switch (this) {
        CoolerStatus.working => AppColors.working,
        CoolerStatus.empty => AppColors.empty,
        CoolerStatus.broken => AppColors.broken,
      };

  IconData get icon => switch (this) {
        CoolerStatus.working => Icons.water_drop,
        CoolerStatus.empty => Icons.water_drop_outlined,
        CoolerStatus.broken => Icons.build_circle,
      };

  String label(AppLocalizations l) => switch (this) {
        CoolerStatus.working => l.statusWorking,
        CoolerStatus.empty => l.statusEmpty,
        CoolerStatus.broken => l.statusBroken,
      };

  String reportLabel(AppLocalizations l) => switch (this) {
        CoolerStatus.working => l.reportWorking,
        CoolerStatus.empty => l.reportEmpty,
        CoolerStatus.broken => l.reportBroken,
      };
}

extension FreshnessStyle on Freshness {
  Color get color => switch (this) {
        Freshness.fresh => AppColors.working,
        Freshness.aging => AppColors.empty,
        Freshness.stale => AppColors.broken,
      };
}

String cupsLabel(AppLocalizations l, bool? hasCups, CupsType? type) {
  if (hasCups == null) return l.cupsUnknown;
  if (!hasCups) return l.cupsNone;
  return switch (type) {
    CupsType.communal => l.cupsShared,
    CupsType.disposable => l.cupsDisposable,
    null => l.cupsAvailable,
  };
}

void showSnack(BuildContext context, String message, {bool error = false}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? AppColors.broken : AppColors.ink,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.pending = false});

  final CoolerStatus status;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final color = pending ? AppColors.pending : status.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(pending ? Icons.hourglass_top : status.icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          pending
              ? context.l10n.statusPendingReview(status.label(context.l10n))
              : status.label(context.l10n),
          style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ]),
    );
  }
}

/// Drag handle shown at the top of bottom sheets.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.line,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
}
