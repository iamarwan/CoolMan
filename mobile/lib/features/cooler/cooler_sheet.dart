// Cooler details sheet. Contributions follow the "be there" rule: the sheet
// shows whether the user is close enough, and actions are optimistic (the
// screen updates at once and rolls back if the server refuses).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/directions.dart';
import '../../core/error_text.dart';
import '../../core/format.dart';
import '../../core/locale.dart';
import '../../core/location_service.dart';
import '../../core/session.dart';
import '../../l10n/app_localizations.dart';
import '../../models/cooler.dart';
import '../../shared/ui.dart';
import '../auth/auth_sheet.dart';
import '../map/map_pins_controller.dart';
import '../map/user_location_controller.dart';
import '../patron/patron_screen.dart';
import '../profile/profile_repository.dart';
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
        initialChildSize: 0.62,
        minChildSize: 0.3,
        maxChildSize: 0.94,
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
  bool _busy = false;
  bool _uploading = false;

  CoolerRepository get _repo => ref.read(coolerRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _load();
    // Refresh the position quietly so the distance shown is current.
    if (AppConfig.maxActionDistanceM > 0) {
      Future.microtask(() => ref.read(userLocationProvider.notifier).locate(precise: true));
    }
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

  /// Login, then a fresh precise position that passes the rule. Returns null
  /// (after telling the user why) if the action cannot go ahead.
  Future<({Fix? fix})?> _prepare() async {
    final c = _cooler!;
    if (!await ensureLoggedIn(context, ref) || !mounted) return null;
    if (AppConfig.maxActionDistanceM <= 0) return (fix: ref.read(userLocationProvider).fix);

    await ref.read(userLocationProvider.notifier).locate(precise: true);
    if (!mounted) return null;
    final state = ref.read(userLocationProvider);
    final range = rangeTo(state, LatLng(c.lat, c.lng));
    if (range.allowed) return (fix: state.fix);
    showSnack(context, _rangeText(context.l10n, range), error: true);
    return null;
  }

  Future<void> _confirm() async {
    final before = _cooler!;
    final ready = await _prepare();
    if (ready == null) return;
    setState(() {
      _busy = true;
      _cooler = before.copyWith(
        lastVerifiedAt: DateTime.now(),
        confirmationsCount: before.confirmationsCount + 1,
      );
    });
    try {
      final r = await _repo.confirm(before.id, at: ready.fix);
      ref.read(sessionProvider.notifier).updateScore(r.trustScore);
      refreshMyData(ref);
      if (mounted) {
        showSnack(
          context,
          r.pointsAwarded > 0
              ? context.l10n.thanksConfirmPoints(r.pointsAwarded)
              : context.l10n.thanksConfirmNoPoints,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _cooler = before);
      showSnack(context, errorText(context.l10n, e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _report(CoolerStatus status) async {
    final before = _cooler!;
    final ready = await _prepare();
    if (ready == null) return;
    final trusted = ref.read(sessionProvider).isTrusted;
    final pins = ref.read(mapPinsProvider.notifier);

    setState(() {
      _busy = true;
      _cooler = trusted
          ? before.copyWith(status: status, lastVerifiedAt: DateTime.now(), clearPending: true)
          : before.copyWith(pendingStatus: status);
    });
    if (trusted) pins.setStatus(before.id, status);

    try {
      final updated = await _repo.reportStatus(before.id, status, at: ready.fix);
      if (!mounted) return;
      setState(() => _cooler = updated.copyWith(confirmationsCount: before.confirmationsCount));
      pins.setStatus(updated.id, updated.status);
      ref.read(sessionProvider.notifier).refreshProfile();
      refreshMyData(ref);
      showSnack(context, trusted ? context.l10n.statusUpdated : context.l10n.reportReviewed);
    } catch (e) {
      if (!mounted) return;
      setState(() => _cooler = before);
      pins.setStatus(before.id, before.status);
      showSnack(context, errorText(context.l10n, e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addPhoto() async {
    final ready = await _prepare();
    if (ready == null || !mounted) return;
    final picked = await pickPhoto(context);
    if (picked == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      final photo = await _repo.uploadPhoto(_cooler!.id, picked.path, picked.category, at: ready.fix);
      if (!mounted) return;
      refreshMyData(ref);
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

    final location = ref.watch(userLocationProvider);
    final range = rangeTo(location, LatLng(c.lat, c.lng));
    final waiting = !c.isApproved;
    final canAct = !waiting && !_busy && range.allowed;
    final freshness = freshnessOf(c.lastVerifiedAt);

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        const SheetHandle(),
        Text(c.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          if (waiting)
            Pill(
              text: l.subUnderReview,
              color: AppColors.pending,
              background: AppColors.pendingBg,
              icon: Icons.schedule,
            )
          else
            StatusChip(status: c.status),
          if (c.pendingStatus != null && c.pendingStatus != c.status)
            StatusChip(status: c.pendingStatus!, pending: true),
          Pill(
            text: l.lastConfirmed(timeAgo(l, c.lastVerifiedAt)),
            color: freshness.color,
            background: AppColors.surfaceLow,
            icon: Icons.verified_outlined,
          ),
        ]),
        const SizedBox(height: 14),
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
            child: _InfoTile(
              icon: Icons.directions_walk,
              label: l.distance,
              value: range.meters == null
                  ? '–'
                  : '${formatDistance(l, range.meters!)} · ${walkingTime(l, range.meters!)}',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _InfoTile(
              icon: c.hasCups == true ? Icons.local_cafe : Icons.local_cafe_outlined,
              label: l.cups,
              value: cupsLabel(l, c.hasCups, c.cupsType),
            ),
          ),
        ])),
        const SizedBox(height: 16),
        _PhotoStrip(
          photos: c.photos,
          uploading: _uploading,
          onAdd: waiting || _uploading ? null : _addPhoto,
        ),
        if (c.sponsor != null) ...[
          const SizedBox(height: 14),
          _PatronCard(cooler: c),
        ],
        const SizedBox(height: 14),
        if (waiting)
          _Banner(
            icon: Icons.schedule,
            color: AppColors.pending,
            background: AppColors.pendingBg,
            text: l.waitingReview,
          )
        else ...[
          _RangeBanner(range: range, onDirections: () => openDirections(context, c.lat, c.lng)),
          const SizedBox(height: 12),
          if (c.status == CoolerStatus.working)
            FilledButton.icon(
              onPressed: canAct ? _confirm : null,
              icon: const Icon(Icons.check_circle_outline),
              label: Text(l.stillWorkingPoints),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
            ),
          const SizedBox(height: 10),
          Row(children: [
            for (final s in CoolerStatus.values)
              if (s != c.status)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: TintButton(
                      label: s.reportLabel(l),
                      icon: s.icon,
                      iconColor: s.color,
                      onPressed: canAct ? () => _report(s) : null,
                    ),
                  ),
                ),
            Expanded(
              child: TintButton(
                label: _uploading ? l.uploading : l.addPhoto,
                icon: Icons.add_a_photo_outlined,
                onPressed: canAct && !_uploading ? _addPhoto : null,
              ),
            ),
          ]),
        ],
        const SizedBox(height: 10),
        Material(
          color: AppColors.surfaceTint,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.button),
            onTap: () => openDirections(context, c.lat, c.lng),
            child: SizedBox(
              height: 52,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.directions_walk, color: AppColors.primaryDark),
                const SizedBox(width: 8),
                Text(
                  range.meters == null ? l.directions : '${l.directions} (${formatDistance(l, range.meters!)})',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ]),
            ),
          ),
        ),
      ],
    );
  }
}

