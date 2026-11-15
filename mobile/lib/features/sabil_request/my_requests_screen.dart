// The user's own build-a-sabil requests and where each one stands.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error_text.dart';
import '../../core/format.dart';
import '../../core/locale.dart';
import '../../models/sabil_request.dart';
import '../../shared/ui.dart';
import 'request_labels.dart';
import 'sabil_request_repository.dart';
import 'sabil_request_screen.dart';

class MyRequestsScreen extends ConsumerWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final requests = ref.watch(myRequestsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.myRequests)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openSabilRequest(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l.reqEntryButton),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myRequestsProvider.future),
        child: requests.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(errorText(l, e), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Center(
                child: TextButton(onPressed: () => ref.invalidate(myRequestsProvider), child: Text(l.retry)),
              ),
            ],
          ),
          data: (list) => list.isEmpty
              ? ListView(
                  padding: const EdgeInsets.all(32),
                  children: [
                    const Center(child: IconBadge(Icons.water_drop_outlined, size: 56)),
                    const SizedBox(height: 14),
                    Text(
                      l.myRequestsEmpty,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _RequestCard(request: list[i]),
                ),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final SabilRequest request;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = request;
    final pkg = packageInfo(l, r.package);
    final status = requestStatus(l, r.status);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(pkg.icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.package == 'company' ? '${pkg.title} × ${r.quantity}' : pkg.title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    Text(
                      '${r.area}, ${governorateName(context, r.governorate)} · ${timeAgo(l, r.createdAt)}',
                      style: const TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Pill(text: status.label, color: status.color, background: status.background),
              Pill(
                text: labelFor(purposeOptions(l), r.purpose),
                color: AppColors.primaryDark,
                background: AppColors.primaryContainer,
                icon: Icons.favorite_outline,
              ),
            ],
          ),
          if (r.dedicationName != null) ...[
            const SizedBox(height: 10),
            Text(r.dedicationName!, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
          if (r.quoteEgp != null) ...[
            const SizedBox(height: 10),
            Text(
              l.reqQuote(formatEgp(r.quoteEgp!)),
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.patron),
            ),
          ],
        ],
      ),
    );
  }
}

/// 24900 → "24,900".
String formatEgp(int amount) => amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
