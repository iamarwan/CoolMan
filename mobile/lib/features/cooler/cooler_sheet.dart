// Cooler details bottom sheet. Actions are optimistic: the screen updates at
// once and rolls back if the server refuses.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/error_text.dart';
import '../../core/format.dart';
import '../../core/locale.dart';
import '../../core/session.dart';
import '../../models/cooler.dart';
import '../../shared/ui.dart';
import '../auth/auth_sheet.dart';
import '../map/map_pins_controller.dart';
import '../map/user_location_controller.dart';
import '../sponsors/sponsor_screen.dart';
import 'cooler_repository.dart';
import 'photo_picker.dart';
import 'photo_viewer.dart';

Future<void> showCoolerSheet(BuildContext context, String coolerId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // Own ScaffoldMessenger so snackbars appear on the sheet, not behind it.
    builder: (_) => ScaffoldMessenger(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.92,
        builder: (_, scroll) => Scaffold(
          backgroundColor: Colors.transparent,
          body: CoolerSheet(coolerId: coolerId, scrollController: scroll),
        ),
      ),
    ),
  );
}

class CoolerSheet extends ConsumerStatefulWidget {
  const CoolerSheet({super.key, required this.coolerId, this.scrollController});

  final String coolerId;
  final ScrollController? scrollController;

  @override
  ConsumerState<CoolerSheet> createState() => _CoolerSheetState();
}

class _CoolerSheetState extends ConsumerState<CoolerSheet> {
  Cooler? _cooler;
  Object? _loadError;
  bool _confirming = false;
  bool _reporting = false;
  bool _uploading = false;

