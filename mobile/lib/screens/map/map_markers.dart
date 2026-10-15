// lib/screens/map/map_markers.dart
//
// The shapes drawn on the map: the blue "you are here" dot, one marker per
// cooler (coloured by status, with a dot when the last check is old), and the
// numbered bubble that groups nearby markers.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme.dart';
import '../../models/water_cooler.dart';
import '../../widgets/status_style.dart';

Marker buildUserMarker(LatLng loc) => Marker(
      point: loc,
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.18),
                shape: BoxShape.circle),
          ),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.4),
                    blurRadius: 6,
                    spreadRadius: 1)
              ],
            ),
          ),
        ],
      ),
    );

Marker buildCoolerMarker(WaterCooler cooler, VoidCallback onTap) {
    final color = statusColor(cooler.status);
    final stalenessDays = DateTime.now()
        .difference(
            DateTime.tryParse(cooler.lastVerifiedAt) ??
                DateTime.now())
        .inDays;
    return Marker(
      point: LatLng(cooler.latitude, cooler.longitude),
      width: 40,
      height: 40,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border:
                    Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(statusIcon(cooler.status),
                  color: Colors.white, size: 20),
            ),
            if (stalenessDays > 14)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: stalenessDays > 30
                        ? AppColors.danger
                        : AppColors.warning,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
}

Widget buildClusterBubble(int count) {
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
}
