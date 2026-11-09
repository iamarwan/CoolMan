import 'package:flutter_test/flutter_test.dart';
import 'package:sabil/core/format.dart';
import 'package:sabil/models/cooler.dart';

void main() {
  test('Cooler.fromJson tolerates missing and unknown fields', () {
    final c = Cooler.fromJson({
      'id': 'x',
      'name': 'مسجد التوحيد',
      'latitude': 29.96,
      'longitude': 31.25,
      'status': 'SomethingNew',
      'last_verified_at': '2026-11-09T10:00:00Z',
      'created_at': null,
      'photos': [
        {'id': 'p', 'file_path': '/uploads/photos/a.jpg', 'thumb_path': '/uploads/photos/a_t.jpg', 'is_approved': true, 'photo_category': 'Cups'},
        'garbage',
      ],
    });
    expect(c.status, CoolerStatus.working);
    expect(c.photos.single.category, PhotoCategory.cups);
    expect(c.pendingStatus, isNull);
    expect(c.toPin().sponsored, isFalse);
  });

  test('CoolerPin json round-trip', () {
    const p = CoolerPin(id: 'a', lat: 1, lng: 2, status: CoolerStatus.broken, hasCups: true, sponsored: true);
    final back = CoolerPin.fromJson(p.toJson());
    expect([back.id, back.lat, back.lng, back.status, back.hasCups, back.sponsored],
        ['a', 1.0, 2.0, CoolerStatus.broken, true, true]);
  });

  test('time and distance formatting', () {
    final now = DateTime(2026, 11, 9, 12);
    expect(timeAgo(now.subtract(const Duration(seconds: 20)), now: now), 'just now');
    expect(timeAgo(now.subtract(const Duration(minutes: 25)), now: now), '25 min ago');
    expect(timeAgo(now.subtract(const Duration(days: 2)), now: now), '2 days ago');
    expect(freshnessOf(now.subtract(const Duration(days: 20)), now: now), Freshness.stale);
    expect(formatDistance(123), '120 m');
    expect(formatDistance(2500), '2.5 km');
    expect(walkingTime(160), '2 min walk');
  });
}
