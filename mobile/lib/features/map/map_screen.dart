// Home: the map is the app. Search and filters float on top, the nearest
// working cooler sits in a card at the bottom, details open in a sheet.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/config.dart';
import '../../core/error_text.dart';
import '../../core/format.dart';
import '../../core/locale.dart';
import '../../core/location_service.dart';
import '../../core/providers.dart';
import '../../models/cooler.dart';
import '../../shared/ui.dart';
import '../auth/auth_sheet.dart';
import '../cooler/add_cooler_sheet.dart';
import '../cooler/cooler_sheet.dart';
import '../home/home_shell.dart';
import 'bbox.dart';
import 'map_filter.dart';
import 'map_pins_controller.dart';
import 'map_search_bar.dart';
import 'nearest_card.dart';
import 'pins_layer.dart';
import 'user_location_controller.dart';

const _cairo = LatLng(29.9600, 31.2500);

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _map = MapController();
  late final LatLng _initialCenter;
  late final double _initialZoom;
  late final bool _hadSavedCamera;
  bool _userMovedMap = false;
  bool _placing = false;

  /// Map centre while placing a new cooler (the pin sits at the centre).
  final _pinPoint = ValueNotifier<LatLng>(_cairo);

  @override
  void initState() {
    super.initState();
    final cam = ref.read(mapPinsProvider.notifier).cachedCamera();
    _hadSavedCamera = cam != null;
    _initialCenter = cam?.center ?? _cairo;
    _initialZoom = cam?.zoom ?? 14.5;
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLocation());
  }

  @override
  void dispose() {
    _map.dispose();
    _pinPoint.dispose();
    super.dispose();
  }

  // ── Location ─────────────────────────────────────────────────────────────

  Future<void> _initLocation() async {
    final loc = ref.read(userLocationProvider.notifier);
    final last = await loc.warmUp();
    if (!mounted) return;
    if (last != null && !_hadSavedCamera && !_userMovedMap) _moveTo(last, 15);
    final fix = await loc.locate();
    if (!mounted) return;
    if (fix != null && !_hadSavedCamera && !_userMovedMap) _moveTo(fix.position, 15);
  }

  Future<void> _goToMyLocation() async {
    final fix = await ref.read(userLocationProvider.notifier).locate();
    if (!mounted) return;
    if (fix != null) {
      _moveTo(fix.position, 16);
      return;
    }
    _explainLocationProblem();
  }

  void _explainLocationProblem() {
    final l = context.l10n;
    final problem = ref.read(userLocationProvider).problem;
    final service = ref.read(locationServiceProvider);
    final (message, action) = switch (problem) {
      LocationProblem.serviceDisabled => (l.locationOff, service.openSettings),
      LocationProblem.deniedForever => (l.locationBlocked, service.openAppSettings),
      LocationProblem.denied => (l.locationDenied, null),
      null => (l.locationUnavailable, null),
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      action: action == null ? null : SnackBarAction(label: l.settings, onPressed: action),
    ));
  }

  void _moveTo(LatLng p, double zoom) {
    try {
      _map.move(p, zoom);
    } catch (_) {
      // Map not ready yet; the next camera event will load pins.
    }
  }

  // ── Map events ───────────────────────────────────────────────────────────

  void _onCamera(MapCamera camera, {bool immediate = false}) {
    if (_placing) _pinPoint.value = camera.center;
    ref.read(mapPinsProvider.notifier).onCameraChanged(
          Bbox.fromBounds(camera.visibleBounds),
          camera.center,
          camera.zoom,
          immediate: immediate,
        );
  }

  void _openCooler(String id) {
    FocusScope.of(context).unfocus();
    showCoolerSheet(context, id);
  }

  void _onSearchSelected(Cooler c) {
    ref.read(mapPinsProvider.notifier).upsert(c.toPin());
    _moveTo(LatLng(c.lat, c.lng), 17);
    _openCooler(c.id);
  }

  // ── Adding a cooler ──────────────────────────────────────────────────────

  Future<void> _startPlacing() async {
    if (!await ensureLoggedIn(context, ref) || !mounted) return;
    // Start the pin where the user stands: a new cooler must be within reach.
    final fix = await ref.read(userLocationProvider.notifier).locate(precise: true);
    if (!mounted) return;
    if (fix != null) _moveTo(fix.position, 18);
    _pinPoint.value = fix?.position ?? _map.camera.center;
    setState(() => _placing = true);
  }

  Future<void> _confirmPlacement() async {
    final point = _map.camera.center;
    final at = ref.read(userLocationProvider).fix;
    setState(() => _placing = false);
    final cooler = await showAddCoolerSheet(context, point, at: at);
    if (cooler == null || !mounted) return;
    showSnack(
      context,
      cooler.isApproved ? context.l10n.coolerAddedLive : context.l10n.coolerSubmitted,
    );
  }

  // ── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final loc = ref.watch(userLocationProvider);
    final userPos = loc.position;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(children: [
        FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: _initialCenter,
            initialZoom: _initialZoom,
            minZoom: 3,
            maxZoom: 19,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            onMapReady: () => _onCamera(_map.camera, immediate: true),
            onPositionChanged: (camera, hasGesture) {
              if (hasGesture) _userMovedMap = true;
              _onCamera(camera);
            },
            onTap: (_, _) => FocusScope.of(context).unfocus(),
          ),
          children: [
            TileLayer(
              urlTemplate: AppConfig.tileUrlTemplate,
              userAgentPackageName: AppConfig.userAgentPackageName,
              maxNativeZoom: 19,
            ),
            // While placing a pin: the area the user is allowed to add in.
            if (_placing && userPos != null && AppConfig.maxActionDistanceM > 0)
              CircleLayer(circles: [
                CircleMarker(
                  point: userPos,
                  radius: AppConfig.maxActionDistanceM.toDouble(),
                  useRadiusInMeter: true,
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderColor: AppColors.primary.withValues(alpha: 0.6),
                  borderStrokeWidth: 1.5,
                ),
              ]),
            if (userPos != null) UserLocationLayer(position: userPos),
            if (!_placing) PinsLayer(onPinTap: _openCooler),
          ],
        ),
        if (_placing)
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 48), // the pin's tip marks the exact centre
                child: PinIcon(
                  pin: CoolerPin(id: 'new', lat: 0, lng: 0, status: CoolerStatus.working),
                  size: 44,
                ),
              ),
            ),
          ),
        if (!_placing)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Column(children: [
                MapSearchBar(
                  onSelected: _onSearchSelected,
                  onAccount: () => ref.read(homeTabProvider.notifier).go(2),
                ),
                const SizedBox(height: 8),
                const _FilterChips(),
                const _LoadingBar(),
              ]),
            ),
          ),
        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _placing
                  ? ValueListenableBuilder<LatLng>(
                      valueListenable: _pinPoint,
                      builder: (_, point, _) => _PlacementCard(
                        range: rangeTo(loc, point),
                        onCancel: () => setState(() => _placing = false),
                        onConfirm: _confirmPlacement,
                        onLocate: _goToMyLocation,
                      ),
                    )
                  : Column(mainAxisSize: MainAxisSize.min, children: [
                      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        _AddCoolerButton(label: l.addCooler, onPressed: _startPlacing),
                        const Spacer(),
                        _SquareFab(
                          icon: Icons.my_location,
                          tooltip: l.myLocation,
                          busy: loc.locating,
                          onPressed: _goToMyLocation,
                        ),
                      ]),
                      const SizedBox(height: 10),
                      const _MapStatusBanner(),
                      NearestCard(onOpen: _openCooler),
                    ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class _FilterChips extends ConsumerWidget {
  const _FilterChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final selected = ref.watch(mapFilterProvider);
    final pins = ref.watch(mapPinsProvider.select((s) => s.pins));
    int count(MapFilter f) => pins.values.where((p) => !p.pending && f.matches(p)).length;

    Widget chip(MapFilter f, String label, {IconData? icon, Color? iconColor}) {
      final on = selected == f;
      return Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: Material(
          color: on ? AppColors.primaryDark : AppColors.surface,
          shape: StadiumBorder(side: BorderSide(color: on ? AppColors.primaryDark : AppColors.line)),
          elevation: 1,
          shadowColor: const Color(0x330F172A),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () => ref.read(mapFilterProvider.notifier).set(f),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: on ? Colors.white : (iconColor ?? AppColors.ink)),
                  const SizedBox(width: 6),
                ],
                Text(
                  '$label (${count(f)})',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: on ? Colors.white : AppColors.ink,
                  ),
                ),
              ]),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          chip(MapFilter.all, l.filterAll, icon: Icons.water_drop_outlined),
          chip(MapFilter.working, l.filterWorking, icon: Icons.circle, iconColor: AppColors.working),
          chip(MapFilter.cups, l.filterCups, icon: Icons.local_cafe_outlined),
          chip(MapFilter.patron, l.filterPatron, icon: Icons.verified_outlined, iconColor: AppColors.patron),
        ],
      ),
    );
  }
}

