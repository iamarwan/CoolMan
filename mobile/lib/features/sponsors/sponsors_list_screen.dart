import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error_text.dart';
import '../../shared/ui.dart';
import '../profile/profile_repository.dart';
import 'sponsor_screen.dart';

class SponsorsListScreen extends ConsumerWidget {
  const SponsorsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sponsors = ref.watch(sponsorsProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Sponsors')),
      body: sponsors.when(
        data: (list) => list.isEmpty
            ? const Center(child: Text('No sponsors yet.'))
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
                      subtitle: Text('${sponsorTypeLabel(s.type)} · ${s.coolerCount} coolers'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => SponsorScreen(sponsor: s)),
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(errorText(e))),
      ),
    );
  }
}
