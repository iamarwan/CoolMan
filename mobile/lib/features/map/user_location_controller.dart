import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/location_service.dart';
import '../../core/providers.dart';

@immutable
class UserLocationState {
  const UserLocationState({this.position, this.problem, this.locating = false});

  final LatLng? position;
  final LocationProblem? problem;
  final bool locating;
}

class UserLocationController extends Notifier<UserLocationState> {
  @override
  UserLocationState build() => const UserLocationState();

  LocationService get _service => ref.read(locationServiceProvider);

  /// Quick, silent attempt (no permission prompt).
  Future<LatLng?> warmUp() async {
    final last = await _service.lastKnown();
    if (last != null && ref.mounted && state.position == null) {
      state = UserLocationState(position: last);
    }
    return last;
  }

  /// Full attempt (may prompt for permission). Returns the position if found.
  Future<LatLng?> locate() async {
    state = UserLocationState(position: state.position, locating: true);
    final result = await _service.current();
    if (!ref.mounted) return null;
    state = UserLocationState(
      position: result.position ?? state.position,
      problem: result.problem,
    );
    return result.position;
  }
}

final userLocationProvider =
    NotifierProvider<UserLocationController, UserLocationState>(UserLocationController.new);