class _LoadingBar extends ConsumerWidget {
  const _LoadingBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(mapPinsProvider.select((s) => s.loading));
    return AnimatedOpacity(
      opacity: loading ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        child: LinearProgressIndicator(minHeight: 2),
      ),
    );
  }
}

class _AddCoolerButton extends StatelessWidget {
  const _AddCoolerButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.surface,
        elevation: 3,
        shadowColor: const Color(0x330F172A),
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(10, 10, 16, 10),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.primaryDark)),
            ]),
          ),
        ),
      );
}

class _SquareFab extends StatelessWidget {
  const _SquareFab({required this.icon, required this.tooltip, required this.onPressed, this.busy = false});

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Material(
          color: AppColors.surface,
          elevation: 3,
          shadowColor: const Color(0x330F172A),
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: InkWell(
            onTap: busy ? null : onPressed,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: SizedBox(
              width: 52,
              height: 52,
              child: Center(
                child: busy
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(icon, color: AppColors.primaryDark),
              ),
            ),
          ),
        ),
      );
}

/// Offline / error / empty-area messages above the bottom card.
class _MapStatusBanner extends ConsumerWidget {
  const _MapStatusBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = ref.watch(mapPinsProvider.select((s) => s.error));
    final hasPins = ref.watch(mapPinsProvider.select((s) => s.pins.isNotEmpty));
    final loadedOnce = ref.watch(mapPinsProvider.select((s) => s.loadedOnce));

