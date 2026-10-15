// lib/screens/map/search_overlays.dart
//
// The floating cards shown on top of the map while searching: "Searching...",
// "No results", and the list of matches. They return Positioned widgets, so
// they must be placed directly inside a Stack.

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/water_cooler.dart';
import '../../widgets/status_style.dart';

Widget buildSearchingBanner() {
  return const Positioned(
      top: 12,
      left: 16,
      right: 16,
      child: Material(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
              SizedBox(width: 12),
              Text('Searching database records…'),
            ],
          ),
        ),
      ),
    );
}

Widget buildNoResultsBanner(String query) {
  return Positioned(
      top: 12,
      left: 16,
      right: 16,
      child: Material(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        color: Colors.white,
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.search_off_rounded, color: Colors.grey.shade400),
              const SizedBox(width: 12),
              Text(
                  'No registered sabil for "$query"',
                  style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
}

Widget buildSearchResultsList({
  required List<WaterCooler> results,
  required VoidCallback onCollapse,
  required void Function(WaterCooler cooler) onSelect,
}) {
  return Positioned(
      top: 12,
      left: 16,
      right: 16,
      bottom: 120,
      child: Material(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        color: Colors.white,
        elevation: 6,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  Text(
                    '${results.length} index matches',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.slate600),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () =>
                        onCollapse(),
                    child: Icon(Icons.expand_less_rounded,
                        color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.slate100),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: results.length,
                separatorBuilder: (_, __) => const Divider(
                    height: 1, indent: 16, endIndent: 16, color: AppColors.slate100),
                itemBuilder: (_, i) {
                  final cooler = results[i];
                  final color = statusColor(cooler.status);
                  return ListTile(
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(statusIcon(cooler.status),
                          color: color, size: 18),
                    ),
                    title: Text(cooler.name,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold, color: AppColors.slate800),
                        overflow: TextOverflow.ellipsis),
                    subtitle: Text('Status: ${cooler.status}',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                    trailing: Icon(Icons.chevron_right_rounded,
                        color: Colors.grey.shade300),
                    onTap: () => onSelect(cooler),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
}
