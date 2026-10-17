// lib/screens/admin/current_tab.dart
//
// The Live tab: approved coolers with force-status, photo and sponsor actions.

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/water_cooler.dart';
import '../../widgets/status_style.dart';
import 'admin_common.dart';

class AdminCurrentTab extends StatelessWidget {
  final bool loading;
  final List<WaterCooler> coolers;
  final void Function(WaterCooler) onDelete;
  final void Function(WaterCooler, String) onForceStatus;
  final void Function(WaterCooler) onAddPhoto;
  final void Function(WaterCooler) onViewPhotos;
  final void Function(WaterCooler) onManageSponsor;
  final void Function(WaterCooler) onDedicate;

  const AdminCurrentTab({super.key, 
    required this.loading,
    required this.coolers,
    required this.onDelete,
    required this.onForceStatus,
    required this.onAddPhoto,
    required this.onViewPhotos,
    required this.onManageSponsor,
    required this.onDedicate,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const AdminLoader();

    if (coolers.isEmpty) {
      return const AdminEmptyState(
        icon: Icons.water_drop_outlined,
        title: 'Map Index empty',
        subtitle: 'Once approved, coolers will populate here.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: coolers.length,
      itemBuilder: (_, i) => AdminLiveCard(
        cooler: coolers[i],
        onDelete: () => onDelete(coolers[i]),
        onForceStatus: (s) => onForceStatus(coolers[i], s),
        onAddPhoto: () => onAddPhoto(coolers[i]),
        onViewPhotos: () => onViewPhotos(coolers[i]),
        onManageSponsor: () => onManageSponsor(coolers[i]),
        onDedicate: () => onDedicate(coolers[i]),
      ),
    );
  }
}

class AdminLiveCard extends StatelessWidget {
  final WaterCooler cooler;
  final VoidCallback onDelete;
  final void Function(String) onForceStatus;
  final VoidCallback onAddPhoto;
  final VoidCallback onViewPhotos;
  final VoidCallback onManageSponsor;
  final VoidCallback onDedicate;

  const AdminLiveCard({super.key, 
    required this.cooler,
    required this.onDelete,
    required this.onForceStatus,
    required this.onAddPhoto,
    required this.onViewPhotos,
    required this.onManageSponsor,
    required this.onDedicate,
  });

  @override
  Widget build(BuildContext context) {
    final color = statusColor(cooler.status);
    final verified = DateTime.tryParse(cooler.lastVerifiedAt);

    final formattedDate = verified != null
        ? '${verified.year}-${verified.month.toString().padLeft(2, '0')}-${verified.day.toString().padLeft(2, '0')}'
        : cooler.lastVerifiedAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: AppColors.slate200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(statusIcon(cooler.status), color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cooler.name,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.slate800),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                              child:
                                  StatusPill(label: cooler.status, color: color)),
                          const SizedBox(width: 8),
                          const Icon(Icons.calendar_today_outlined,
                              size: 11, color: AppColors.slate400),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              formattedDate,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.slate500),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: onAddPhoto,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  color: AppColors.info,
                  tooltip: 'Admin Add Photo',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.infoTint,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                IconButton(
                  onPressed: onViewPhotos,
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.photo_library_outlined),
                      if (cooler.photos.isNotEmpty)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                                color: AppColors.primary, shape: BoxShape.circle),
                            child: Text(
                              '${cooler.photos.length}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                  color: AppColors.primary,
                  tooltip: 'Inspect Gallery',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primaryTint,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: AppColors.danger,
                  tooltip: 'Spam cleanup',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.dangerTint,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded,
                      color: AppColors.slate400),
                  tooltip: 'Audit status options',
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  onSelected: (value) {
                    if (value == '__sponsor__') {
                      onManageSponsor();
                    } else if (value == '__dedicate__') {
                      onDedicate();
                    } else {
                      onForceStatus(value);
                    }
                  },
                  itemBuilder: (_) => [
                    _forceMenuItem('Working', AppColors.success, Icons.water_drop),
                    _forceMenuItem(
                        'Empty', AppColors.slate500, Icons.water_drop_outlined),
                    _forceMenuItem('Broken', AppColors.danger, Icons.report),
                    const PopupMenuDivider(),
                    PopupMenuItem<String>(
                      value: '__sponsor__',
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryTint,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                                Icons.volunteer_activism_outlined,
                                color: AppColors.primary,
                                size: 16),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            cooler.sponsor != null
                                ? 'Edit sponsor mapping'
                                : 'Map Sponsor',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: '__dedicate__',
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryTint,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.favorite_border_rounded,
                                color: AppColors.primary, size: 16),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            cooler.dedicatedTo != null
                                ? 'Edit dedication'
                                : 'In memory of…',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (cooler.dedicatedTo != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.favorite_rounded,
                        color: AppColors.primary, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'In memory of ${cooler.dedicatedTo}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (cooler.sponsor != null) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.successTint,
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: AppColors.successBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.volunteer_activism_rounded,
                        color: AppColors.successDark, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Sponsored Sadie: ${cooler.sponsor!.name}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.successDark,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (cooler.sponsor!.verified)
                      const Icon(Icons.verified_rounded,
                          size: 14, color: AppColors.successDark),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _forceMenuItem(
      String status, Color color, IconData icon) {
    return PopupMenuItem<String>(
      value: status,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Text('Verify $status',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color, fontSize: 13)),
        ],
      ),
    );
  }
}
