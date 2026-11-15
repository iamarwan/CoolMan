import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:sabil/core/location_service.dart';
import 'package:sabil/features/map/map_filter.dart';
import 'package:sabil/features/map/nearest_card.dart';
import 'package:sabil/features/map/user_location_controller.dart';
import 'package:sabil/models/cooler.dart';

import 'fakes.dart';

const cooler = LatLng(29.96, 31.25);

UserLocationState at(double lat, double lng, {double? accuracy, bool locating = false}) => UserLocationState(
      fix: Fix(LatLng(lat, lng), accuracy, DateTime(2026)),
      locating: locating,
    );

void main() {
  group('the 50 m rule', () {
    test('near with good GPS is allowed', () {
      final r = rangeTo(at(29.9601, 31.25005, accuracy: 10), cooler);
      expect(r.range, Range.near);
      expect(r.allowed, isTrue);
      expect(r.meters, closeTo(12, 3));
    });

    test('far is refused and reports the distance', () {
      final r = rangeTo(at(29.962, 31.25, accuracy: 10), cooler);
      expect(r.range, Range.far);
      expect(r.allowed, isFalse);
      expect(r.meters, closeTo(222, 5));
    });

    test('close but with poor GPS accuracy is refused until it improves', () {
      expect(rangeTo(at(29.9601, 31.25005, accuracy: 90), cooler).range, Range.inaccurate);
      expect(rangeTo(at(29.9601, 31.25005, accuracy: 90, locating: true), cooler).range, Range.locating);
    });

    test('no position: waiting, unknown or needs permission', () {
      expect(rangeTo(const UserLocationState(locating: true), cooler).range, Range.locating);
      expect(rangeTo(const UserLocationState(), cooler).range, Range.unknown);
      expect(rangeTo(const UserLocationState(problem: LocationProblem.denied), cooler).range, Range.noPermission);
    });

    test('rule switched off allows everything', () {
      expect(rangeTo(const UserLocationState(), cooler, maxMeters: 0).allowed, isTrue);
      expect(rangeTo(at(31, 31), cooler, maxMeters: 0).allowed, isTrue);
    });
  });

  test('nearest working cooler ignores broken, empty and pending ones', () {
    final pins = [
      pin('broken-closest', 29.9601, 31.25, CoolerStatus.broken),
      const CoolerPin(id: 'pending', lat: 29.96005, lng: 31.25, status: CoolerStatus.working, pending: true),
      pin('working-near', 29.961, 31.25),
      pin('working-far', 29.97, 31.25),
    ];
    final n = nearestWorking(pins, cooler)!;
    expect(n.pin.id, 'working-near');
    expect(n.meters, closeTo(111, 5));
    expect(nearestWorking([pin('other-city', 31.2, 29.9)], cooler), isNull);
  });

  test('map filters', () {
    const cups = CoolerPin(id: 'a', lat: 0, lng: 0, status: CoolerStatus.empty, hasCups: true);
    const patron = CoolerPin(id: 'b', lat: 0, lng: 0, status: CoolerStatus.working, sponsored: true);
    const mine = CoolerPin(id: 'c', lat: 0, lng: 0, status: CoolerStatus.broken, pending: true);
    expect(MapFilter.working.matches(cups), isFalse);
    expect(MapFilter.cups.matches(cups), isTrue);
    expect(MapFilter.patron.matches(patron), isTrue);
    expect(MapFilter.patron.matches(cups), isFalse);
    // Your own cooler in review is always shown.
    expect(MapFilter.working.matches(mine), isTrue);
  });
}
