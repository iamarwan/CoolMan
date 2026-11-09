import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error_text.dart';
import '../../core/locale.dart';
import '../../shared/ui.dart';
import '../profile/profile_repository.dart';
import 'sponsor_screen.dart';

class SponsorsListScreen extends ConsumerWidget {
  const SponsorsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final sponsors = ref.watch(sponsorsProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text(l.sponsors)),
      body: sponsors.when(
        data: (list) => list.isEmpty
            ? Center(child: Text(l.sponsorsEmpty))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final s = list[i];
                  return Card(
                    child: ListTile(
                      leading: Icon(sponsorTypeIcon(s.type), color: AppColors.sponsor),
                      title: Row(children: [
                        Flexible(child: Text(s.name)),
                        if (s.verified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, size: 16, color: AppColors.working),
                        ],
                      ]),
                      subtitle: Text('${sponsorTypeLabel(l, s.type)} · ${l.sponsorCoolerCount(s.coolerCount)}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => SponsorScreen(sponsor: s)),
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(errorText(l, e))),
      ),
    );
  }
}
