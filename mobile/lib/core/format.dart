import 'package:latlong2/latlong.dart';

import '../l10n/app_localizations.dart';

const _distance = Distance();

String timeAgo(AppLocalizations l, DateTime t, {DateTime? now}) {
  final d = (now ?? DateTime.now()).difference(t);
  if (d.inMinutes < 1) return l.timeJustNow;
  if (d.inMinutes < 60) return l.timeMinutesAgo(d.inMinutes);
  if (d.inHours < 24) return l.timeHoursAgo(d.inHours);
  if (d.inDays < 7) return l.timeDaysAgo(d.inDays);
  if (d.inDays < 35) return l.timeWeeksAgo(d.inDays ~/ 7);
  return l.timeMonthsAgo(d.inDays ~/ 30);
}

/// How much to trust a status, based on when it was last confirmed.
enum Freshness { fresh, aging, stale }

Freshness freshnessOf(DateTime lastVerified, {DateTime? now}) {
  final days = (now ?? DateTime.now()).difference(lastVerified).inDays;
  if (days <= 3) return Freshness.fresh;
  if (days <= 14) return Freshness.aging;
  return Freshness.stale;
}

double metersBetween(LatLng a, LatLng b) => _distance.as(LengthUnit.Meter, a, b);

/// Exact metres when close (it matters for the 50 m rule), rounded farther out.
String formatDistance(AppLocalizations l, double meters) {
  if (meters < 100) return l.distanceMeters(meters.round());
  if (meters < 1000) return l.distanceMeters((meters / 10).round() * 10);
  return l.distanceKm((meters / 1000).toStringAsFixed(1));
}

/// Walking at ~80 m per minute.
String walkingTime(AppLocalizations l, double meters) {
  final min = (meters / 80).ceil();
  return min < 60 ? l.walkMinutes(min) : l.walkHours((min / 60).toStringAsFixed(1));
}
