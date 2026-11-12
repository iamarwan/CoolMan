// Cooler data models. Parsing is defensive: a bad field never crashes the app.

enum CoolerStatus {
  working('Working'),
  empty('Empty'),
  broken('Broken');

  const CoolerStatus(this.api);
  final String api;

  static CoolerStatus parse(Object? v) =>
      values.firstWhere((s) => s.api == v, orElse: () => CoolerStatus.working);
}

enum CupsType {
  communal('Communal'),
  disposable('Disposable');

  const CupsType(this.api);
  final String api;

  static CupsType? parse(Object? v) {
    for (final t in values) {
      if (t.api == v) return t;
    }
    return null;
  }
}

enum PhotoCategory {
  cooler('Cooler'),
  cups('Cups');

  const PhotoCategory(this.api);
  final String api;

  static PhotoCategory parse(Object? v) =>
      values.firstWhere((c) => c.api == v, orElse: () => PhotoCategory.cooler);
}

DateTime _date(Object? v) =>
    (v is String ? DateTime.tryParse(v) : null)?.toLocal() ?? DateTime.now();

/// Minimal data for a map marker (from GET /coolers/map).
class CoolerPin {
  const CoolerPin({
    required this.id,
    required this.lat,
    required this.lng,
    required this.status,
    this.hasCups,
    this.sponsored = false,
    this.pending = false,
  });

  final String id;
  final double lat;
  final double lng;
  final CoolerStatus status;
  final bool? hasCups;
  final bool sponsored;

  /// The user's own cooler, still waiting for review (only they can see it).
  final bool pending;

  factory CoolerPin.fromJson(Map<String, dynamic> j) => CoolerPin(
        id: j['id'] as String,
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        status: CoolerStatus.parse(j['status']),
        hasCups: j['has_cups'] as bool?,
        sponsored: j['sponsored'] as bool? ?? false,
        pending: j['pending'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'lat': lat,
        'lng': lng,
        'status': status.api,
        'has_cups': hasCups,
        'sponsored': sponsored,
        'pending': pending,
      };

  CoolerPin copyWith({CoolerStatus? status}) => CoolerPin(
        id: id,
        lat: lat,
        lng: lng,
        status: status ?? this.status,
        hasCups: hasCups,
        sponsored: sponsored,
        pending: pending,
      );
}

class Sponsor {
  const Sponsor({
    required this.id,
    required this.name,
    required this.type,
    this.contact,
    this.verified = false,
    this.coolerCount = 0,
  });

  final String id;
  final String name;
  final String type; // Business | Mosque | Individual | NGO
  final String? contact;
  final bool verified;
  final int coolerCount;

  factory Sponsor.fromJson(Map<String, dynamic> j) => Sponsor(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        type: j['sponsor_type'] as String? ?? 'Business',
        contact: j['contact'] as String?,
        verified: j['verified'] as bool? ?? false,
        coolerCount: j['cooler_count'] as int? ?? 0,
      );
}

class CoolerPhoto {
  const CoolerPhoto({
    required this.id,
    required this.url,
    this.thumbUrl,
    required this.category,
    required this.isApproved,
  });

  final String id;
  final String url; // server-relative path
  final String? thumbUrl;
  final PhotoCategory category;
  final bool isApproved;

  factory CoolerPhoto.fromJson(Map<String, dynamic> j) => CoolerPhoto(
        id: j['id'] as String,
        url: j['file_path'] as String,
        thumbUrl: j['thumb_path'] as String?,
        category: PhotoCategory.parse(j['photo_category']),
        isApproved: j['is_approved'] as bool? ?? false,
      );
}

/// Full cooler (from GET /coolers/{id}, search, my submissions).
class Cooler {
  const Cooler({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.status,
    required this.lastVerifiedAt,
    required this.createdAt,
    this.isApproved = true,
    this.isRejected = false,
    this.pendingStatus,
    this.hasCups,
    this.cupsType,
    this.sponsor,
    this.photos = const [],
    this.confirmationsCount = 0,
  });

  final String id;
  final String name;
  final double lat;
  final double lng;
  final CoolerStatus status;
  final DateTime lastVerifiedAt;
  final DateTime createdAt;
  final bool isApproved;
  final bool isRejected;
  final CoolerStatus? pendingStatus;
  final bool? hasCups;
  final CupsType? cupsType;
  final Sponsor? sponsor;
  final List<CoolerPhoto> photos;

  /// How many times people confirmed this cooler as working.
  final int confirmationsCount;

  factory Cooler.fromJson(Map<String, dynamic> j) => Cooler(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        lat: (j['latitude'] as num).toDouble(),
        lng: (j['longitude'] as num).toDouble(),
        status: CoolerStatus.parse(j['status']),
        lastVerifiedAt: _date(j['last_verified_at']),
        createdAt: _date(j['created_at']),
        isApproved: j['is_approved'] as bool? ?? false,
        isRejected: j['is_rejected'] as bool? ?? false,
        pendingStatus: j['pending_status'] == null
            ? null
            : CoolerStatus.parse(j['pending_status']),
        hasCups: j['has_cups'] as bool?,
        cupsType: CupsType.parse(j['cups_type']),
        sponsor: j['sponsor'] is Map<String, dynamic>
            ? Sponsor.fromJson(j['sponsor'] as Map<String, dynamic>)
            : null,
        photos: [
          for (final p in (j['photos'] as List? ?? const []))
            if (p is Map<String, dynamic>) CoolerPhoto.fromJson(p),
        ],
        confirmationsCount: j['confirmations_count'] as int? ?? 0,
      );

  CoolerPin toPin() => CoolerPin(
        id: id,
        lat: lat,
        lng: lng,
        status: status,
        hasCups: hasCups,
        sponsored: sponsor != null,
        pending: !isApproved && !isRejected,
      );

  Cooler copyWith({
    CoolerStatus? status,
    DateTime? lastVerifiedAt,
    CoolerStatus? pendingStatus,
    bool clearPending = false,
    List<CoolerPhoto>? photos,
    int? confirmationsCount,
  }) =>
      Cooler(
        id: id,
        name: name,
        lat: lat,
        lng: lng,
        status: status ?? this.status,
        lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
        createdAt: createdAt,
        isApproved: isApproved,
        isRejected: isRejected,
        pendingStatus: clearPending ? null : (pendingStatus ?? this.pendingStatus),
        hasCups: hasCups,
        cupsType: cupsType,
        sponsor: sponsor,
        photos: photos ?? this.photos,
        confirmationsCount: confirmationsCount ?? this.confirmationsCount,
      );
}
