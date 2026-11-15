// Map data flow (stale-while-revalidate, viewport-based):
//  1. On start, show the pins saved from the last session instantly.
//  2. When the map stops moving, fetch pins for the visible area (+50% margin)
//     unless that area was fetched recently.
//  3. Merge: pins inside the fetched area are replaced (so deleted coolers
//     disappear), pins elsewhere are kept.
//  4. Older responses that arrive late are ignored.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/api_client.dart';
import '../../core/providers.dart';
import '../../models/cooler.dart';
import '../cooler/cooler_repository.dart';
import 'bbox.dart';

const _pinsCacheKey = 'map.pins.v1';
const _cameraCacheKey = 'map.camera.v1';
const _maxPinsInMemory = 3000;
const _maxPinsCached = 800;
const _refetchAfter = Duration(minutes: 2);

@immutable
class MapPinsState {
  const MapPinsState({
    this.pins = const {},
    this.loading = false,
    this.error,
    this.truncated = false,
    this.loadedOnce = false,
  });

  final Map<String, CoolerPin> pins;
  final bool loading;
  final ApiException? error;
  final bool truncated;

  /// True once at least one network load succeeded this session.
  final bool loadedOnce;

  MapPinsState copyWith({
    Map<String, CoolerPin>? pins,
    bool? loading,
    ApiException? error,
    bool clearError = false,
    bool? truncated,
    bool? loadedOnce,
  }) =>
      MapPinsState(
        pins: pins ?? this.pins,
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
        truncated: truncated ?? this.truncated,
        loadedOnce: loadedOnce ?? this.loadedOnce,
      );
}

/// Replaces pins inside [area] with [fresh]; keeps the rest (bounded in size).
Map<String, CoolerPin> mergePins(
  Map<String, CoolerPin> existing,
  Bbox area,
  List<CoolerPin> fresh,
) {
  final merged = <String, CoolerPin>{
    for (final p in existing.values)
      if (!area.containsPoint(p.lat, p.lng)) p.id: p,
  };
  if (merged.length + fresh.length > _maxPinsInMemory) {
    final near = area.expand(1.0);
    merged.removeWhere((_, p) => !near.containsPoint(p.lat, p.lng));
  }
  for (final p in fresh) {
    merged[p.id] = p;
  }
  return merged;
}

class CameraSnapshot {
  const CameraSnapshot(this.center, this.zoom);

  final LatLng center;
  final double zoom;
}

class MapPinsController extends Notifier<MapPinsState> {
  Timer? _debounce;
  Bbox? _lastFetched;
  DateTime? _lastFetchAt;
  Bbox? _lastVisible;
  int _requestSeq = 0;

  @override
  MapPinsState build() {
    ref.onDispose(() => _debounce?.cancel());
    return MapPinsState(pins: _readCachedPins());
  }

  /// Last camera position from the previous session, if any.
  CameraSnapshot? cachedCamera() {
    final j = ref.read(cacheStoreProvider).readJson(_cameraCacheKey);
    if (j is! Map) return null;
    final lat = j['lat'], lng = j['lng'], zoom = j['zoom'];
    if (lat is! num || lng is! num || zoom is! num) return null;
    return CameraSnapshot(LatLng(lat.toDouble(), lng.toDouble()), zoom.toDouble());
  }

  /// Called whenever the map moves. Debounced so panning stays smooth.
  void onCameraChanged(Bbox visible, LatLng center, double zoom, {bool immediate = false}) {
    _lastVisible = visible;
    _debounce?.cancel();
    _debounce = Timer(immediate ? Duration.zero : const Duration(milliseconds: 350), () {
      ref.read(cacheStoreProvider).writeJson(
        _cameraCacheKey,
        {'lat': center.latitude, 'lng': center.longitude, 'zoom': zoom},
      );
      _load(visible);
    });
  }

  Future<void> refresh() async {
    final visible = _lastVisible;
    if (visible != null) await _load(visible, force: true);
  }

  Future<void> _load(Bbox visible, {bool force = false}) async {
    final fresh = _lastFetchAt != null && DateTime.now().difference(_lastFetchAt!) < _refetchAfter;
    if (!force && fresh && (_lastFetched?.containsBox(visible) ?? false)) return;

    final area = visible.expand(0.5);
    final seq = ++_requestSeq;
    state = state.copyWith(loading: true);
    try {
      final result = await ref.read(coolerRepositoryProvider).pins(area);
      if (!ref.mounted || seq != _requestSeq) return;
      _lastFetched = area;
      _lastFetchAt = DateTime.now();
      final merged = mergePins(state.pins, area, result.pins);
      state = state.copyWith(
        pins: merged,
        loading: false,
        clearError: true,
        truncated: result.truncated,
        loadedOnce: true,
      );
      _saveCachedPins(merged, visible.expand(2));
    } on ApiException catch (e) {
      if (!ref.mounted || seq != _requestSeq) return;
      state = state.copyWith(loading: false, error: e);
    }
  }

  /// Optimistic local updates.
  void upsert(CoolerPin pin) => state = state.copyWith(pins: {...state.pins, pin.id: pin});

  void setStatus(String id, CoolerStatus status) {
    final pin = state.pins[id];
    if (pin != null && pin.status != status) upsert(pin.copyWith(status: status));
  }

  void remove(String id) {
    if (!state.pins.containsKey(id)) return;
    state = state.copyWith(pins: {...state.pins}..remove(id));
  }

  Map<String, CoolerPin> _readCachedPins() {
    final j = ref.read(cacheStoreProvider).readJson(_pinsCacheKey);
    if (j is! List) return const {};
    final pins = <String, CoolerPin>{};
    for (final item in j) {
      try {
        final p = CoolerPin.fromJson(Map<String, dynamic>.from(item as Map));
        pins[p.id] = p;
      } catch (_) {}
    }
    return pins;
  }

  void _saveCachedPins(Map<String, CoolerPin> pins, Bbox near) {
    final list = [
      for (final p in pins.values)
        if (near.containsPoint(p.lat, p.lng)) p.toJson(),
    ].take(_maxPinsCached).toList();
    ref.read(cacheStoreProvider).writeJson(_pinsCacheKey, list);
  }
}

final mapPinsProvider = NotifierProvider<MapPinsController, MapPinsState>(MapPinsController.new);
