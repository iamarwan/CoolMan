// lib/services/api_service.dart

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart';

import '../models/water_cooler.dart';

MediaType _getMediaType(String path) {
  final ext = path.split('.').last.toLowerCase();
  if (ext == 'png') return MediaType('image', 'png');
  if (ext == 'webp') return MediaType('image', 'webp');
  return MediaType('image', 'jpeg');
}

// ─────────────────────────────────────────────
// DATA CLASSES
// ─────────────────────────────────────────────

class UserProfile {
  final String id;
  final String username;
  final int trustScore;

  const UserProfile({
    required this.id,
    required this.username,
    required this.trustScore,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'],
        username: json['username'],
        trustScore: json['trust_score'] as int,
      );
}

class LeaderboardEntry {
  final int rank;
  final String username;
  final int trustScore;

  const LeaderboardEntry({
    required this.rank,
    required this.username,
    required this.trustScore,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntry(
        rank: json['rank'] as int,
        username: json['username'],
        trustScore: json['trust_score'] as int,
      );
}

// ─────────────────────────────────────────────
// API SERVICE
// ─────────────────────────────────────────────

class ApiService {
  // Android emulator -> host machine custom port. Change this to dynamic configurations as outlined.
  static const _base = 'http://10.0.2.2:8000';

  static const _timeout = Duration(seconds: 15);

  static String? _adminToken;
  static String? _userToken;
  static UserProfile? _cachedProfile;

  static const _storage = FlutterSecureStorage();

  // ─── Token management ───

  static void setAdminToken(String? token) => _adminToken = token;
  static void clearAdminToken() => _adminToken = null;

  static Future<void> setUserToken(String? token) async {
    _userToken = token;
    if (token != null) {
      await _storage.write(key: 'user_token', value: token);
    } else {
      await _storage.delete(key: 'user_token');
    }
  }

  static Future<void> clearUserToken() async {
    _userToken = null;
    _cachedProfile = null;
    await _storage.delete(key: 'user_token');
  }

  static Future<void> restoreSession() async {
    final stored = await _storage.read(key: 'user_token');
    if (stored == null) return;
    _userToken = stored;
    try {
      _cachedProfile = await ApiService().getUserProfile();
    } catch (_) {
      _userToken = null;
      await _storage.delete(key: 'user_token');
    }
  }

  static bool get isLoggedIn => _userToken != null && _userToken!.isNotEmpty;
  static UserProfile? get cachedProfile => _cachedProfile;

  // ─── Header builders ───

  Map<String, String> _adminHeaders([Map<String, String>? extra]) {
    final merged = <String, String>{...?extra};
    if (_adminToken != null && _adminToken!.isNotEmpty) {
      merged['Authorization'] = 'Bearer $_adminToken';
    }
    return merged;
  }

  Map<String, String> _userHeaders([Map<String, String>? extra]) {
    final merged = <String, String>{...?extra};
    if (_userToken != null && _userToken!.isNotEmpty) {
      merged['Authorization'] = 'Bearer $_userToken';
    }
    return merged;
  }

  // ─── Error extraction helper ───

  String _extractError(http.Response response, String fallback) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return (body['detail'] ?? fallback).toString();
    } catch (_) {
      return fallback;
    }
  }

  // ─────────────────────────────────────────────
  // AUTH
  // ─────────────────────────────────────────────

  Future<UserProfile> register({
    required String username,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_base/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': username, 'password': password}),
        )
        .timeout(_timeout);

    if (response.statusCode == 201) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final token = body['access_token'] as String?;
      if (token == null || token.isEmpty) {
        throw Exception('Register response did not include access token.');
      }
      await setUserToken(token);
      final profile = UserProfile.fromJson(body);
      _cachedProfile = profile;
      return profile;
    }
    if (response.statusCode == 409) throw Exception('Username already taken.');
    throw Exception(_extractError(response, 'Registration failed (${response.statusCode}).'));
  }