    final l = context.l10n;
    final String? text;
    var showRetry = false;
    if (error != null) {
      text = hasPins ? l.mapOffline : errorText(l, error);
      showRetry = true;
    } else if (loadedOnce && !hasPins) {
      text = l.mapEmpty;
    } else {
      text = null;
    }
    if (text == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 6, 6, 6),
          child: Row(children: [
            Expanded(child: Text(text, style: const TextStyle(color: Colors.white))),
            if (showRetry)
              TextButton(
                onPressed: () => ref.read(mapPinsProvider.notifier).refresh(),
                child: Text(l.retry, style: const TextStyle(color: Colors.white)),
              ),
          ]),
        ),
      ),
    );
  }
}

/// Step 1 of adding a cooler: put the pin on it, within reach of where you stand.
class _PlacementCard extends StatelessWidget {
  const _PlacementCard({
    required this.range,
    required this.onCancel,
    required this.onConfirm,
    required this.onLocate,
  });

  final RangeInfo range;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final VoidCallback onLocate;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final max = AppConfig.maxActionDistanceM;
    final (icon, color, bg, text) = switch (range.range) {
      Range.off => (Icons.place_outlined, AppColors.primaryDark, AppColors.primaryContainer, l.placeFree),
      Range.near => (
          Icons.verified_outlined,
          AppColors.primaryDark,
          AppColors.primaryContainer,
          l.placeInRange(range.meters!.round()),
        ),
      Range.far => (
          Icons.social_distance,
          AppColors.empty,
          AppColors.emptyBg,
          l.placeTooFar(formatDistance(l, range.meters!), max),
        ),
      Range.inaccurate || Range.locating => (
          Icons.gps_not_fixed,
          AppColors.pending,
          AppColors.pendingBg,
          l.rangeLocating,
        ),
      Range.unknown || Range.noPermission => (
          Icons.location_off_outlined,
          AppColors.broken,
          AppColors.brokenBg,
          l.rangeNeedLocation,
        ),
    };
    return AppCard(
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(l.stepOf(1, 2).toUpperCase(),
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: AppColors.primaryDark)),
        const SizedBox(height: 2),
        Text(l.placeTitle, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(l.placePinHint, style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.button)),
          child: Row(children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600))),
            if (range.range == Range.unknown || range.range == Range.noPermission || range.range == Range.inaccurate)
              TextButton(onPressed: onLocate, child: Text(l.retry)),
          ]),
        ),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: range.allowed ? onConfirm : null,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: Text(l.confirmLocation),
        ),
        TextButton(onPressed: onCancel, child: Text(l.cancel)),
      ]),
    );
  }
}
