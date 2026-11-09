import 'package:latlong2/latlong.dart';

const _distance = Distance();

String timeAgo(DateTime t, {DateTime? now}) {
  final d = (now ?? DateTime.now()).difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 24) return '${d.inHours} h ago';
  if (d.inDays < 7) return '${d.inDays} ${d.inDays == 1 ? 'day' : 'days'} ago';
  final weeks = d.inDays ~/ 7;
  if (weeks < 5) return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
  return '${d.inDays ~/ 30} mo ago';
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

String formatDistance(double meters) =>
    meters < 1000 ? '${(meters / 10).round() * 10} m' : '${(meters / 1000).toStringAsFixed(1)} km';

/// Walking at ~80 m per minute.
String walkingTime(double meters) {
  final min = (meters / 80).ceil();
  return min < 60 ? '$min min walk' : '${(min / 60).toStringAsFixed(1)} h walk';
}
