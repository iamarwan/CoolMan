// Home screen: the map is the app. Everything else is a sheet over it.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/config.dart';
import '../../core/error_text.dart';
import '../../core/location_service.dart';
import '../../core/providers.dart';
import '../../models/cooler.dart';
import '../../shared/ui.dart';
import '../auth/auth_sheet.dart';
import '../cooler/add_cooler_sheet.dart';
import '../cooler/cooler_sheet.dart';
import '../profile/profile_screen.dart';
import 'bbox.dart';
import 'map_pins_controller.dart';
import 'map_search_bar.dart';
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
    super.dispose();
  }

  // ── Location ─────────────────────────────────────────────────────────────

  Future<void> _initLocation() async {
    final loc = ref.read(userLocationProvider.notifier);
    final last = await loc.warmUp();
    if (!mounted) return;
    if (last != null && !_hadSavedCamera && !_userMovedMap) _moveTo(last, 15);
    final current = await loc.locate();
    if (!mounted) return;
    if (current != null && !_hadSavedCamera && !_userMovedMap) _moveTo(current, 15);
  }

  Future<void> _goToMyLocation() async {
    final pos = await ref.read(userLocationProvider.notifier).locate();
    if (!mounted) return;
    if (pos != null) {
      _moveTo(pos, 16);
      return;
    }
    final problem = ref.read(userLocationProvider).problem;
    final service = ref.read(locationServiceProvider);
    final (message, action) = switch (problem) {
      LocationProblem.serviceDisabled => ('Location is turned off.', service.openSettings),
      LocationProblem.deniedForever => ('Location permission is blocked.', service.openAppSettings),
      LocationProblem.denied => ('Location permission was denied.', null),
      null => ('Could not find your location. Try again outside.', null),
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      action: action == null ? null : SnackBarAction(label: 'Settings', onPressed: action),
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

  Future<void> _openProfile() async {
    if (!await ensureLoggedIn(context, ref) || !mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
  }

  // ── Adding a cooler ──────────────────────────────────────────────────────

  Future<void> _startPlacing() async {
    if (!await ensureLoggedIn(context, ref) || !mounted) return;
    setState(() => _placing = true);
  }

  Future<void> _addAt(LatLng point) async {
    setState(() => _placing = false);
    if (!await ensureLoggedIn(context, ref) || !mounted) return;
    final cooler = await showAddCoolerSheet(context, point);
    if (cooler == null || !mounted) return;
    showSnack(
      context,
      cooler.isApproved
          ? 'Cooler added and live on the map. +50 points'
          : 'Submitted! It will appear after review (+50 points when approved).',
    );
  }

  // ── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final userPos = ref.watch(userLocationProvider.select((s) => s.position));
    final locating = ref.watch(userLocationProvider.select((s) => s.locating));

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
            onLongPress: (_, point) => _addAt(point),
          ),
          children: [
            TileLayer(
              urlTemplate: AppConfig.tileUrlTemplate,
              userAgentPackageName: AppConfig.userAgentPackageName,
              maxNativeZoom: 19,
            ),
            if (userPos != null) UserLocationLayer(position: userPos),
            if (!_placing) PinsLayer(onPinTap: _openCooler),
          ],
        ),
        if (_placing)
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 44), // pin tip at the exact centre
                child: Icon(Icons.location_on, size: 48, color: AppColors.primary),
              ),
            ),
          ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Column(children: [
              MapSearchBar(
                onSelected: _onSearchSelected,
                onProfile: _openProfile,
              ),
              const _LoadingBar(),
            ]),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _placing
                  ? _PlacementCard(
                      onCancel: () => setState(() => _placing = false),
                      onConfirm: () => _addAt(_map.camera.center),
                    )
                  : Column(mainAxisSize: MainAxisSize.min, children: [
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: FloatingActionButton.small(
                          heroTag: 'locate',
                          onPressed: locating ? null : _goToMyLocation,
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          tooltip: 'My location',
                          child: locating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.my_location),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const _MapStatusBanner(),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: FloatingActionButton.extended(
                          heroTag: 'add',
                          onPressed: _startPlacing,
                          icon: const Icon(Icons.add_location_alt_outlined),
                          label: const Text('Add cooler'),
                        ),
                      ),
                    ]),
            ),
          ),
        ),
      ]),
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
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        child: LinearProgressIndicator(minHeight: 2),
      ),
    );
  }
}

/// Offline / error / empty-area messages above the add button.
class _MapStatusBanner extends ConsumerWidget {
  const _MapStatusBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = ref.watch(mapPinsProvider.select((s) => s.error));
    final hasPins = ref.watch(mapPinsProvider.select((s) => s.pins.isNotEmpty));
    final loadedOnce = ref.watch(mapPinsProvider.select((s) => s.loadedOnce));

    final String? text;
    var showRetry = false;
    if (error != null) {
      text = hasPins ? 'Offline: showing saved coolers.' : errorText(error);
      showRetry = true;
    } else if (loadedOnce && !hasPins) {
      text = 'No coolers here yet. Be the first to add one!';
    } else {
      text = null;
    }
    if (text == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 6, 6, 6),
          child: Row(children: [
            Expanded(child: Text(text, style: const TextStyle(color: Colors.white))),
            if (showRetry)
              TextButton(
                onPressed: () => ref.read(mapPinsProvider.notifier).refresh(),
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
          ]),
        ),
      ),
    );
  }
}

class _PlacementCard extends StatelessWidget {
  const _PlacementCard({required this.onCancel, required this.onConfirm});

  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Move the map to put the pin on the cooler',
                style: TextStyle(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: onCancel, child: const Text('Cancel'))),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(onPressed: onConfirm, child: const Text('Confirm location')),
              ),
            ]),
          ]),
        ),
      );
}
