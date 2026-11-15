import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/config.dart';
import '../../core/format.dart';
import '../../core/location_service.dart';
import '../../core/providers.dart';

@immutable
class UserLocationState {
  const UserLocationState({this.fix, this.problem, this.locating = false});

  final Fix? fix;
  final LocationProblem? problem;
  final bool locating;

  LatLng? get position => fix?.position;
}

/// Where the user stands relative to a spot, for the "be there" rule.
enum Range { off, near, far, inaccurate, locating, unknown, noPermission }

class RangeInfo {
  const RangeInfo(this.range, [this.meters]);

  final Range range;
  final double? meters;

  /// True when the app should let the user contribute.
  bool get allowed => range == Range.off || range == Range.near;
}

/// Pure rule, shared by the cooler sheet and the add-cooler pin.
RangeInfo rangeTo(UserLocationState s, LatLng target, {int maxMeters = AppConfig.maxActionDistanceM}) {
  final fix = s.fix;
  final meters = fix == null ? null : metersBetween(fix.position, target);
  if (maxMeters <= 0) return RangeInfo(Range.off, meters);
  if (fix == null) {
    if (s.locating) return const RangeInfo(Range.locating);
    if (s.problem != null) return const RangeInfo(Range.noPermission);
    return const RangeInfo(Range.unknown);
  }
  if (meters! > maxMeters) return RangeInfo(Range.far, meters);
  if (fix.accuracyM != null && fix.accuracyM! > AppConfig.maxGpsAccuracyM) {
    return RangeInfo(s.locating ? Range.locating : Range.inaccurate, meters);
  }
  return RangeInfo(Range.near, meters);
}

class UserLocationController extends Notifier<UserLocationState> {
  @override
  UserLocationState build() => const UserLocationState();

  LocationService get _service => ref.read(locationServiceProvider);

  /// Quick, silent attempt (no permission prompt).
  Future<LatLng?> warmUp() async {
    final last = await _service.lastKnown();
    if (last != null && ref.mounted && state.fix == null) {
      state = UserLocationState(fix: last);
    }
    return last?.position;
  }

  /// Full attempt (may prompt for permission). Returns the new fix if found.
  Future<Fix?> locate({bool precise = false}) async {
    state = UserLocationState(fix: state.fix, locating: true);
    final result = await _service.current(precise: precise);
    if (!ref.mounted) return null;
    state = UserLocationState(fix: result.fix ?? state.fix, problem: result.problem);
    return result.fix;
  }
}

final userLocationProvider =
    NotifierProvider<UserLocationController, UserLocationState>(UserLocationController.new);
