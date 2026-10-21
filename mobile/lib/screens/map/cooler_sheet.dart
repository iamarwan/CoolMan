// lib/screens/map/cooler_sheet.dart
//
// The sheet that opens when a cooler marker is tapped. It is draggable:
//   first view   the cooler's photos, its name and the Navigate button
//   slide up     status, freshness, cups, "Still working", the "Update condition"
//                menu, add-photo, dedication, sponsor
// It does no server work itself; the screen passes in what each button does.
// Results are shown in a banner INSIDE the sheet (a normal snackbar would appear
// behind it, out of sight).

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/cooler_photo.dart';
import '../../models/water_cooler.dart';
import '../../services/api_client.dart';
import '../../widgets/status_style.dart';
import 'cooler_info.dart';
import 'cooler_photo_strip.dart';
import 'map_widgets.dart';

/// A message for the banner inside the sheet. An action returns one to show it,
/// or null when it handled everything itself (e.g. it closed the sheet).
class SheetNotice {
  final String message;
  final bool isError;
  const SheetNotice(this.message, {this.isError = false});
}

typedef SheetAction = Future<SheetNotice?> Function();

void showCoolerSheet(
  BuildContext context,
  WaterCooler cooler, {
  required Future<List<CoolerPhoto>> Function() loadPhotos,
  required VoidCallback onNavigate,
  required SheetAction onConfirmWorking,
  required Future<SheetNotice?> Function(String newStatus) onChangeStatus,
  required SheetAction onAddPhoto,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.46,
      minChildSize: 0.3,
      maxChildSize: 0.92,
      builder: (context, scrollController) => _CoolerSheetBody(
        cooler: cooler,
        scrollController: scrollController,
        loadPhotos: loadPhotos,
        onNavigate: onNavigate,
        onConfirmWorking: onConfirmWorking,
        onChangeStatus: onChangeStatus,
        onAddPhoto: onAddPhoto,
      ),
    ),
  );
}

class _CoolerSheetBody extends StatefulWidget {
  final WaterCooler cooler;
  final ScrollController scrollController;
  final Future<List<CoolerPhoto>> Function() loadPhotos;
  final VoidCallback onNavigate;
  final SheetAction onConfirmWorking;
  final Future<SheetNotice?> Function(String newStatus) onChangeStatus;
  final SheetAction onAddPhoto;

  const _CoolerSheetBody({
    required this.cooler,
    required this.scrollController,
    required this.loadPhotos,
    required this.onNavigate,
    required this.onConfirmWorking,
    required this.onChangeStatus,
    required this.onAddPhoto,
  });

  @override
  State<_CoolerSheetBody> createState() => _CoolerSheetBodyState();
}

class _CoolerSheetBodyState extends State<_CoolerSheetBody> {
  SheetNotice? _notice;
  bool _busy = false;

