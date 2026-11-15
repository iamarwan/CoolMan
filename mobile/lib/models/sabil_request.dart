/// A "build a sabil" request as the app sees it after sending.
/// Contact details are never sent back by the server.
class SabilRequest {
  const SabilRequest({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.package,
    required this.quantity,
    required this.taps,
    required this.extras,
    required this.timing,
    required this.purpose,
    required this.governorate,
    required this.area,
    this.dedicationName,
    this.quoteEgp,
  });

  final String id;
  final String status;
  final DateTime createdAt;
  final String package;
  final int quantity;
  final int taps;
  final List<String> extras;
  final String timing;
  final String purpose;
  final String governorate;
  final String area;
  final String? dedicationName;
  final int? quoteEgp;

  factory SabilRequest.fromJson(Map<String, dynamic> j) => SabilRequest(
        id: j['id'] as String,
        status: j['status'] as String,
        createdAt: DateTime.parse(j['created_at'] as String),
        package: j['package'] as String,
        quantity: (j['quantity'] as num?)?.toInt() ?? 1,
        taps: (j['taps'] as num?)?.toInt() ?? 2,
        extras: [for (final e in (j['extras'] as List? ?? const [])) e as String],
        timing: j['timing'] as String,
        purpose: j['purpose'] as String,
        governorate: j['governorate'] as String,
        area: j['area'] as String,
        dedicationName: j['dedication_name'] as String?,
        quoteEgp: (j['quote_egp'] as num?)?.toInt(),
      );
}

/// What the form sends. Codes match the server's choices exactly.
class SabilRequestDraft {
  String package = 'full';
  int quantity = 1;
  int taps = 2;
  final Set<String> extras = {};
  String? timing;

  String? purpose;
  String dedicationName = '';
  String plaqueText = '';
  bool showPublicly = true;

  String governorate = 'cairo';
  String area = '';
  String addressNotes = '';
  double? latitude;
  double? longitude;
  String? placeType;
  String? permission;
  String electricity = 'unsure';
  String waterLine = 'unsure';

  String contactName = '';
  String phone = '';
  String contactMethod = 'call';
  String bestTime = 'any';
  String notes = '';

  String? _opt(String s) => s.trim().isEmpty ? null : s.trim();

  Map<String, Object?> toJson() => {
        'package': package,
        'quantity': package == 'company' ? quantity : 1,
        'taps': taps,
        'extras': extras.toList()..sort(),
        'timing': timing,
        'purpose': purpose,
        'dedication_name': _opt(dedicationName),
        'plaque_text': _opt(plaqueText),
        'show_publicly': showPublicly,
        'governorate': governorate,
        'area': area.trim(),
        'address_notes': _opt(addressNotes),
        'latitude': latitude,
        'longitude': longitude,
        'place_type': placeType,
        'permission': permission,
        'electricity': electricity,
        'water_line': waterLine,
        'contact_name': contactName.trim(),
        'phone': phone.trim(),
        'contact_method': contactMethod,
        'best_time': bestTime,
        'notes': _opt(notes),
      };
}

final _egMobile = RegExp(r'^(?:\+20|0020|0)?(1[0125]\d{8})$');

/// "010 1234 5678", "+201012345678" or Arabic digits → "01012345678"; null if
/// it is not an Egyptian mobile number. Mirrors the server's check.
String? normalizeEgMobile(String input) {
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  final buf = StringBuffer();
  for (final ch in input.split('')) {
    final i = arabic.indexOf(ch);
    if (i >= 0) {
      buf.write(i);
    } else if (!RegExp(r'[\s\-()]').hasMatch(ch)) {
      buf.write(ch);
    }
  }
  final m = _egMobile.firstMatch(buf.toString());
  return m == null ? null : '0${m.group(1)}';
}
