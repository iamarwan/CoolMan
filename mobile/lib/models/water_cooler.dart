// lib/models/water_cooler.dart

import 'cooler_photo.dart';
import 'sponsor.dart';

class WaterCooler {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String status;
  final String lastVerifiedAt;
  final String? createdAt;
  final bool isApproved;
  final bool isRejected;
  final String? pendingStatus;
  final String? userId;           // who submitted it
  final List<CoolerPhoto> photos;
  final bool? hasCups;
  final String? cupsType;
  final bool cupsEnabled;             // cup info is hidden unless an admin switched it on
  final Sponsor? sponsor;
  final String? dedicatedTo;          // "in memory of ..." (set by an admin)
  final String? dedicationMessage;

  const WaterCooler({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.lastVerifiedAt,
    this.createdAt,
    required this.isApproved,
    this.isRejected = false,
    this.pendingStatus,
    this.userId,
    this.photos = const [],
    this.hasCups,
    this.cupsType,
    this.cupsEnabled = false,
    this.sponsor,
    this.dedicatedTo,
    this.dedicationMessage,
  });

  factory WaterCooler.fromJson(Map<String, dynamic> json) => WaterCooler(
        id: json['id'] as String,
        name: json['name'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        status: json['status'] as String,
        lastVerifiedAt: json['last_verified_at'] as String,
        createdAt: json['created_at'] as String?,
        isApproved: json['is_approved'] as bool? ?? false,
        isRejected: json['is_rejected'] as bool? ?? false,
        pendingStatus: json['pending_status'] as String?,
        userId: json['user_id'] as String?,
        photos: (json['photos'] as List<dynamic>? ?? [])
            .map((e) => CoolerPhoto.fromJson(e as Map<String, dynamic>))
            .toList(),
        hasCups: json['has_cups'] as bool?,
        cupsType: json['cups_type'] as String?,
        cupsEnabled: json['cups_enabled'] as bool? ?? false,
        sponsor: json['sponsor'] != null
            ? Sponsor.fromJson(json['sponsor'] as Map<String, dynamic>)
            : null,
        dedicatedTo: json['dedicated_to'] as String?,
        dedicationMessage: json['dedication_message'] as String?,
      );

  static String statusLabel(String status) => switch (status) {
        'Working' => 'Working',
        'Empty' => 'Empty',
        'Broken' => 'Broken',
        _ => status,
      };
}
