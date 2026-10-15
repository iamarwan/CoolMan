// lib/services/admin_api.dart
//
// Server calls only an admin may make: the review queue, approving/rejecting
// coolers and photos, forcing a status, and deleting. (Admin sponsor actions
// are in sponsors_api.dart; the admin login is in auth_api.dart.)

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/config.dart';
import '../models/water_cooler.dart';
import 'api_client.dart';
import 'session_store.dart';

mixin class AdminApi {
  // ─── Photos ───

  Future<CoolerPhoto> adminUploadPhoto({
    required String coolerId,
    required File imageFile,
    String photoCategory = 'Cooler',
  }) async {
    final request =
        http.MultipartRequest('POST', apiUri('/admin/coolers/$coolerId/photos'));
    SessionStore.adminHeaders().forEach((k, v) => request.headers[k] = v);
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
    throw Exception('Failed to upload photo (${response.statusCode}).');
  }

  Future<bool> approvePhoto(String photoId) async {
    final response = await http
        .patch(apiUri('/admin/photos/$photoId/approve'),
            headers: SessionStore.adminHeaders())
        .timeout(ApiConfig.timeout);
    if (response.statusCode == 200) return true;
    throw Exception('Failed to approve photo (${response.statusCode}).');
  }

  Future<bool> deletePhoto(String photoId) async {
    final response = await http
        .delete(apiUri('/admin/photos/$photoId'),
            headers: SessionStore.adminHeaders())
        .timeout(ApiConfig.timeout);
    if (response.statusCode == 200 || response.statusCode == 204) return true;
    throw Exception('Failed to delete photo (${response.statusCode}).');
  }

  Future<List<CoolerPhoto>> fetchCoolerPhotosAdmin(String coolerId) async {
    final response = await http
        .get(apiUri('/admin/coolers/$coolerId/photos'),
            headers: SessionStore.adminHeaders())
        .timeout(ApiConfig.timeout);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => CoolerPhoto.fromJson(e)).toList();
    }
    throw Exception('Failed to fetch photos (${response.statusCode}).');
  }

  // ─── Coolers ───

  Future<List<WaterCooler>> fetchPendingCoolers() async {
    final response = await http
        .get(apiUri('/admin/coolers/pending'),
            headers: SessionStore.adminHeaders())
        .timeout(ApiConfig.timeout);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => WaterCooler.fromJson(e)).toList();
    }
    throw Exception('Failed to fetch pending coolers (${response.statusCode}).');
  }

  Future<List<WaterCooler>> fetchCurrentCoolers() async {
    final response = await http
        .get(apiUri('/admin/coolers/current'),
            headers: SessionStore.adminHeaders())
        .timeout(ApiConfig.timeout);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => WaterCooler.fromJson(e)).toList();
    }
    throw Exception('Failed to fetch current coolers (${response.statusCode}).');
  }

  Future<bool> approveCooler(String coolerId) async {
    final response = await http
        .patch(apiUri('/admin/coolers/$coolerId/approve'),
            headers: SessionStore.adminHeaders())
        .timeout(ApiConfig.timeout);
    if (response.statusCode == 200) return true;
    throw Exception('Failed to approve cooler (${response.statusCode}).');
  }

  Future<bool> rejectCooler(String coolerId) async {
    final response = await http
        .patch(apiUri('/admin/coolers/$coolerId/reject'),
            headers: SessionStore.adminHeaders())
        .timeout(ApiConfig.timeout);
    if (response.statusCode == 200) return true;
    throw Exception('Failed to reject cooler (${response.statusCode}).');
  }

  Future<bool> rejectStatusChange(String coolerId) async {
    final response = await http
        .patch(apiUri('/admin/coolers/$coolerId/reject-status'),
            headers: SessionStore.adminHeaders())
        .timeout(ApiConfig.timeout);
    if (response.statusCode == 200) return true;
    throw Exception('Failed to reject status change (${response.statusCode}).');
  }

  Future<bool> forceUpdateStatus({
    required String coolerId,
    required String newStatus,
  }) async {
    final response = await http
        .patch(
          apiUri('/admin/coolers/$coolerId/force-status'),
          headers: SessionStore.adminHeaders({'Content-Type': 'application/json'}),
          body: jsonEncode({'status': newStatus}),
        )
        .timeout(ApiConfig.timeout);
    if (response.statusCode == 200) return true;
    throw Exception('Failed to force update status (${response.statusCode}).');
  }

  Future<bool> deleteCooler(String coolerId) async {
    final response = await http
        .delete(apiUri('/admin/coolers/$coolerId'),
            headers: SessionStore.adminHeaders())
        .timeout(ApiConfig.timeout);
    if (response.statusCode == 200 || response.statusCode == 204) return true;
    throw Exception('Failed to delete cooler (${response.statusCode}).');
  }
}
