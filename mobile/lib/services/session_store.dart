// lib/services/session_store.dart
//
// Remembers who is logged in. Holds the user token (also saved on the phone in
// secure storage so the login survives closing the app) and the admin token
// (memory only), and builds the "Authorization" header the server expects.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user_profile.dart';
import 'api_client.dart';

class SessionStore {
  SessionStore._();

  static const _storage = FlutterSecureStorage();

  static String? _adminToken;
  static String? _userToken;

  /// The logged-in user's profile from the last time we fetched it.
  static UserProfile? cachedProfile;

  // ─── Admin token (not saved to disk) ───

  static void setAdminToken(String? token) => _adminToken = token;
  static void clearAdminToken() => _adminToken = null;

  // ─── User token (saved to secure storage) ───

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
    cachedProfile = null;
    await _storage.delete(key: 'user_token');
  }

  /// Called once when the app starts. If a token was saved last time, check it
  /// is still valid by fetching the profile; if not, forget it.
  static Future<void> restoreSession(
      Future<UserProfile> Function() fetchProfile) async {
    final stored = await _storage.read(key: 'user_token');
    if (stored == null) return;
    _userToken = stored;
    try {
      cachedProfile = await fetchProfile();
    } on AuthRejectedException {
      // The server says this login is no longer valid: forget it.
      _userToken = null;
      await _storage.delete(key: 'user_token');
    } catch (_) {
      // No network, server down, timeout: keep the login so the person is not
      // signed out just because they opened the app offline. The profile loads later.
    }
  }

  static bool get isLoggedIn => _userToken != null && _userToken!.isNotEmpty;

  // ─── Request headers ───

  static Map<String, String> adminHeaders([Map<String, String>? extra]) {
    final merged = <String, String>{...?extra};
    if (_adminToken != null && _adminToken!.isNotEmpty) {
      merged['Authorization'] = 'Bearer $_adminToken';
    }
    return merged;
  }

  static Map<String, String> userHeaders([Map<String, String>? extra]) {
    final merged = <String, String>{...?extra};
    if (_userToken != null && _userToken!.isNotEmpty) {
      merged['Authorization'] = 'Bearer $_userToken';
    }
    return merged;
  }
}
