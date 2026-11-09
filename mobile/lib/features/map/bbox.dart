import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';

/// Geographic bounding box (degrees).
class Bbox {
  const Bbox({required this.south, required this.west, required this.north, required this.east});

  final double south;
  final double west;
  final double north;
  final double east;

  factory Bbox.fromBounds(LatLngBounds b) =>
      Bbox(south: b.south, west: b.west, north: b.north, east: b.east);

  bool containsBox(Bbox o) =>
      o.south >= south && o.north <= north && o.west >= west && o.east <= east;

  bool containsPoint(double lat, double lng) =>
      lat >= south && lat <= north && lng >= west && lng <= east;

  /// Grows the box by [factor] of its size on every side (clamped to the world).
  Bbox expand(double factor) {
    final dLat = (north - south) * factor;
    final dLng = (east - west) * factor;
    return Bbox(
      south: math.max(-90, south - dLat),
      north: math.min(90, north + dLat),
      west: math.max(-180, west - dLng),
      east: math.min(180, east + dLng),
    );
  }

  Map<String, Object> toQuery() =>
      {'min_lat': south, 'min_lng': west, 'max_lat': north, 'max_lng': east};
}
