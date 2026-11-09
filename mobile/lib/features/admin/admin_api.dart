// Admin-only API used by the in-app admin screens.
// LEGACY: replaced by the web admin panel in Phase 5, then deleted.

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../core/config.dart';
import 'admin_models.dart';

MediaType _getMediaType(String path) {
  final ext = path.split('.').last.toLowerCase();
  if (ext == 'png') return MediaType('image', 'png');
  if (ext == 'webp') return MediaType('image', 'webp');
  return MediaType('image', 'jpeg');
}

// ─────────────────────────────────────────────
// DATA CLASSES
// ─────────────────────────────────────────────

// ─────────────────────────────────────────────
// API SERVICE
// ─────────────────────────────────────────────

class AdminApi {
  static const _base = AppConfig.apiBaseUrl;

  static const _timeout = Duration(seconds: 15);

  static String? _adminToken;

  // ─── Token management ───

  static void setAdminToken(String? token) => _adminToken = token;
  static void clearAdminToken() => _adminToken = null;

  /// Restores a saved login without ever blocking start-up.
  /// The token is only discarded if the server explicitly rejects it (401/403);
  /// being offline keeps the user logged in.

  // ─── Header builders ───

  Map<String, String> _adminHeaders([Map<String, String>? extra]) {
    final merged = <String, String>{...?extra};
    if (_adminToken != null && _adminToken!.isNotEmpty) {
      merged['Authorization'] = 'Bearer $_adminToken';
    }
    return merged;
  }

  // ─────────────────────────────────────────────
  // AUTH
  // ─────────────────────────────────────────────