  CoolerRepository get _repo => ref.read(coolerRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final c = await _repo.detail(widget.coolerId);
      if (!mounted) return;
      setState(() => _cooler = c);
      ref.read(mapPinsProvider.notifier).upsert(c.toPin());
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e);
      // Deleted or no longer approved: drop the stale pin.
      if (e is ApiException && e.status == 404) {
        ref.read(mapPinsProvider.notifier).remove(widget.coolerId);
      }
    }
  }

  Future<void> _confirm() async {
    final before = _cooler!;
    if (!await ensureLoggedIn(context, ref) || !mounted) return;
    setState(() {
      _confirming = true;
      _cooler = before.copyWith(lastVerifiedAt: DateTime.now());
    });
    try {
      final r = await _repo.confirm(before.id);
      ref.read(sessionProvider.notifier).updateScore(r.trustScore);
      if (mounted) showSnack(context, context.l10n.thanksConfirm);
    } catch (e) {
      if (!mounted) return;
      setState(() => _cooler = before);
      showSnack(context, errorText(context.l10n, e), error: true);
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  Future<void> _report(CoolerStatus status) async {
    final before = _cooler!;
    if (!await ensureLoggedIn(context, ref) || !mounted) return;
    final trusted = ref.read(sessionProvider).isTrusted;
    final pins = ref.read(mapPinsProvider.notifier);

    setState(() {
      _reporting = true;
      _cooler = trusted
          ? before.copyWith(status: status, lastVerifiedAt: DateTime.now(), clearPending: true)
          : before.copyWith(pendingStatus: status);
    });
    if (trusted) pins.setStatus(before.id, status);

    try {
      final updated = await _repo.reportStatus(before.id, status);
      if (!mounted) return;
      setState(() => _cooler = updated);
      pins.setStatus(updated.id, updated.status);
      ref.read(sessionProvider.notifier).refreshProfile();
      showSnack(
        context,
        trusted ? context.l10n.statusUpdatedPoints : context.l10n.reportReviewedPoints,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _cooler = before);
      pins.setStatus(before.id, before.status);
      showSnack(context, errorText(context.l10n, e), error: true);
    } finally {
      if (mounted) setState(() => _reporting = false);
    }
  }

  Future<void> _addPhoto() async {
    if (!await ensureLoggedIn(context, ref) || !mounted) return;
    final picked = await pickPhoto(context);
    if (picked == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      final photo = await _repo.uploadPhoto(_cooler!.id, picked.path, picked.category);
      if (!mounted) return;
      if (photo.isApproved) {
        setState(() => _cooler = _cooler!.copyWith(photos: [photo, ..._cooler!.photos]));
        showSnack(context, context.l10n.photoAdded);
      } else {
        showSnack(context, context.l10n.photoSentForReview);
      }
    } catch (e) {
      if (mounted) showSnack(context, errorText(context.l10n, e), error: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _directions() async {
    final c = _cooler!;
    final google = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${c.lat},${c.lng}&travelmode=walking');
    final geo = Uri.parse('geo:${c.lat},${c.lng}?q=${c.lat},${c.lng}');
    try {
      if (!await launchUrl(google, mode: LaunchMode.externalApplication)) {
        await launchUrl(geo, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (mounted) showSnack(context, context.l10n.errDirections, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = _cooler;
    if (c == null) {
      return _loadError != null
          ? _Message(
              icon: Icons.cloud_off_outlined,
              text: errorText(l, _loadError!),
              action: TextButton(onPressed: _load, child: Text(l.tryAgain)),
            )
          : _Message(icon: null, text: l.loading);
    }

    final userPos = ref.watch(userLocationProvider.select((s) => s.position));
    final meters = userPos == null ? null : metersBetween(userPos, LatLng(c.lat, c.lng));
    final freshness = freshnessOf(c.lastVerifiedAt);

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        const SheetHandle(),
        Row(children: [
          Expanded(
            child: Text(c.name,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800, color: AppColors.ink)),
          ),
          IconButton.filled(
            onPressed: _directions,
            tooltip: l.directions,
            icon: const Icon(Icons.directions_walk),
          ),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          StatusChip(status: c.status),
          if (c.pendingStatus != null && c.pendingStatus != c.status)
            StatusChip(status: c.pendingStatus!, pending: true),
          if (meters != null)
            Text('${formatDistance(l, meters)} · ${walkingTime(l, meters)}',
                style: const TextStyle(color: AppColors.muted)),
        ]),
        const SizedBox(height: 16),
        _InfoRow(
          icon: Icons.verified_outlined,
          color: freshness.color,
          text: l.lastConfirmed(timeAgo(l, c.lastVerifiedAt)),
        ),
        _InfoRow(
          icon: c.hasCups == true ? Icons.coffee : Icons.coffee_outlined,
          color: c.hasCups == true ? AppColors.working : AppColors.muted,
          text: cupsLabel(l, c.hasCups, c.cupsType),
        ),
        if (c.photos.isNotEmpty) ...[
          const SizedBox(height: 12),
          _PhotoStrip(photos: c.photos),
        ],
        if (c.sponsor != null) ...[
          const SizedBox(height: 12),
          _SponsorCard(sponsor: c.sponsor!),
        ],
        const SizedBox(height: 20),
        if (c.status == CoolerStatus.working)
          FilledButton.icon(
            onPressed: _confirming ? null : _confirm,
            icon: const Icon(Icons.check_circle_outline),
            label: Text(l.stillWorking),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.working,
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        const SizedBox(height: 12),
        Text(l.somethingChanged,
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.muted)),
        const SizedBox(height: 8),
        Row(children: [
          for (final s in CoolerStatus.values)
            if (s != c.status)
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: OutlinedButton.icon(
                    onPressed: _reporting ? null : () => _report(s),
                    icon: Icon(s.icon, color: s.color, size: 18),
                    label: Text(s.reportLabel(l)),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  ),
                ),
              ),
        ]),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _uploading ? null : _addPhoto,
          icon: _uploading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.add_a_photo_outlined),
          label: Text(_uploading ? l.uploading : l.addPhoto),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});

  final IconData? icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null)
            Icon(icon, size: 40, color: AppColors.muted)
          else
            const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
          ?action,
        ]),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ]),
      );
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({required this.photos});

  final List<CoolerPhoto> photos;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) => GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => PhotoViewer(photos: photos, initialIndex: i),
          )),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              AppConfig.absoluteUrl(photos[i].thumbUrl ?? photos[i].url),
              width: 96,
              height: 96,
              fit: BoxFit.cover,
              cacheWidth: (96 * dpr).round(),
              errorBuilder: (_, _, _) => Container(
                width: 96,
                color: AppColors.line,
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SponsorCard extends StatelessWidget {
  const _SponsorCard({required this.sponsor});

  final Sponsor sponsor;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        color: AppColors.sponsor.withValues(alpha: 0.06),
        elevation: 0,
        child: ListTile(
          leading: Icon(sponsorTypeIcon(sponsor.type), color: AppColors.sponsor),
          title: Text(context.l10n.maintainedBy(sponsor.name)),
          subtitle: sponsor.verified ? Text(context.l10n.verifiedSponsor) : null,
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => SponsorScreen(sponsor: sponsor)),
          ),
        ),
      );
}
