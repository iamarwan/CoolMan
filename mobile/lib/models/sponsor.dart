// lib/models/sponsor.dart

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
