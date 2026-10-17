// lib/screens/admin/sponsors_tab.dart
//
// The Sponsors tab: list of sponsors with verify / delete actions.

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/water_cooler.dart';
import '../../models/sponsor.dart';
import '../../services/api_service.dart';
import 'admin_common.dart';

class AdminSponsorsTab extends StatelessWidget {
  final bool loading;
  final List<Sponsor> sponsors;
  final ApiService api;
  final VoidCallback onRefresh;
  final void Function(String message, {bool isError}) snack;

  const AdminSponsorsTab({super.key, 
    required this.loading,
    required this.sponsors,
    required this.api,
    required this.onRefresh,
    required this.snack,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const AdminLoader();

    if (sponsors.isEmpty) {
      return const AdminEmptyState(
        icon: Icons.volunteer_activism_outlined,
        title: 'Sponsor list is empty',
        subtitle: 'Incentivize local mosques and shops, then add profiles.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: sponsors.length,
      itemBuilder: (ctx, i) {
        final sponsor = sponsors[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: AppColors.slate200)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.infoTint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.volunteer_activism_rounded, color: AppColors.info),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sponsor.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.slate800)),
                          const SizedBox(height: 4),
                          Text('${sponsor.sponsorType} · ${sponsor.coolerCount} Coolers Maintained',
                              style: const TextStyle(color: AppColors.slate500, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    if (sponsor.verified)
                      const Icon(Icons.verified_rounded, color: AppColors.success)
                  ],
                ),
                if (sponsor.contact != null) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.link, size: 14, color: AppColors.slate400),
                      const SizedBox(width: 8),
                      Text(sponsor.contact!, style: const TextStyle(color: AppColors.slate700, fontSize: 13)),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!sponsor.verified)
                      OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            await api.verifySponsor(sponsor.id);
                            snack('Sponsor profile verified.');
                            onRefresh();
                          } catch (e) {
                            snack('Verification failed: $e', isError: true);
                          }
                        },
                        icon: const Icon(Icons.verified_rounded, size: 16),
                        label: const Text('Verify'),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.success,
                            side: const BorderSide(color: AppColors.success),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          await api.deleteSponsor(sponsor.id);
                          snack('Sponsor profile deleted successfully.');
                          onRefresh();
                        } catch (e) {
                          snack('Deletion failed: $e', isError: true);
                        }
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
