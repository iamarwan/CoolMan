// The card at the bottom of the map: the nearest working cooler, with its
// distance and a one-tap route to it. This is the reason most people open the app.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/directions.dart';
import '../../core/format.dart';
import '../../core/locale.dart';
import '../../models/cooler.dart';
import '../../shared/ui.dart';
import '../cooler/cooler_repository.dart';
import 'map_pins_controller.dart';
import 'user_location_controller.dart';

/// Coolers farther than this are not offered as "nearest".
const _maxNearestMeters = 5000.0;

/// Nearest working cooler to [from] among [pins], or null.
({CoolerPin pin, double meters})? nearestWorking(Iterable<CoolerPin> pins, LatLng from) {
  CoolerPin? best;
  var bestMeters = double.infinity;
  for (final p in pins) {
    if (p.pending || p.status != CoolerStatus.working) continue;
    final m = metersBetween(from, LatLng(p.lat, p.lng));
    if (m < bestMeters) {
      best = p;
      bestMeters = m;
    }
  }
  if (best == null || bestMeters > _maxNearestMeters) return null;
  return (pin: best, meters: bestMeters);
}

/// Name of a cooler, loaded once and kept (pins carry no names to stay small).
final coolerNameProvider = FutureProvider.family<String, String>(
  (ref, id) async => (await ref.watch(coolerRepositoryProvider).detail(id)).name,
);

class NearestCard extends ConsumerWidget {
  const NearestCard({super.key, required this.onOpen});

  final void Function(String coolerId) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final from = ref.watch(userLocationProvider.select((s) => s.position));
    final pins = ref.watch(mapPinsProvider.select((s) => s.pins));
    if (from == null) return const SizedBox.shrink();
    final nearest = nearestWorking(pins.values, from);
    if (nearest == null) return const SizedBox.shrink();

    final pin = nearest.pin;
    final name = ref.watch(coolerNameProvider(pin.id));

    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => onOpen(pin.id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Wrap(spacing: 8, runSpacing: 6, children: [
              Pill(text: l.nearestWorking, color: AppColors.working, background: AppColors.workingBg),
              if (pin.hasCups == true)
                Pill(
                  text: l.cupsAvailable,
                  color: AppColors.primaryDark,
                  background: AppColors.primaryContainer,
                  icon: Icons.local_cafe_outlined,
                ),
              if (pin.sponsored)
                Pill(
                  text: l.patronBadge,
                  color: AppColors.patron,
                  background: AppColors.patronBg,
                  icon: Icons.verified_outlined,
                ),
            ]),
            const SizedBox(height: 8),
            Text(
              name.value ?? '…',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Row(children: [
              const Icon(Icons.directions_walk, size: 18, color: AppColors.primaryDark),
              const SizedBox(width: 4),
              Flexible(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: formatDistance(l, nearest.meters),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                      text: ' · ${walkingTime(l, nearest.meters)}',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TintButton(
                  label: l.details,
                  icon: Icons.info_outline,
                  onPressed: () => onOpen(pin.id),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => openDirections(context, pin.lat, pin.lng),
                  icon: const Icon(Icons.near_me_outlined, size: 18),
                  label: Text(l.directions),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primaryDark),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
