import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

enum LocationProblem { serviceDisabled, denied, deniedForever }

class LocationResult {
  const LocationResult.found(LatLng this.position) : problem = null;
  const LocationResult.failed(LocationProblem this.problem) : position = null;
  const LocationResult.unavailable()
      : position = null,
        problem = null;

  final LatLng? position;
  final LocationProblem? problem;
}

class LocationService {
  /// Fast path: last known fix, no permission prompt, never throws.
  Future<LatLng?> lastKnown() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        return null;
      }
      final p = await Geolocator.getLastKnownPosition();
      return p == null ? null : LatLng(p.latitude, p.longitude);
    } catch (_) {
      return null;
    }
  }

  /// Asks for permission if needed, then returns a fix within ~10 s.
  Future<LocationResult> current() async {
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
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return LocationResult.found(LatLng(p.latitude, p.longitude));
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
