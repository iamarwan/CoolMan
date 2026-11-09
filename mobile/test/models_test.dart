import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:sabil/core/format.dart';
import 'package:sabil/l10n/app_localizations.dart';
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

  test('time and distance formatting in English', () {
    final l = lookupAppLocalizations(const Locale('en'));
    final now = DateTime(2026, 11, 9, 12);
    expect(timeAgo(l, now.subtract(const Duration(seconds: 20)), now: now), 'just now');
    expect(timeAgo(l, now.subtract(const Duration(minutes: 25)), now: now), '25 min ago');
    expect(timeAgo(l, now.subtract(const Duration(days: 2)), now: now), '2 days ago');
    expect(freshnessOf(now.subtract(const Duration(days: 20)), now: now), Freshness.stale);
    expect(formatDistance(l, 123), '120 m');
    expect(formatDistance(l, 2500), '2.5 km');
    expect(walkingTime(l, 160), '2 min walk');
  });

  test('Arabic uses correct plural forms', () {
    final l = lookupAppLocalizations(const Locale('ar'));
    final now = DateTime(2026, 11, 9, 12);
    String ago(Duration d) => timeAgo(l, now.subtract(d), now: now);
    expect(ago(const Duration(minutes: 1)), 'منذ دقيقة');
    expect(ago(const Duration(minutes: 2)), 'منذ دقيقتين');
    expect(ago(const Duration(minutes: 5)), 'منذ 5 دقائق');
    expect(ago(const Duration(minutes: 25)), 'منذ 25 دقيقة');
    expect(ago(const Duration(days: 3)), 'منذ 3 أيام');
    expect(formatDistance(l, 2500), '2.5 كم');
    expect(l.sponsorCoolerCount(2), 'مبردان');
  });
}
