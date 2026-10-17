// lib/services/coolers_api.dart
//
// Server calls for coolers that any user can make: find them, add one, report
// a status, confirm "still working", and upload a photo.

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/config.dart';
import '../models/water_cooler.dart';
import '../models/cooler_photo.dart';
import 'api_client.dart';
import 'session_store.dart';

mixin class CoolersApi {
  // ─── Read ───

  Future<List<WaterCooler>> fetchNearbyCoolers({
    required double lat,
    required double lng,
    double radiusKm = 5.0,
  }) async {
    final uri = apiUri('/coolers/nearby?lat=$lat&lng=$lng&radius_km=$radiusKm');
    final response = await http.get(uri).timeout(ApiConfig.timeout);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => WaterCooler.fromJson(e)).toList();
    }
    throw Exception('Failed to fetch nearby coolers (${response.statusCode}).');
  }

  Future<List<WaterCooler>> searchCoolers(String query) async {
    final uri = apiUri('/coolers/search?q=${Uri.encodeComponent(query.trim())}');
    final response = await http.get(uri).timeout(ApiConfig.timeout);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => WaterCooler.fromJson(e)).toList();
    }
    throw Exception('Search failed (${response.statusCode}).');
  }

  Future<List<WaterCooler>> fetchMySubmissions() async {
    final response = await http
        .get(apiUri('/coolers/my'), headers: SessionStore.userHeaders())
        .timeout(ApiConfig.timeout);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => WaterCooler.fromJson(e)).toList();
    }
    throw Exception('Failed to fetch submissions (${response.statusCode}).');
  }

  Future<List<CoolerPhoto>> fetchCoolerPhotos(String coolerId) async {
    final response = await http
        .get(apiUri('/coolers/$coolerId/photos'))
        .timeout(ApiConfig.timeout);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => CoolerPhoto.fromJson(e)).toList();
    }
    throw Exception('Failed to fetch photos (${response.statusCode}).');
  }

  // ─── Write ───

  Future<String> createCoolerAndReturnId({
    required String name,
    required double latitude,
    required double longitude,
    String status = 'Working',
    bool? hasCups,
    String? cupsType,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
    };
    if (hasCups != null) body['has_cups'] = hasCups;
    if (cupsType != null) body['cups_type'] = cupsType;

    final response = await http
        .post(
          apiUri('/coolers'),
          headers: SessionStore.userHeaders({'Content-Type': 'application/json'}),
          body: jsonEncode(body),
        )
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 201) {
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      return responseBody['id'] as String;
    }
    throw Exception(extractError(response, 'Failed to create cooler (${response.statusCode}).'));
  }

  Future<bool> updateCoolerStatus({
    required String coolerId,
    required String newStatus,
  }) async {
    final response = await http
        .patch(
          apiUri('/coolers/$coolerId/status'),
          headers: SessionStore.userHeaders({'Content-Type': 'application/json'}),
          body: jsonEncode({'status': newStatus}),
        )
        .timeout(ApiConfig.timeout);
    if (response.statusCode == 200) return true;
    throw Exception(
        extractError(response, 'Failed to update status (${response.statusCode}).'));
  }

  Future<Map<String, dynamic>> confirmCoolerWorking(String coolerId) async {
    final response = await http
        .post(
          apiUri('/coolers/$coolerId/confirm'),
          headers: SessionStore.userHeaders(),
        )
        .timeout(ApiConfig.timeout);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    if (response.statusCode == 429) {
      throw Exception(extractError(response, 'Too many confirmations.'));
    }
    throw Exception('Failed to confirm cooler (${response.statusCode}).');
  }

  Future<CoolerPhoto> uploadPhoto({
    required String coolerId,
    required File imageFile,
    String photoCategory = 'Cooler',
  }) async {
    final request = http.MultipartRequest('POST', apiUri('/coolers/$coolerId/photos'));
    SessionStore.userHeaders().forEach((k, v) => request.headers[k] = v);
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      imageFile.path,
      contentType: mediaTypeFor(imageFile.path),
    ));
    request.fields['photo_category'] = photoCategory;

    final streamed = await request.send().timeout(ApiConfig.timeout);
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 201) {
      return CoolerPhoto.fromJson(jsonDecode(response.body));
    }
    throw Exception(extractError(response, 'Failed to upload photo (${response.statusCode}).'));
  }
}
