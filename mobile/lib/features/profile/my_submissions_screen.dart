import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error_text.dart';
import '../../core/format.dart';
import '../../models/cooler.dart';
import '../../shared/ui.dart';
import 'profile_repository.dart';

class MySubmissionsScreen extends ConsumerWidget {
  const MySubmissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(mySubmissionsProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('My submissions')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(mySubmissionsProvider.future),
        child: items.when(
          data: (list) => list.isEmpty
              ? ListView(children: const [
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Nothing yet. Add a cooler from the map to help others find water.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ])
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _SubmissionTile(cooler: list[i]),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(children: [
            Padding(padding: const EdgeInsets.all(32), child: Text(errorText(e), textAlign: TextAlign.center)),
          ]),
        ),
      ),
    );
  }
}

class _SubmissionTile extends StatelessWidget {
  const _SubmissionTile({required this.cooler});

  final Cooler cooler;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = cooler.isRejected
        ? ('Rejected', AppColors.broken, Icons.cancel_outlined)
        : !cooler.isApproved
            ? ('Under review', AppColors.empty, Icons.hourglass_top)
            : cooler.pendingStatus != null
                ? ('Status change pending', AppColors.pending, Icons.swap_horiz)
                : ('Live on the map', AppColors.working, Icons.check_circle_outline);
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(cooler.name),
        subtitle: Text('$label · added ${timeAgo(cooler.createdAt)}'),
        trailing: StatusChip(status: cooler.status),
      ),
    );
  }
}
