// "My reports" tab: the coolers this user added and reports still in review.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error_text.dart';
import '../../core/format.dart';
import '../../core/locale.dart';
import '../../core/session.dart';
import '../../models/cooler.dart';
import '../../shared/ui.dart';
import '../auth/auth_sheet.dart';
import '../cooler/cooler_sheet.dart';
import 'profile_repository.dart';

class MySubmissionsScreen extends ConsumerWidget {
  const MySubmissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final loggedIn = ref.watch(sessionProvider.select((s) => s.isLoggedIn));

    Widget body;
    if (!loggedIn) {
      body = _Empty(
        icon: Icons.verified_outlined,
        text: l.signInPrompt,
        action: FilledButton(onPressed: () => ensureLoggedIn(context, ref), child: Text(l.guestLogin)),
      );
    } else {
      final items = ref.watch(mySubmissionsProvider);
      body = RefreshIndicator(
        onRefresh: () => ref.refresh(mySubmissionsProvider.future),
        child: items.when(
          data: (list) => list.isEmpty
              ? ListView(children: [_Empty(icon: Icons.add_location_alt_outlined, text: l.submissionsEmpty)])
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _SubmissionCard(cooler: list[i]),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(children: [_Empty(icon: Icons.cloud_off_outlined, text: errorText(l, e))]),
        ),
      );
    }

    return Scaffold(appBar: AppBar(title: Text(l.navReports)), body: body);
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(32, 64, 32, 32),
        child: Column(children: [
          IconBadge(icon, size: 64, background: AppColors.primaryContainer, color: AppColors.primaryDark),
          const SizedBox(height: 16),
          Text(text, textAlign: TextAlign.center, style: const TextStyle(height: 1.5)),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ]),
      );
}

class _SubmissionCard extends StatelessWidget {
  const _SubmissionCard({required this.cooler});

  final Cooler cooler;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final (label, color, bg, icon) = cooler.isRejected
        ? (l.subRejected, AppColors.broken, AppColors.brokenBg, Icons.cancel_outlined)
        : !cooler.isApproved
            ? (l.subUnderReview, AppColors.pending, AppColors.pendingBg, Icons.schedule)
            : cooler.pendingStatus != null
                ? (l.subStatusPending, AppColors.empty, AppColors.emptyBg, Icons.swap_horiz)
                : (l.subLive, AppColors.working, AppColors.workingBg, Icons.check_circle_outline);
    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: cooler.isRejected ? null : () => showCoolerSheet(context, cooler.id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            IconBadge(icon, color: color, background: bg, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(cooler.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 4),
                Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Pill(text: label, color: color, background: bg, icon: icon),
                  Text(timeAgo(l, cooler.createdAt), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                ]),
              ]),
            ),
            if (!cooler.isRejected) const Icon(Icons.chevron_right, color: AppColors.muted),
          ]),
        ),
      ),
    );
  }
}
