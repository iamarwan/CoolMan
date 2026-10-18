// lib/services/auth_api.dart
//
// Server calls about people: register, log in, profile, leaderboard, and the
// admin login.
//
// `mixin class` lets this be used on its own (AuthApi().register(...)) AND mixed
// into ApiService (class ApiService with AuthApi, ...), so old code keeps working.

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config.dart';
import '../models/leaderboard_entry.dart';
import '../models/user_profile.dart';
import 'api_client.dart';
import 'session_store.dart';

/// Thrown by verifyPhoneCode when the number has no account yet: the app must
/// ask for a username and call verifyPhoneCode again with the same code.
class UsernameRequiredException implements Exception {
  const UsernameRequiredException();
  @override
  String toString() => 'Choose a username to finish creating your account.';
}

mixin class AuthApi {
  Future<UserProfile> register({
    required String username,
    required String password,
  }) async {
    final response = await http
        .post(
          apiUri('/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': username, 'password': password}),
        )
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 201) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final token = body['access_token'] as String?;
      if (token == null || token.isEmpty) {
        throw Exception('Register response did not include access token.');
      }
      await SessionStore.setUserToken(token);
      final profile = UserProfile.fromJson(body);
      SessionStore.cachedProfile = profile;
      return profile;
    }
    if (response.statusCode == 409) throw Exception('Username already taken.');
    throw Exception(extractError(response, 'Registration failed (${response.statusCode}).'));
  }

  Future<UserProfile> userLogin({
    required String username,
    required String password,
  }) async {
    final response = await http
        .post(
          apiUri('/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': username, 'password': password}),
        )
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final token = body['access_token'] as String?;
      if (token == null || token.isEmpty) {
        throw Exception('Login response did not include access token.');
      }
      await SessionStore.setUserToken(token);
      final profile = UserProfile.fromJson(body);
      SessionStore.cachedProfile = profile;
      return profile;
    }
    throw Exception('Invalid username or password.');
  }

  /// Asks the server to text a one-time code to [phone] (an Egyptian mobile).
  Future<void> requestPhoneCode(String phone) async {
    final response = await http
        .post(
          apiUri('/auth/phone/request'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'phone': phone}),
        )
        .timeout(ApiConfig.timeout);
    if (response.statusCode == 202) return;
    throw Exception(extractError(response, 'Could not send the code (${response.statusCode}).'));
  }

  /// Signs in with the texted code. A number that has no account yet also needs
  /// a [username]; without one this throws [UsernameRequiredException].
  Future<UserProfile> verifyPhoneCode({
    required String phone,
    required String code,
    String? username,
  }) async {
    final response = await http
        .post(
          apiUri('/auth/phone/verify'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'phone': phone,
            'code': code,
            if (username != null && username.isNotEmpty) 'username': username,
          }),
        )
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final token = body['access_token'] as String?;
      if (token == null || token.isEmpty) {
        throw Exception('Login response did not include access token.');
      }
      await SessionStore.setUserToken(token);
      final profile = UserProfile.fromJson(body);
      SessionStore.cachedProfile = profile;
      return profile;
    }
    final message = extractError(response, 'Could not verify the code (${response.statusCode}).');
    if (response.statusCode == 400 && message.startsWith('Choose a username')) {
      throw const UsernameRequiredException();
    }
    throw Exception(message);
  }

  Future<UserProfile> getUserProfile() async {
    final response = await http
        .get(apiUri('/auth/me'), headers: SessionStore.userHeaders())
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 200) {
      final profile = UserProfile.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
      SessionStore.cachedProfile = profile;
      return profile;
    }
    if (response.statusCode == 401) throw const AuthRejectedException();
    throw Exception('Failed to fetch profile (${response.statusCode}).');
  }

  Future<List<LeaderboardEntry>> getLeaderboard() async {
    final response = await http
        .get(apiUri('/users/leaderboard'))
        .timeout(ApiConfig.timeout);
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
          apiUri('/auth/admin/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': username, 'password': password}),
        )
        .timeout(ApiConfig.timeout);
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final token = body['access_token'] as String?;
      if (token == null || token.isEmpty) {
        throw Exception('Admin login response missing access token.');
      }
      SessionStore.setAdminToken(token);
      return token;
    }
    throw Exception(extractError(
        response, 'Invalid administrative credentials (${response.statusCode}).'));
  }
}
