// lib/screens/admin/pending_tab.dart
//
// The Pending tab: new coolers, proposed status changes and unreviewed photos, as swipeable cards.

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/water_cooler.dart';
import '../../widgets/status_style.dart';
import 'admin_common.dart';

class AdminPendingTab extends StatelessWidget {
  final bool loading;
  final List<WaterCooler> coolers;
  final void Function(WaterCooler) onApprove;
  final void Function(WaterCooler) onReject;
  final void Function(WaterCooler) onViewPhotos;

  const AdminPendingTab({super.key, 
    required this.loading,
    required this.coolers,
    required this.onApprove,
    required this.onReject,
    required this.onViewPhotos,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const AdminLoader();

    if (coolers.isEmpty) {
      return const AdminEmptyState(
        icon: Icons.check_circle_outline_rounded,
        title: 'Review Queue Clear',
        subtitle: 'All newly proposed water coolers resolved.',
      );
    }
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: AppColors.primaryTint,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: const Row(
            children: [
              Icon(Icons.swipe_rounded, size: 14, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Swipe right to approve · Swipe left to reject',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: coolers.length,
            itemBuilder: (_, i) => AdminSwipeablePendingCard(
              key: ValueKey(coolers[i].id),
              cooler: coolers[i],
              onApprove: () => onApprove(coolers[i]),
              onReject: () => onReject(coolers[i]),
              onViewPhotos: () => onViewPhotos(coolers[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class AdminSwipeablePendingCard extends StatelessWidget {
  final WaterCooler cooler;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onViewPhotos;

  const AdminSwipeablePendingCard({
    super.key,
    required this.cooler,
    required this.onApprove,
    required this.onReject,
    required this.onViewPhotos,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(cooler.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onApprove();
          return true;
        } else {
          onReject();
          return true;
        }
      },
      background: const AdminSwipeBg(
        color: AppColors.success,
        icon: Icons.check_circle_rounded,
        label: 'Approve',
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: const AdminSwipeBg(
        color: AppColors.danger,
        icon: Icons.cancel_rounded,
        label: 'Reject',
        alignment: Alignment.centerRight,
      ),
      child: AdminPendingCard(
        cooler: cooler,
        onApprove: onApprove,
        onReject: onReject,
        onViewPhotos: onViewPhotos,
      ),
    );
  }
}

class AdminSwipeBg extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final Alignment alignment;

  const AdminSwipeBg({super.key, 
    required this.color,
    required this.icon,
    required this.label,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final isLeft = alignment == Alignment.centerLeft;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: isLeft
            ? [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ]
            : [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(width: 8),
                Icon(icon, color: Colors.white, size: 24),
              ],
      ),
    );
  }
}

class AdminPendingCard extends StatelessWidget {
  final WaterCooler cooler;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onViewPhotos;

  const AdminPendingCard({super.key, 
    required this.cooler,
    required this.onApprove,
    required this.onReject,
    required this.onViewPhotos,
  });

  bool get _isStatusUpdate => cooler.pendingStatus != null;
  bool get _isNewProposal => !cooler.isApproved;

  Color get _typeColor {
    if (_isStatusUpdate) return AppColors.warning;
    if (_isNewProposal) return const Color(0xFF4F46E5);
    return AppColors.primary;
  }

  IconData get _typeIcon {
    if (_isStatusUpdate) return Icons.swap_horiz_rounded;
    if (_isNewProposal) return Icons.add_location_alt_rounded;
    return Icons.image_search_rounded;
  }

  String get _typeLabel {
    if (_isStatusUpdate) return 'Status Update Review';
    if (_isNewProposal) return 'New Location Proposal';
    return 'New Photo Submission';
  }

  @override
  Widget build(BuildContext context) {
    final verified = DateTime.tryParse(cooler.lastVerifiedAt);

    final formattedDate = verified != null
        ? '${verified.year}-${verified.month.toString().padLeft(2, '0')}-${verified.day.toString().padLeft(2, '0')} '
            '${verified.hour.toString().padLeft(2, '0')}:${verified.minute.toString().padLeft(2, '0')}'
        : cooler.lastVerifiedAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _typeColor.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Icon(_typeIcon, size: 14, color: _typeColor),
                const SizedBox(width: 8),
                Text(
                  _typeLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _typeColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cooler.name,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.slate800)),
                const SizedBox(height: 12),
                AdminMetaRow(
                  icon: Icons.location_on_outlined,
                  text:
                      'GPS: ${cooler.latitude.toStringAsFixed(6)}, ${cooler.longitude.toStringAsFixed(6)}',
                ),
                const SizedBox(height: 6),
                AdminMetaRow(
                  icon: Icons.access_time_rounded,
                  text: 'Submitted: $formattedDate',
                ),
                if (_isStatusUpdate) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      StatusPill(
                          label: cooler.status,
                          color: statusColor(cooler.status)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward_rounded,
                            size: 16, color: Colors.grey),
                      ),
                      StatusPill(
                        label: cooler.pendingStatus!,
                        color: statusColor(cooler.pendingStatus!),
                        isPending: true,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: onViewPhotos,
                  icon: const Icon(Icons.photo_library_outlined, size: 15),
                  label: Text(
                    cooler.photos.isEmpty
                        ? 'No user photos'
                        : 'View ${cooler.photos.length} item${cooler.photos.length == 1 ? '' : 's'}',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: BorderSide(
                              color: AppColors.danger.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onApprove,
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Approve'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
