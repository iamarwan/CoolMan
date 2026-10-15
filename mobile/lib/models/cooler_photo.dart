// lib/models/cooler_photo.dart

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