  Future<String> adminLogin({
    required String username,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_base/auth/admin/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': username, 'password': password}),
        )
        .timeout(_timeout);
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final token = body['access_token'] as String?;
      if (token == null || token.isEmpty) {
        throw Exception('Admin login response missing access token.');
      }
      setAdminToken(token);
      return token;
    }
    throw Exception('Admin login failed (${response.statusCode}).');
  }

  // ─────────────────────────────────────────────
  // COOLERS — READ
  // ─────────────────────────────────────────────

  // ─────────────────────────────────────────────
  // COOLERS — WRITE
  // ─────────────────────────────────────────────

  // ─────────────────────────────────────────────
  // ADMIN — PHOTOS
  // ─────────────────────────────────────────────

  Future<CoolerPhoto> adminUploadPhoto({
    required String coolerId,
    required File imageFile,
    String photoCategory = 'Cooler',
  }) async {
    final uri = Uri.parse('$_base/admin/coolers/$coolerId/photos');
    final request = http.MultipartRequest('POST', uri);
    _adminHeaders().forEach((k, v) => request.headers[k] = v);
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      imageFile.path,
      contentType: _getMediaType(imageFile.path),
    ));
    request.fields['photo_category'] = photoCategory;

    final streamed = await request.send().timeout(_timeout);
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 201) {
      return CoolerPhoto.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to upload photo (${response.statusCode}).');
  }

  Future<bool> approvePhoto(String photoId) async {
    final response = await http
        .patch(Uri.parse('$_base/admin/photos/$photoId/approve'),
            headers: _adminHeaders())
        .timeout(_timeout);
    if (response.statusCode == 200) return true;
    throw Exception('Failed to approve photo (${response.statusCode}).');
  }

  Future<bool> deletePhoto(String photoId) async {
    final response = await http
        .delete(Uri.parse('$_base/admin/photos/$photoId'),
            headers: _adminHeaders())
        .timeout(_timeout);
    if (response.statusCode == 200 || response.statusCode == 204) return true;
    throw Exception('Failed to delete photo (${response.statusCode}).');
  }

  // ─────────────────────────────────────────────
  // ADMIN — COOLERS
  // ─────────────────────────────────────────────

  Future<List<CoolerPhoto>> fetchCoolerPhotosAdmin(String coolerId) async {
    final response = await http
        .get(Uri.parse('$_base/admin/coolers/$coolerId/photos'),
            headers: _adminHeaders())
        .timeout(_timeout);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => CoolerPhoto.fromJson(e)).toList();
    }
    throw Exception('Failed to fetch photos (${response.statusCode}).');
  }

  Future<List<WaterCooler>> fetchPendingCoolers() async {
    final response = await http
        .get(Uri.parse('$_base/admin/coolers/pending'), headers: _adminHeaders())
        .timeout(_timeout);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => WaterCooler.fromJson(e)).toList();
    }
    throw Exception('Failed to fetch pending coolers (${response.statusCode}).');
  }

  Future<List<WaterCooler>> fetchCurrentCoolers() async {
    final response = await http
        .get(Uri.parse('$_base/admin/coolers/current'), headers: _adminHeaders())
        .timeout(_timeout);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => WaterCooler.fromJson(e)).toList();
    }
    throw Exception('Failed to fetch current coolers (${response.statusCode}).');
  }

  Future<bool> approveCooler(String coolerId) async {
    final response = await http
        .patch(Uri.parse('$_base/admin/coolers/$coolerId/approve'),
            headers: _adminHeaders())
        .timeout(_timeout);
    if (response.statusCode == 200) return true;
    throw Exception('Failed to approve cooler (${response.statusCode}).');
  }

  Future<bool> rejectCooler(String coolerId) async {
    final response = await http
        .patch(Uri.parse('$_base/admin/coolers/$coolerId/reject'),
            headers: _adminHeaders())
        .timeout(_timeout);
    if (response.statusCode == 200) return true;
    throw Exception('Failed to reject cooler (${response.statusCode}).');
  }

  Future<bool> rejectStatusChange(String coolerId) async {
    final response = await http
        .patch(Uri.parse('$_base/admin/coolers/$coolerId/reject-status'),
            headers: _adminHeaders())
        .timeout(_timeout);
    if (response.statusCode == 200) return true;
    throw Exception('Failed to reject status change (${response.statusCode}).');
  }

  Future<bool> forceUpdateStatus({
    required String coolerId,
    required String newStatus,
  }) async {
    final response = await http
        .patch(
          Uri.parse('$_base/admin/coolers/$coolerId/force-status'),
          headers: _adminHeaders({'Content-Type': 'application/json'}),
          body: jsonEncode({'status': newStatus}),
        )
        .timeout(_timeout);
    if (response.statusCode == 200) return true;
    throw Exception('Failed to force update status (${response.statusCode}).');
  }

  Future<bool> deleteCooler(String coolerId) async {
    final response = await http
        .delete(Uri.parse('$_base/admin/coolers/$coolerId'),
            headers: _adminHeaders())
        .timeout(_timeout);
    if (response.statusCode == 200 || response.statusCode == 204) return true;
    throw Exception('Failed to delete cooler (${response.statusCode}).');
  }

  // ─────────────────────────────────────────────
  // SPONSORS
  // ─────────────────────────────────────────────

  Future<List<Sponsor>> fetchAllSponsors() async {
    final response =
        await http.get(Uri.parse('$_base/sponsors')).timeout(_timeout);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Sponsor.fromJson(e)).toList();
    }
    throw Exception('Failed to fetch sponsors (${response.statusCode}).');
  }

  Future<Sponsor> createSponsor({
    required String name,
    required String sponsorType,
    String? contact,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_base/admin/sponsors'),
          headers: _adminHeaders({'Content-Type': 'application/json'}),
          body: jsonEncode({
            'name': name,
            'sponsor_type': sponsorType,
            if (contact != null && contact.isNotEmpty) 'contact': contact,
          }),
        )
        .timeout(_timeout);
    if (response.statusCode == 201) {
      return Sponsor.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to create sponsor (${response.statusCode}).');
  }

  Future<bool> verifySponsor(String sponsorId) async {
    final response = await http
        .patch(Uri.parse('$_base/admin/sponsors/$sponsorId/verify'),
            headers: _adminHeaders())
        .timeout(_timeout);
    if (response.statusCode == 200) return true;
    throw Exception('Failed to verify sponsor (${response.statusCode}).');
  }

  Future<bool> deleteSponsor(String sponsorId) async {
    final response = await http
        .delete(Uri.parse('$_base/admin/sponsors/$sponsorId'),
            headers: _adminHeaders())
        .timeout(_timeout);
    if (response.statusCode == 200 || response.statusCode == 204) return true;
    throw Exception('Failed to delete sponsor (${response.statusCode}).');
  }

  Future<WaterCooler> assignSponsor({
    required String coolerId,
    required String sponsorId,
  }) async {
    final response = await http
        .patch(
          Uri.parse('$_base/admin/coolers/$coolerId/assign-sponsor'),
          headers: _adminHeaders({'Content-Type': 'application/json'}),
          body: jsonEncode({'sponsor_id': sponsorId}),
        )
        .timeout(_timeout);
    if (response.statusCode == 200) {
      return WaterCooler.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to assign sponsor (${response.statusCode}).');
  }

  Future<WaterCooler> removeSponsor(String coolerId) async {
    final response = await http
        .delete(Uri.parse('$_base/admin/coolers/$coolerId/assign-sponsor'),
            headers: _adminHeaders())
        .timeout(_timeout);
    if (response.statusCode == 200) {
      return WaterCooler.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to remove sponsor (${response.statusCode}).');
  }
}
