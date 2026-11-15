// Nwasy design system (from the Stitch export, nwasy/DESIGN.md).
// Every colour in the app comes from AppColors; change the palette here.

import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/locale.dart';
import '../l10n/app_localizations.dart';
import '../models/cooler.dart';

class AppColors {
  // Brand
  static const primary = Color(0xFF0F766E);
  static const primaryDark = Color(0xFF005C55);
  static const primaryContainer = Color(0xFFCCFBF1);
  // Surfaces
  static const background = Color(0xFFF9F9FF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceLow = Color(0xFFF0F3FF); // quiet buttons, tiles
  static const surfaceTint = Color(0xFFDEE8FF);
  static const line = Color(0xFFE2E8F0);
  // Text
  static const ink = Color(0xFF111C2D);
  static const muted = Color(0xFF64748B);
  // Status (always shown with an icon and a label, never colour alone)
  static const working = Color(0xFF059669);
  static const workingBg = Color(0xFFECFDF5);
  static const empty = Color(0xFFD97706);
  static const emptyBg = Color(0xFFFFFBEB);
  static const broken = Color(0xFFDC2626);
  static const brokenBg = Color(0xFFFEF2F2);
  static const pending = Color(0xFF2563EB);
  static const pendingBg = Color(0xFFEFF6FF);
  static const patron = Color(0xFF7C3AED);
  static const patronBg = Color(0xFFF5F3FF);

  // Kept for older call sites.
  static const sponsor = patron;
}

class AppRadius {
  static const button = 12.0;
  static const card = 16.0;
  static const sheet = 24.0;
}

/// Tight, low shadow that stays readable in sunlight.
const cardShadow = [
  BoxShadow(color: Color(0x0F0F172A), blurRadius: 4, offset: Offset(0, 2)),
  BoxShadow(color: Color(0x0A0F172A), blurRadius: 2, offset: Offset(0, 1)),
];

extension CoolerStatusStyle on CoolerStatus {
  Color get color => switch (this) {
        CoolerStatus.working => AppColors.working,
        CoolerStatus.empty => AppColors.empty,
        CoolerStatus.broken => AppColors.broken,
      };

  Color get background => switch (this) {
        CoolerStatus.working => AppColors.workingBg,
        CoolerStatus.empty => AppColors.emptyBg,
        CoolerStatus.broken => AppColors.brokenBg,
      };

  IconData get icon => switch (this) {
        CoolerStatus.working => Icons.water_drop,
        CoolerStatus.empty => Icons.hourglass_empty_rounded,
        CoolerStatus.broken => Icons.build_rounded,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
    ));
}

/// Small rounded label: a dot or icon plus text on a tinted background.
class Pill extends StatelessWidget {
  const Pill({super.key, required this.text, required this.color, required this.background, this.icon});

  final String text;
  final Color color;
  final Color background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null)
          Icon(icon, size: 14, color: color)
        else
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12, height: 1.35),
          ),
        ),
      ]),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.pending = false});

  final CoolerStatus status;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (pending) {
      return Pill(
        text: l.statusPendingReview(status.label(l)),
        color: AppColors.pending,
        background: AppColors.pendingBg,
        icon: Icons.schedule,
      );
    }
    return Pill(text: status.label(l), color: status.color, background: status.background);
  }
}

/// Drag handle shown at the top of bottom sheets.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 44,
          height: 5,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceTint,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      );
}

/// White card with a hairline border and the standard low shadow.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.color});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.line),
          boxShadow: color == null ? cardShadow : null,
        ),
        child: child,
      );
}

/// Quiet, tinted button used for secondary actions.
class TintButton extends StatelessWidget {
  const TintButton({super.key, required this.label, required this.icon, this.onPressed, this.iconColor});

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: AppColors.surfaceLow,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 18, color: enabled ? (iconColor ?? AppColors.ink) : AppColors.muted),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    height: 1.25,
                    color: enabled ? AppColors.ink : AppColors.muted,
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Uppercase section label ("MY ACTIVITY").
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.only(start: 4, top: 8, bottom: 8),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: AppColors.muted,
          ),
        ),
      );
}

/// Rounded-square icon badge used at the start of list rows and cards.
class IconBadge extends StatelessWidget {
  const IconBadge(this.icon, {super.key, this.color = AppColors.primary, this.background = AppColors.surfaceLow, this.size = 40});

  final IconData icon;
  final Color color;
  final Color background;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(size * 0.28)),
        child: Icon(icon, color: color, size: size * 0.52),
      );
}
