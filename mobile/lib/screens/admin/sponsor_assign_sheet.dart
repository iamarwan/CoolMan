// lib/screens/admin/sponsor_assign_sheet.dart
//
// Bottom sheet to attach (or remove) a sponsor on a cooler.

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/water_cooler.dart';
import '../../models/sponsor.dart';
import '../../services/api_service.dart';

class AdminSponsorAssignSheet extends StatefulWidget {
  final WaterCooler cooler;
  final ApiService api;
  final List<Sponsor> sponsors;
  final VoidCallback onAssigned;
  final VoidCallback onRemoved;

  const AdminSponsorAssignSheet({super.key, 
    required this.cooler,
    required this.api,
    required this.sponsors,
    required this.onAssigned,
    required this.onRemoved,
  });

  @override
  State<AdminSponsorAssignSheet> createState() => _AdminSponsorAssignSheetState();
}

class _AdminSponsorAssignSheetState extends State<AdminSponsorAssignSheet> {
  bool _loading = false;
  String? _error;

  Future<void> _removeSponsor() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await widget.api.removeSponsor(widget.cooler.id);
      widget.onRemoved();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to remove sponsor association.';
      });
    }
  }

  Future<void> _assign(String id) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.api.assignSponsor(coolerId: widget.cooler.id, sponsorId: id);
      widget.onAssigned();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'Failed to assign sponsor.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sponsor = widget.cooler.sponsor;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                const Icon(Icons.volunteer_activism_outlined,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sponsor != null
                        ? 'Manage sponsor association'
                        : 'Assign sponsor',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.slate100),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (sponsor != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTint,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.volunteer_activism_rounded,
                              color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              sponsor.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Sponsor represents verified status sadaka. Removing Association will orphan this cooler.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.slate500, height: 1.4),
                    ),
                    const Spacer(),
                    if (_error != null) ...[
                      Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                      const SizedBox(height: 8),
                    ],
                    OutlinedButton(
                      onPressed: _loading ? null : _removeSponsor,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _loading
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Remove Assigned Sponsor', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ] else ...[
                    const Text(
                      'Select sponsor profile from records:',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.slate600),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: widget.sponsors.isEmpty
                          ? const Center(child: Text('Create a sponsor first in the Sponsors tab.'))
                          : ListView.builder(
                              itemCount: widget.sponsors.length,
                              itemBuilder: (ctx, i) {
                                final s = widget.sponsors[i];
                                return ListTile(
                                  title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  subtitle: Text(s.sponsorType, style: const TextStyle(fontSize: 11)),
                                  trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                                  onTap: () => _assign(s.id),
                                );
                              },
                            ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
