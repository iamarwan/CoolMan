import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/api_client.dart';
import '../../core/location_service.dart';
import '../../core/providers.dart';
import '../../models/cooler.dart';
import '../map/bbox.dart';

class CoolerRepository {
  CoolerRepository(this._api);

  final ApiClient _api;

  Future<({List<CoolerPin> pins, bool truncated})> pins(Bbox area, {int limit = 600}) async {
    final json = await _api.get('/coolers/map', query: {...area.toQuery(), 'limit': limit})
        as Map<String, dynamic>;
    return (
      pins: [for (final p in json['pins'] as List) CoolerPin.fromJson(p as Map<String, dynamic>)],
      truncated: json['truncated'] as bool? ?? false,
    );
  }

  Future<Cooler> detail(String id) async =>
      Cooler.fromJson(await _api.get('/coolers/$id') as Map<String, dynamic>);

  Future<List<Cooler>> search(String query, {LatLng? near}) async {
    final list = await _api.get('/coolers/search', query: {
      'q': query,
      if (near != null) 'lat': near.latitude,
      if (near != null) 'lng': near.longitude,
    }) as List;
    return [for (final c in list) Cooler.fromJson(c as Map<String, dynamic>)];
  }

  Future<List<Cooler>> mine() async {
    final list = await _api.get('/coolers/my') as List;
    return [for (final c in list) Cooler.fromJson(c as Map<String, dynamic>)];
  }

  Future<Cooler> create({
    required String name,
    required LatLng point,
    required CoolerStatus status,
    bool? hasCups,
    CupsType? cupsType,
    Fix? at,
  }) async {
    final json = await _api.post('/coolers', {
      'name': name,
      'latitude': point.latitude,
      'longitude': point.longitude,
      'status': status.api,
      'has_cups': hasCups,
      if (hasCups == true && cupsType != null) 'cups_type': cupsType.api,
      if (at != null) 'user_location': at.toJson(),
    }) as Map<String, dynamic>;
    return Cooler.fromJson(json);
  }

  Future<Cooler> reportStatus(String id, CoolerStatus status, {Fix? at}) async =>
      Cooler.fromJson(await _api.patch('/coolers/$id/status', {
        'status': status.api,
        if (at != null) 'location': at.toJson(),
      }) as Map<String, dynamic>);

  Future<({int trustScore, int pointsAwarded, DateTime verifiedAt})> confirm(String id, {Fix? at}) async {
    final json = await _api.post('/coolers/$id/confirm', at?.toJson()) as Map<String, dynamic>;
    return (
      trustScore: json['trust_score'] as int,
      pointsAwarded: json['points_awarded'] as int? ?? 0,
      verifiedAt: DateTime.tryParse(json['last_verified_at'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }

  Future<CoolerPhoto> uploadPhoto(String id, String filePath, PhotoCategory category, {Fix? at}) async =>
      CoolerPhoto.fromJson(await _api.uploadFile(
        '/coolers/$id/photos',
        filePath: filePath,
        fields: {
          'photo_category': category.api,
          if (at != null) 'lat': '${at.position.latitude}',
          if (at != null) 'lng': '${at.position.longitude}',
          if (at?.accuracyM != null) 'accuracy': '${at!.accuracyM}',
        },
      ) as Map<String, dynamic>);
}

final coolerRepositoryProvider =
    Provider<CoolerRepository>((ref) => CoolerRepository(ref.watch(apiClientProvider)));
