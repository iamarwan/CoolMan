// lib/screens/map/cooler_sheet.dart
//
// The bottom sheet that opens when a cooler marker is tapped: status, freshness,
// cups, "Still working" and status buttons, add-photo button, sponsor badge.
// It does no server work itself; the screen passes in what each button does.

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/water_cooler.dart';
import '../../widgets/status_style.dart';
import 'cooler_info.dart';
import 'map_widgets.dart';

void showCoolerSheet(
  BuildContext context,
  WaterCooler cooler, {
  required VoidCallback onNavigate,
  required VoidCallback onConfirmWorking,
  required void Function(String newStatus) onChangeStatus,
  required VoidCallback onAddPhoto,
}) {
  final staleness = stalenessInfo(cooler.lastVerifiedAt);

  final verifiedDate = DateTime.tryParse(cooler.lastVerifiedAt);
  final now = DateTime.now().toUtc();
  final diff = verifiedDate != null ? now.difference(verifiedDate) : const Duration(hours: 1);
  final canConfirm = diff.inMinutes >= 60;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(cooler.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900, color: AppColors.slate800, letterSpacing: -0.5)),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: () => onNavigate(),
                icon: const Icon(Icons.directions_rounded),
                tooltip: 'Navigate',
                style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 18),
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
          const SizedBox(height: 24),
          if (cooler.status == 'Working') ...[
            SizedBox(
              width: double.infinity,
              child: canConfirm
                  ? FilledButton.icon(
                      onPressed: () => onConfirmWorking(),
                      icon: const Icon(Icons.verified_rounded, size: 18),
                      label: const Text('Report: Still Working'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
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
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
            ),
            const SizedBox(height: 14),
          ],
          const Text('Change reported status',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.slate600)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: StatusButton(
                  label: 'Working',
                  color: AppColors.success,
                  icon: Icons.water_drop,
                  isActive: cooler.status == 'Working',
                  // The server refuses "report the status it already has", so do nothing here.
                  onTap: cooler.status == 'Working' ? () {} : () => onChangeStatus('Working'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatusButton(
                  label: 'Empty',
                  color: AppColors.slate500,
                  icon: Icons.water_drop_outlined,
                  isActive: cooler.status == 'Empty',
                  // The server refuses "report the status it already has", so do nothing here.
                  onTap: cooler.status == 'Empty' ? () {} : () => onChangeStatus('Empty'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatusButton(
                  label: 'Broken',
                  color: AppColors.danger,
                  icon: Icons.report,
                  isActive: cooler.status == 'Broken',
                  // The server refuses "report the status it already has", so do nothing here.
                  onTap: cooler.status == 'Broken' ? () {} : () => onChangeStatus('Broken'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => onAddPhoto(),
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              label: const Text('Add Status Evidence Photo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (cooler.dedicatedTo != null) ...[
            const SizedBox(height: 14),
            DedicationCard(
                name: cooler.dedicatedTo!, message: cooler.dedicationMessage),
          ],
          if (cooler.sponsor != null) ...[
            const SizedBox(height: 18),
            SponsorBadge(sponsor: cooler.sponsor!),
          ],
        ],
      ),
    ),
  );
}
