// Cooler markers with clustering. Only this layer rebuilds when pins or the
// filter change, and markers are cheap to draw (one painted shape, no shadows).

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../../models/cooler.dart';
import '../../shared/ui.dart';
import 'map_filter.dart';
import 'map_pins_controller.dart';

class PinsLayer extends ConsumerWidget {
  const PinsLayer({super.key, required this.onPinTap});

  final void Function(String coolerId) onPinTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pins = ref.watch(mapPinsProvider.select((s) => s.pins));
    final filter = ref.watch(mapFilterProvider);
    final markers = [
      for (final p in pins.values)
        if (filter.matches(p))
          Marker(
            key: ValueKey(p.id),
            point: LatLng(p.lat, p.lng),
            width: 40,
            height: 48,
            alignment: Alignment.topCenter, // the pin's tip touches the spot
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
        size: const Size(44, 44),
        zoomToBoundsOnClick: true,
        builder: (context, clustered) => _ClusterBubble(count: clustered.length),
      ),
    );
  }
}

({Color color, IconData icon}) pinStyle(CoolerPin pin) {
  if (pin.pending) return (color: AppColors.pending, icon: Icons.schedule);
  return (color: pin.status.color, icon: pin.status.icon);
}

/// Teardrop pin: status colour and icon; a purple ring marks a patron's cooler.
class PinIcon extends StatelessWidget {
  const PinIcon({super.key, required this.pin, this.size = 40});

  final CoolerPin pin;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = pinStyle(pin);
    return CustomPaint(
      size: Size(size, size * 1.2),
      painter: _PinPainter(
        fill: style.color,
        ring: pin.sponsored && !pin.pending ? AppColors.patron : Colors.white,
      ),
      child: SizedBox(
        width: size,
        height: size * 1.2,
        child: Align(
          alignment: const Alignment(0, -0.42),
          child: Icon(style.icon, size: size * 0.45, color: Colors.white),
        ),
      ),
    );
  }
}

class _PinPainter extends CustomPainter {
  _PinPainter({required this.fill, required this.ring});

  final Color fill;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final head = Offset(r, r);
    final tip = Path()
      ..moveTo(r - r * 0.42, r + r * 0.72)
      ..lineTo(r, size.height)
      ..lineTo(r + r * 0.42, r + r * 0.72)
      ..close();
    final ringPaint = Paint()..color = ring;
    canvas.drawPath(tip, ringPaint);
    canvas.drawCircle(head, r, ringPaint);
    canvas.drawCircle(head, r - 3, Paint()..color = fill);
  }

  @override
  bool shouldRepaint(_PinPainter old) => old.fill != fill || old.ring != ring;
}

class _ClusterBubble extends StatelessWidget {
  const _ClusterBubble({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
      ),
    );
  }
}

/// The "you are here" dot.
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
              color: AppColors.primary.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
          ),
        ]),
      ),
    ]);
  }
}
