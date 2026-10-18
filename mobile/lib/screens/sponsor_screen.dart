// lib/screens/sponsor_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sponsor.dart';
import '../core/theme.dart';

class SponsorScreen extends StatelessWidget {
  final Sponsor sponsor;

  const SponsorScreen({super.key, required this.sponsor});

  String _typeLabel(String type) => switch (type) {
        'Business' => 'Local Business Contribution',
        'Mosque' => 'Mosque / Religious Center',
        'Individual' => 'Private Generous Contributor',
        'NGO' => 'NGO / Humanitarian Aid',
        _ => type,
      };

  IconData _typeIcon(String type) => switch (type) {
        'Business' => Icons.storefront_rounded,
        'Mosque' => Icons.mosque_rounded,
        'Individual' => Icons.person_rounded,
        'NGO' => Icons.volunteer_activism_rounded,
        _ => Icons.business_rounded,
      };

  Future<void> _launchContact(BuildContext context, String contact) async {
    final phoneUri = Uri.parse('tel:$contact');
    final webUri = Uri.parse(
        contact.startsWith('http') ? contact : 'https://$contact');
    var opened = false;
    try {
      if (await canLaunchUrl(phoneUri)) {
        opened = await launchUrl(phoneUri);
      } else if (await canLaunchUrl(webUri)) {
        opened = await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Opening contact failed: $e');
    }
    // Tell the person whenever nothing opened, not only when an error was thrown.
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not open contact.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: const Text(
          'Sponsor Profile',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.5),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ─── Header Card ───────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.teal600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _typeIcon(sponsor.sponsorType),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  sponsor.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              if (sponsor.verified)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.5)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified_rounded,
                                          color: Colors.white, size: 12),
                                      SizedBox(width: 4),
                                      Text(
                                        'Verified',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _typeLabel(sponsor.sponsorType),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.teal.shade100,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.water_drop_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Maintains ${sponsor.coolerCount} Coolers',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ─── Sadaka Jariya Note ─────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.slate900.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: AppColors.slate100),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppColors.successTint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.volunteer_activism_rounded,
                      color: AppColors.successDark, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sadaka Jariya (On-going Charity)',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.slate800),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Providing free access to cool drinking water is of significant communal value. This sponsor funds refills, cup stock, maintenance, and repairs for the assigned coolers.',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.slate600, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─── Contact Button ─────────────────────
          if (sponsor.contact != null && sponsor.contact!.isNotEmpty) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _launchContact(context, sponsor.contact!),
                icon: const Icon(Icons.phone_rounded, size: 18),
                label: const Text('Contact Sponsor'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.2),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
