import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/cooler.dart';

enum MapFilter { all, working, cups, patron }

extension MapFilterMatch on MapFilter {
  /// A user's own pending cooler is always shown, whatever the filter.
  bool matches(CoolerPin p) => p.pending || switch (this) {
        MapFilter.all => true,
        MapFilter.working => p.status == CoolerStatus.working,
        MapFilter.cups => p.hasCups == true,
        MapFilter.patron => p.sponsored,
      };
}

class MapFilterController extends Notifier<MapFilter> {
  @override
  MapFilter build() => MapFilter.all;

  void set(MapFilter f) => state = f;
}

final mapFilterProvider = NotifierProvider<MapFilterController, MapFilter>(MapFilterController.new);