String _rangeText(AppLocalizations l, RangeInfo r) => switch (r.range) {
      Range.near => l.rangeNear(r.meters!.round()),
      Range.far => l.rangeFar(AppConfig.maxActionDistanceM, formatDistance(l, r.meters!)),
      Range.inaccurate => l.rangeInaccurate,
      Range.locating => l.rangeLocating,
      Range.unknown || Range.noPermission => l.rangeNeedLocation,
      Range.off => '',
    };

class _RangeBanner extends StatelessWidget {
  const _RangeBanner({required this.range, required this.onDirections});

  final RangeInfo range;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (range.range == Range.off) return const SizedBox.shrink();
    final (icon, color, bg) = switch (range.range) {
      Range.near => (Icons.check_circle, AppColors.primaryDark, AppColors.primaryContainer),
      Range.far => (Icons.social_distance, AppColors.ink, AppColors.surfaceLow),
      Range.inaccurate || Range.locating => (Icons.gps_not_fixed, AppColors.pending, AppColors.pendingBg),
      _ => (Icons.location_off_outlined, AppColors.broken, AppColors.brokenBg),
    };
    return _Banner(
      icon: icon,
      color: color,
      background: bg,
      text: _rangeText(l, range),
      busy: range.range == Range.locating,
      trailing: range.range == Range.far
          ? TextButton(onPressed: onDirections, child: Text(l.directions))
          : null,
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.color,
    required this.background,
    required this.text,
    this.trailing,
    this.busy = false,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final String text;
  final Widget? trailing;
  final bool busy;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 8, 10),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadius.card)),
        child: Row(children: [
          if (busy)
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: color))
          else
            Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600, height: 1.4)),
          ),
          ?trailing,
        ]),
      );
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

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(children: [
          IconBadge(icon, background: AppColors.primaryContainer, color: AppColors.primaryDark, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)),
              Text(value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, height: 1.3)),
            ]),
          ),
        ]),
      );
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({required this.photos, required this.onAdd, required this.uploading});

  final List<CoolerPhoto> photos;
  final VoidCallback? onAdd;
  final bool uploading;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l.photosTitle(photos.length), style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      SizedBox(
        height: 104,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (var i = 0; i < photos.length; i++)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => PhotoViewer(photos: photos, initialIndex: i),
                  )),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    child: Image.network(
                      AppConfig.absoluteUrl(photos[i].thumbUrl ?? photos[i].url),
                      width: 104,
                      height: 104,
                      fit: BoxFit.cover,
                      cacheWidth: (104 * dpr).round(),
                      errorBuilder: (_, _, _) => Container(
                        width: 104,
                        color: AppColors.surfaceLow,
                        child: const Icon(Icons.broken_image_outlined, color: AppColors.muted),
                      ),
                    ),
                  ),
                ),
              ),
            Opacity(
              opacity: onAdd == null ? 0.5 : 1,
              child: InkWell(
                onTap: onAdd,
                borderRadius: BorderRadius.circular(AppRadius.button),
                child: Container(
                  width: 104,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLow,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    if (uploading)
                      const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                    else
                      const Icon(Icons.add_a_photo_outlined, color: AppColors.primaryDark),
                    const SizedBox(height: 6),
                    Text(uploading ? l.uploading : l.addPhoto,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    ]);
  }
}

/// The patron (family, mosque, business or NGO) who funds or looks after this
/// cooler. Shown only on coolers that have one.
class _PatronCard extends StatelessWidget {
  const _PatronCard({required this.cooler});

  final Cooler cooler;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final patron = cooler.sponsor!;
    return Material(
      color: AppColors.patronBg,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PatronScreen(patron: patron, cooler: cooler)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            IconBadge(patronTypeIcon(patron.type), color: Colors.white, background: AppColors.patron, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  patronTypeLabel(l, patron.type).toUpperCase(),
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: AppColors.patron),
                ),
                Text(patron.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, height: 1.3)),
                Text(l.confirmedTimes(cooler.confirmationsCount),
                    style: const TextStyle(color: AppColors.muted, fontSize: 13)),
              ]),
            ),
            const Icon(Icons.chevron_right, color: AppColors.patron),
          ]),
        ),
      ),
    );
  }
}