  /// Runs one button's action: blocks double taps while it runs, then shows the
  /// result in the banner (unless the action closed the sheet).
  Future<void> _run(SheetAction action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _notice = null;
    });
    SheetNotice? result;
    try {
      result = await action();
    } catch (e) {
      result = SheetNotice(friendlyError(e, 'Something went wrong. Please try again.'),
          isError: true);
    }
    if (!mounted) return; // the action closed the sheet
    setState(() {
      _busy = false;
      _notice = result;
    });
    if (result != null && widget.scrollController.hasClients) {
      widget.scrollController.animateTo(0,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cooler = widget.cooler;
    final staleness = stalenessInfo(cooler.lastVerifiedAt);

    final verifiedDate = DateTime.tryParse(cooler.lastVerifiedAt);
    final now = DateTime.now().toUtc();
    final diff = verifiedDate != null ? now.difference(verifiedDate) : const Duration(hours: 1);
    final canConfirm = diff.inMinutes >= 60;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 14),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(minHeight: 3),
            ),
          if (_notice != null) _NoticeBanner(notice: _notice!),
          CoolerPhotoStrip(
            load: widget.loadPhotos,
            onAddPhoto: () => _run(widget.onAddPhoto),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(cooler.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.slate800,
                        letterSpacing: -0.5)),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: () => widget.onNavigate(),
                icon: const Icon(Icons.directions_rounded),
                tooltip: 'Navigate',
                style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              Icon(Icons.keyboard_arrow_up_rounded, size: 18, color: AppColors.slate400),
              SizedBox(width: 4),
              Text('Slide up for status and more',
                  style: TextStyle(fontSize: 12, color: AppColors.slate400)),
            ],
          ),
          const SizedBox(height: 22),
          InfoRow(
            icon: statusIcon(cooler.status),
            iconColor: statusColor(cooler.status),
            label: 'Operational Status',
            value: cooler.status,
          ),
          const SizedBox(height: 10),
          InfoRow(
            icon: Icons.verified_user_outlined,
            iconColor: staleness.color,
            label: 'Verified Freshness',
            value: staleness.text,
          ),
          const SizedBox(height: 10),
          InfoRow(
            icon: cupsIcon(cooler.hasCups),
            iconColor: cupsColor(cooler.hasCups),
            label: 'Cup Supplies',
            value: cupsLabel(cooler.hasCups, cooler.cupsType),
          ),
          const SizedBox(height: 22),
          if (cooler.status == 'Working') ...[
            SizedBox(
              width: double.infinity,
              child: canConfirm
                  ? FilledButton.icon(
                      onPressed: _busy ? null : () => _run(widget.onConfirmWorking),
                      icon: const Icon(Icons.verified_rounded, size: 18),
                      label: const Text('Confirm: Still Working'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    )
                  : FilledButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.timer_outlined, size: 18),
                      label: Text('Verified (${60 - diff.inMinutes}m left for point reward)'),
                      style: FilledButton.styleFrom(
                        disabledBackgroundColor: AppColors.slate100,
                        disabledForegroundColor: AppColors.slate400,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
            ),
            const SizedBox(height: 12),
          ],
          _ConditionMenu(
            current: cooler.status,
            enabled: !_busy,
            onSelected: (status) => _run(() => widget.onChangeStatus(status)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : () => _run(widget.onAddPhoto),
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              label: const Text('Add Status Evidence Photo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (cooler.dedicatedTo != null) ...[
            const SizedBox(height: 14),
            DedicationCard(name: cooler.dedicatedTo!, message: cooler.dedicationMessage),
          ],
          if (cooler.sponsor != null) ...[
            const SizedBox(height: 18),
            SponsorBadge(sponsor: cooler.sponsor!),
          ],
        ],
      ),
    );
  }
}

/// The result banner at the top of the sheet (green for success, red for a problem).
class _NoticeBanner extends StatelessWidget {
  final SheetNotice notice;
  const _NoticeBanner({required this.notice});

  @override
  Widget build(BuildContext context) {
    final color = notice.isError ? AppColors.danger : AppColors.success;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(notice.isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(notice.message,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.slate800)),
          ),
        ],
      ),
    );
  }
}

/// One button that opens a menu: Working / Empty / Broken. The cooler's current
/// condition is highlighted with a tick and cannot be picked again (the server
/// refuses a report that repeats the current status anyway).
class _ConditionMenu extends StatelessWidget {
  final String current;
  final bool enabled;
  final void Function(String newStatus) onSelected;

  const _ConditionMenu(
      {required this.current, required this.enabled, required this.onSelected});

  static const _options = ['Working', 'Empty', 'Broken'];

  PopupMenuEntry<String> _item(String status) {
    final isCurrent = status == current;
    final color = statusColor(status);
    return PopupMenuItem<String>(
      value: status,
      enabled: !isCurrent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isCurrent ? color.withValues(alpha: 0.14) : null,
          borderRadius: BorderRadius.circular(10),
          border: isCurrent ? Border.all(color: color, width: 1.5) : null,
        ),
        child: Row(
          children: [
            Icon(statusIcon(status), color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(status,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            if (isCurrent) ...[
              Text('Current',
                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Icon(Icons.check_circle_rounded, color: color, size: 18),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Update condition',
      enabled: enabled,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: onSelected,
      itemBuilder: (_) => [for (final s in _options) _item(s)],
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primaryTint,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_note_rounded, size: 20, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Update condition',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
            SizedBox(width: 4),
            Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
