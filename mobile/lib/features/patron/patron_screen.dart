// A cooler's patron: the family, mosque, business or NGO behind it.
// Opened only from that cooler's sheet; there is no list of patrons.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/format.dart';
import '../../core/locale.dart';
import '../../l10n/app_localizations.dart';
import '../../models/cooler.dart';
import '../../shared/ui.dart';

IconData patronTypeIcon(String type) => switch (type) {
      'Mosque' => Icons.mosque_outlined,
      'Individual' => Icons.volunteer_activism_outlined,
      'NGO' => Icons.diversity_1_outlined,
      _ => Icons.storefront_outlined,
    };

String patronTypeLabel(AppLocalizations l, String type) => switch (type) {
      'Mosque' => l.sponsorTypeMosque,
      'Individual' => l.patronFamily,
      'NGO' => l.sponsorTypeNgo,
      _ => l.sponsorTypeBusiness,
    };

Future<void> openPatronContact(BuildContext context, String contact) async {
  final c = contact.trim();
  final isPhone = RegExp(r'^\+?[\d\s\-()]{6,}$').hasMatch(c);
  final uri = isPhone
      ? Uri(scheme: 'tel', path: c.replaceAll(RegExp(r'[\s\-()]'), ''))
      : Uri.parse(c.startsWith('http') ? c : 'https://$c');
  try {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) {
      showSnack(context, context.l10n.errContact, error: true);
    }
  } catch (_) {
    if (context.mounted) showSnack(context, context.l10n.errContact, error: true);
  }
}

class PatronScreen extends StatelessWidget {
  const PatronScreen({super.key, required this.patron, required this.cooler});

  final Sponsor patron;
  final Cooler cooler;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.sponsorTitle)),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 28), children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.patron,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 8, runSpacing: 8, children: [
              _HeroPill(icon: patronTypeIcon(patron.type), text: patronTypeLabel(l, patron.type)),
              if (patron.verified) _HeroPill(icon: Icons.verified, text: l.verifiedSponsor),
            ]),
            const SizedBox(height: 14),
            Text(
              patron.name,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700, height: 1.3),
            ),
            const SizedBox(height: 6),
            Text(cooler.name, style: const TextStyle(color: Color(0xFFEDE4FF), fontSize: 15)),
          ]),
        ),
        const SizedBox(height: 14),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.patronImpact, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: _Metric(
                  icon: Icons.thumb_up_alt_outlined,
                  value: '${cooler.confirmationsCount}',
                  label: l.statConfirmations,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Metric(
                  icon: Icons.schedule,
                  value: timeAgo(l, cooler.lastVerifiedAt),
                  label: l.lastChecked,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              StatusChip(status: cooler.status),
              const SizedBox(width: 8),
              Flexible(
                child: Text(cupsLabel(l, cooler.hasCups, cooler.cupsType),
                    style: const TextStyle(color: AppColors.muted)),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 14),
        AppCard(
          color: AppColors.primaryContainer,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.favorite_outline, color: AppColors.primaryDark),
            const SizedBox(width: 12),
            Expanded(child: Text(l.sponsorThanks, style: const TextStyle(color: AppColors.primaryDark, height: 1.5))),
          ]),
        ),
        if (patron.contact != null && patron.contact!.isNotEmpty) ...[
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => openPatronContact(context, patron.contact!),
            icon: const Icon(Icons.call_outlined),
            label: Text(patron.contact!, textDirection: TextDirection.ltr),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          ),
        ],
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.map_outlined),
          label: Text(l.viewOnMap),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),
      ]),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
        ]),
      );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.surfaceLow, borderRadius: BorderRadius.circular(AppRadius.button)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 20, color: AppColors.primaryDark),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ]),
      );
}
