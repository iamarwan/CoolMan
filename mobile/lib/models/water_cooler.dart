// lib/models/water_cooler.dart

class CoolerPhoto {
  final String id;
  final String coolerId;
  final String filePath;
  final String uploadedAt;
  final bool isApproved;
  final String photoCategory;

  const CoolerPhoto({
    required this.id,
    required this.coolerId,
    required this.filePath,
    required this.uploadedAt,
    required this.isApproved,
    this.photoCategory = 'Cooler',
  });

  factory CoolerPhoto.fromJson(Map<String, dynamic> json) => CoolerPhoto(
        id: json['id'] as String,
        coolerId: json['cooler_id'] as String,
        filePath: json['file_path'] as String,
        uploadedAt: json['uploaded_at'] as String,
        isApproved: json['is_approved'] as bool? ?? false,
        photoCategory: json['photo_category'] as String? ?? 'Cooler',
      );
}

class Sponsor {
  final String id;
  final String name;
  final String sponsorType;
  final String? contact;
  final bool verified;
  final int coolerCount;

  const Sponsor({
    required this.id,
    required this.name,
    required this.sponsorType,
    this.contact,
    required this.verified,
    this.coolerCount = 0,
  });

  factory Sponsor.fromJson(Map<String, dynamic> json) => Sponsor(
        id: json['id'] as String,
        name: json['name'] as String,
        sponsorType: json['sponsor_type'] as String,
        contact: json['contact'] as String?,
        verified: json['verified'] as bool? ?? false,
        coolerCount: json['cooler_count'] as int? ?? 0,
      );
}

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
  final Sponsor? sponsor;

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
    this.sponsor,
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
        sponsor: json['sponsor'] != null
            ? Sponsor.fromJson(json['sponsor'] as Map<String, dynamic>)
            : null,
      );

  static String statusLabel(String status) => switch (status) {
        'Working' => 'Working',
        'Empty' => 'Empty',
        'Broken' => 'Broken',
        _ => status,
      };
}
