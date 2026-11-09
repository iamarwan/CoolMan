import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/cooler.dart';
import '../../shared/ui.dart';

IconData sponsorTypeIcon(String type) => switch (type) {
      'Mosque' => Icons.mosque_outlined,
      'Individual' => Icons.person_outline,
      'NGO' => Icons.volunteer_activism_outlined,
      _ => Icons.storefront_outlined,
    };

String sponsorTypeLabel(String type) => switch (type) {
      'Mosque' => 'Mosque',
      'Individual' => 'Individual donor',
      'NGO' => 'NGO',
      _ => 'Local business',
    };

Future<void> openSponsorContact(BuildContext context, String contact) async {
  final c = contact.trim();
  final isPhone = RegExp(r'^\+?[\d\s\-()]{6,}$').hasMatch(c);
  final uri = isPhone
      ? Uri(scheme: 'tel', path: c.replaceAll(RegExp(r'[\s\-()]'), ''))
      : Uri.parse(c.startsWith('http') ? c : 'https://$c');
  try {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) {
      showSnack(context, 'Could not open contact.', error: true);
    }
  } catch (_) {
    if (context.mounted) showSnack(context, 'Could not open contact.', error: true);
  }
}

class SponsorScreen extends StatelessWidget {
  const SponsorScreen({super.key, required this.sponsor});

  final Sponsor sponsor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Sponsor')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Center(
          child: CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.sponsor.withValues(alpha: 0.12),
            child: Icon(sponsorTypeIcon(sponsor.type), size: 40, color: AppColors.sponsor),
          ),
        ),
        const SizedBox(height: 16),
        Text(sponsor.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(sponsorTypeLabel(sponsor.type),
            textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
        if (sponsor.verified) ...[
          const SizedBox(height: 8),
          const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.verified, color: AppColors.working, size: 18),
            SizedBox(width: 4),
            Text('Verified sponsor', style: TextStyle(color: AppColors.working)),
          ]),
        ],
        const SizedBox(height: 24),
        const Text(
          'This sponsor helps keep public water coolers working. Thank you!',
          textAlign: TextAlign.center,
        ),
        if (sponsor.contact != null && sponsor.contact!.isNotEmpty) ...[
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => openSponsorContact(context, sponsor.contact!),
            icon: const Icon(Icons.call_outlined),
            label: Text(sponsor.contact!),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          ),
        ],
      ]),
    );
  }
}
