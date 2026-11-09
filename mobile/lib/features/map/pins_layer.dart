// Cooler markers with clustering. Rebuilds only when the pin set changes, and
// markers are deliberately cheap (no shadows/blur) to stay smooth on
// mid-range phones.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../models/cooler.dart';
import '../../shared/ui.dart';
import 'map_pins_controller.dart';

class PinsLayer extends ConsumerWidget {
  const PinsLayer({super.key, required this.onPinTap});

  final void Function(String coolerId) onPinTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pins = ref.watch(mapPinsProvider.select((s) => s.pins));
    final markers = [
      for (final p in pins.values)
        Marker(
          key: ValueKey(p.id),
          point: LatLng(p.lat, p.lng),
          width: 40,
          height: 40,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onPinTap(p.id),
            child: PinIcon(pin: p),
          ),
        ),
    ];
    return MarkerClusterLayerWidget(
      options: MarkerClusterLayerOptions(
        markers: markers,
        maxClusterRadius: 50,
        disableClusteringAtZoom: 16,
        size: const Size(42, 42),
        zoomToBoundsOnClick: true,
        builder: (context, clustered) => _ClusterBubble(count: clustered.length),
      ),
    );
  }
}

class PinIcon extends StatelessWidget {
  const PinIcon({super.key, required this.pin});

  final CoolerPin pin;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: pin.status.color,
          shape: BoxShape.circle,
          border: Border.all(
            color: pin.sponsored ? AppColors.sponsor : Colors.white,
            width: pin.sponsored ? 3 : 2.5,
          ),
        ),
        child: Icon(pin.status.icon, size: 17, color: Colors.white),
      ),
    );
  }
}

class _ClusterBubble extends StatelessWidget {
  const _ClusterBubble({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
      ),
    );
  }
}

/// The blue "you are here" dot.
class UserLocationLayer extends StatelessWidget {
  const UserLocationLayer({super.key, required this.position});

  final LatLng position;

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(markers: [
      Marker(
        point: position,
        width: 44,
        height: 44,
        child: Stack(alignment: Alignment.center, children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
            ),
          ),
        ]),
      ),
    ]);
  }
}
