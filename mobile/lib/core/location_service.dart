import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

enum LocationProblem { serviceDisabled, denied, deniedForever }

/// A position with how sure the phone is about it.
class Fix {
  const Fix(this.position, this.accuracyM, this.time);

  final LatLng position;

  /// Estimated error in metres (smaller is better); null if unknown.
  final double? accuracyM;
  final DateTime time;

  Map<String, Object?> toJson() => {
        'lat': position.latitude,
        'lng': position.longitude,
        if (accuracyM != null) 'accuracy': accuracyM,
      };
}

class LocationResult {
  const LocationResult.found(Fix this.fix) : problem = null;
  const LocationResult.failed(LocationProblem this.problem) : fix = null;
  const LocationResult.unavailable()
      : fix = null,
        problem = null;

  final Fix? fix;
  final LocationProblem? problem;
}

class LocationService {
  Fix _fix(Position p) => Fix(LatLng(p.latitude, p.longitude), p.accuracy, p.timestamp);

  /// Fast path: last known fix, no permission prompt, never throws.
  Future<Fix?> lastKnown() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        return null;
      }
      final p = await Geolocator.getLastKnownPosition();
      return p == null ? null : _fix(p);
    } catch (_) {
      return null;
    }
  }

  /// Asks for permission if needed, then returns a fresh fix within ~10 s.
  /// [precise] asks the phone for its best accuracy (used for the 50 m rule).
  Future<LocationResult> current({bool precise = false}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationResult.failed(LocationProblem.serviceDisabled);
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        return const LocationResult.failed(LocationProblem.deniedForever);
      }
      if (perm == LocationPermission.denied) {
        return const LocationResult.failed(LocationProblem.denied);
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: precise ? LocationAccuracy.best : LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        ),
      );
      return LocationResult.found(_fix(p));
    } on TimeoutException {
      final last = await lastKnown();
      return last == null ? const LocationResult.unavailable() : LocationResult.found(last);
    } catch (_) {
      return const LocationResult.unavailable();
    }
  }

  Future<void> openSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (_) {}
  }

  Future<void> openAppSettings() async {
    try {
      await Geolocator.openAppSettings();
    } catch (_) {}
  }
}
