import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:sabil/core/api_client.dart';
import 'package:sabil/core/cache_store.dart';
import 'package:sabil/features/map/bbox.dart';
import 'package:sabil/features/map/map_pins_controller.dart';
import 'package:sabil/models/cooler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

const box = Bbox(south: 29.9, west: 31.2, north: 30.0, east: 31.3);

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  group('Bbox', () {
    test('contains and expands (clamped to the world)', () {
      expect(box.containsBox(const Bbox(south: 29.95, west: 31.22, north: 29.99, east: 31.28)), isTrue);
      expect(box.containsBox(const Bbox(south: 29.8, west: 31.22, north: 29.99, east: 31.28)), isFalse);
      final big = box.expand(0.5);
      expect(big.south, closeTo(29.85, 1e-9));
      expect(big.east, closeTo(31.35, 1e-9));
      expect(const Bbox(south: -89, west: -179, north: 89, east: 179).expand(1).north, 90);
    });
  });

  test('mergePins replaces pins inside the area and keeps the rest', () {
    final existing = {
      'in-old': pin('in-old', 29.95, 31.25),
      'out': pin('out', 31.0, 31.25),
    };
    final merged = mergePins(existing, box, [pin('in-new', 29.96, 31.26)]);
    expect(merged.keys, unorderedEquals(['out', 'in-new']));
  });

  group('MapPinsController', () {
    late FakeCoolerRepository repo;
    late ProviderContainer container;

    setUp(() {
      repo = FakeCoolerRepository();
      container = ProviderContainer(overrides: baseOverrides(repo));
    });
    tearDown(() => container.dispose());

    void move(Bbox b) => container
        .read(mapPinsProvider.notifier)
        .onCameraChanged(b, const LatLng(29.95, 31.25), 15, immediate: true);

    test('loads pins for the visible area plus margin', () async {
      repo.pinResponses.add(() async => (pins: [pin('a', 29.95, 31.25)], truncated: false));
      move(box);
      await settle();
      final s = container.read(mapPinsProvider);
      expect(s.pins.keys, ['a']);
      expect(s.loadedOnce, isTrue);
      expect(repo.pinRequests.single.south, lessThan(box.south));
    });

    test('does not refetch when panning inside the loaded area', () async {
      repo.pinResponses.add(() async => (pins: <CoolerPin>[], truncated: false));
      move(box);
      await settle();
      move(const Bbox(south: 29.92, west: 31.22, north: 29.98, east: 31.28));
      await settle();
      expect(repo.pinRequests, hasLength(1));
    });

    test('a slow older response cannot overwrite a newer one', () async {
      repo.pinResponses
        ..add(() => Future.delayed(const Duration(milliseconds: 60),
            () => (pins: [pin('old', 29.95, 31.25)], truncated: false)))
        ..add(() async => (pins: [pin('new', 40.05, 31.25)], truncated: false));
      move(box);
      await settle();
      move(const Bbox(south: 40.0, west: 31.2, north: 40.1, east: 31.3));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(container.read(mapPinsProvider).pins.keys, ['new']);
    });

    test('errors keep existing pins and expose the error', () async {
      repo.pinResponses
        ..add(() async => (pins: [pin('a', 29.95, 31.25)], truncated: false))
        ..add(() async => throw const ApiException('offline', 'No connection'));
      move(box);
      await settle();
      await container.read(mapPinsProvider.notifier).refresh();
      final s = container.read(mapPinsProvider);
      expect(s.pins.keys, ['a']);
      expect(s.error?.code, 'offline');
    });

    test('optimistic status change and removal', () {
      final c = container.read(mapPinsProvider.notifier)..upsert(pin('a', 29.95, 31.25));
      c.setStatus('a', CoolerStatus.empty);
      expect(container.read(mapPinsProvider).pins['a']!.status, CoolerStatus.empty);
      c.remove('a');
      expect(container.read(mapPinsProvider).pins, isEmpty);
    });
  });

  test('pins and camera survive a restart via the cache', () async {
    SharedPreferences.setMockInitialValues({});
    final cache = CacheStore(await SharedPreferences.getInstance());

    final repo1 = FakeCoolerRepository()
      ..pinResponses.add(() async => (pins: [pin('a', 29.95, 31.25)], truncated: false));
    final first = ProviderContainer(overrides: baseOverrides(repo1, cache: cache));
    first.read(mapPinsProvider.notifier)
        .onCameraChanged(box, const LatLng(29.95, 31.25), 15, immediate: true);
    await settle();
    first.dispose();

    final second = ProviderContainer(overrides: baseOverrides(FakeCoolerRepository(), cache: cache));
    expect(second.read(mapPinsProvider).pins.keys, ['a']);
    final cam = second.read(mapPinsProvider.notifier).cachedCamera();
    expect(cam?.zoom, 15);
    second.dispose();
  });
}
