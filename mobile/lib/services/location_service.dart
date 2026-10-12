import 'dart:async';

import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Resolves a fix without blocking indefinitely (emulators often stall on
  /// high-accuracy GPS). Uses last-known when available, then a bounded wait.
  Future<Position?> resolveCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceDisabledException();
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationPermissionDeniedException();
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationPermissionPermanentlyDeniedException();
    }

    final cached = await Geolocator.getLastKnownPosition();
    if (cached != null) {
      return cached;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 12),
      );
    } on TimeoutException {
      return null;
    }
  }
}

class LocationServiceDisabledException implements Exception {
  final String message = 'Location services are disabled.';
}

class LocationPermissionDeniedException implements Exception {
  final String message = 'Location permission denied. Showing default area.';
}

class LocationPermissionPermanentlyDeniedException implements Exception {
  final String message = 'Location permission permanently denied.';
}