  Future<UserProfile> userLogin({
    required String username,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_base/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': username, 'password': password}),
        )
        .timeout(_timeout);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final token = body['access_token'] as String?;
      if (token == null || token.isEmpty) {
        throw Exception('Login response did not include access token.');
      }
      await setUserToken(token);
      final profile = UserProfile.fromJson(body);
      _cachedProfile = profile;
      return profile;
    }
    throw Exception('Invalid username or password.');
  }

  Future<UserProfile> getUserProfile() async {
    final response = await http
        .get(Uri.parse('$_base/auth/me'), headers: _userHeaders())
        .timeout(_timeout);

    if (response.statusCode == 200) {
      final profile = UserProfile.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
      _cachedProfile = profile;
      return profile;
    }
    throw Exception('Failed to fetch profile (${response.statusCode}).');
  }

  Future<List<LeaderboardEntry>> getLeaderboard() async {
    final response = await http
        .get(Uri.parse('$_base/users/leaderboard'))
        .timeout(_timeout);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => LeaderboardEntry.fromJson(e)).toList();
    }
    throw Exception('Failed to fetch leaderboard (${response.statusCode}).');
  }

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

  Future<List<WaterCooler>> fetchNearbyCoolers({
    required double lat,
    required double lng,
    double radiusKm = 5.0,
  }) async {
    final uri =
        Uri.parse('$_base/coolers/nearby?lat=$lat&lng=$lng&radius_km=$radiusKm');
    final response = await http.get(uri).timeout(_timeout);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => WaterCooler.fromJson(e)).toList();
    }
    throw Exception('Failed to fetch nearby coolers (${response.statusCode}).');
  }

  Future<List<WaterCooler>> searchCoolers(String query) async {
    final uri = Uri.parse(
        '$_base/coolers/search?q=${Uri.encodeComponent(query.trim())}');
    final response = await http.get(uri).timeout(_timeout);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => WaterCooler.fromJson(e)).toList();
    }
    throw Exception('Search failed (${response.statusCode}).');
  }

  Future<List<WaterCooler>> fetchMySubmissions() async {
    final response = await http
        .get(Uri.parse('$_base/coolers/my'), headers: _userHeaders())
        .timeout(_timeout);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => WaterCooler.fromJson(e)).toList();
    }
    throw Exception('Failed to fetch submissions (${response.statusCode}).');
  }

  Future<List<CoolerPhoto>> fetchCoolerPhotos(String coolerId) async {
    final response = await http
        .get(Uri.parse('$_base/coolers/$coolerId/photos'))
        .timeout(_timeout);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => CoolerPhoto.fromJson(e)).toList();
    }
    throw Exception('Failed to fetch photos (${response.statusCode}).');
  }

  // ─────────────────────────────────────────────
  // COOLERS — WRITE
  // ─────────────────────────────────────────────

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
          Uri.parse('$_base/coolers'),
          headers: _userHeaders({'Content-Type': 'application/json'}),
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    if (response.statusCode == 201) {
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      return responseBody['id'] as String;
    }
    throw Exception(_extractError(response, 'Failed to create cooler (${response.statusCode}).'));
  }

  Future<bool> updateCoolerStatus({
    required String coolerId,
    required String newStatus,
  }) async {
    final response = await http
        .patch(
          Uri.parse('$_base/coolers/$coolerId/status'),
          headers: _userHeaders({'Content-Type': 'application/json'}),
          body: jsonEncode({'status': newStatus}),
        )
        .timeout(_timeout);
    if (response.statusCode == 200) return true;
    throw Exception(
        _extractError(response, 'Failed to update status (${response.statusCode}).'));
  }

  Future<Map<String, dynamic>> confirmCoolerWorking(String coolerId) async {
    final response = await http
        .post(
          Uri.parse('$_base/coolers/$coolerId/confirm'),
          headers: _userHeaders(),
        )
        .timeout(_timeout);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    if (response.statusCode == 429) {
      throw Exception(_extractError(response, 'Too many confirmations.'));
    }
    throw Exception('Failed to confirm cooler (${response.statusCode}).');
  }

  Future<CoolerPhoto> uploadPhoto({
    required String coolerId,
    required File imageFile,
    String photoCategory = 'Cooler',
  }) async {
    final uri = Uri.parse('$_base/coolers/$coolerId/photos');
    final request = http.MultipartRequest('POST', uri);
    _userHeaders().forEach((k, v) => request.headers[k] = v);
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
    throw Exception(_extractError(response, 'Failed to upload photo (${response.statusCode}).'));
  }

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

  Future<Sponsor> fetchSponsor(String sponsorId) async {
    final response = await http
        .get(Uri.parse('$_base/sponsors/$sponsorId'))
        .timeout(_timeout);
    if (response.statusCode == 200) {
      return Sponsor.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to fetch sponsor (${response.statusCode}).');
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
