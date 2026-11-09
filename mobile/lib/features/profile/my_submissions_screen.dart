import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error_text.dart';
import '../../core/format.dart';
import '../../core/locale.dart';
import '../../models/cooler.dart';
import '../../shared/ui.dart';
import 'profile_repository.dart';

class MySubmissionsScreen extends ConsumerWidget {
  const MySubmissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final items = ref.watch(mySubmissionsProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text(l.mySubmissions)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(mySubmissionsProvider.future),
        child: items.when(
          data: (list) => list.isEmpty
              ? ListView(children: [
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(l.submissionsEmpty, textAlign: TextAlign.center),
                  ),
                ])
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _SubmissionTile(cooler: list[i]),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(children: [
            Padding(padding: const EdgeInsets.all(32), child: Text(errorText(l, e), textAlign: TextAlign.center)),
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
    final l = context.l10n;
    final (label, color, icon) = cooler.isRejected
        ? (l.subRejected, AppColors.broken, Icons.cancel_outlined)
        : !cooler.isApproved
            ? (l.subUnderReview, AppColors.empty, Icons.hourglass_top)
            : cooler.pendingStatus != null
                ? (l.subStatusPending, AppColors.pending, Icons.swap_horiz)
                : (l.subLive, AppColors.working, Icons.check_circle_outline);
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(cooler.name),
        subtitle: Text(l.subAdded(label, timeAgo(l, cooler.createdAt))),
        trailing: StatusChip(status: cooler.status),
      ),
    );
  }
}
