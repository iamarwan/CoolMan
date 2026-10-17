// lib/services/api_service.dart
//
// The one class the screens use to talk to the server. It used to hold ~600
// lines of code; now it only combines the smaller pieces:
//
//   AuthApi      register, login, profile, leaderboard, admin login   (auth_api.dart)
//   CoolersApi   find / add / report / confirm / upload photo         (coolers_api.dart)
//   SponsorsApi  sponsor pages and sponsor admin                      (sponsors_api.dart)
//   AdminApi     review queue and moderation                          (admin_api.dart)
//   SessionStore who is logged in, tokens                             (session_store.dart)
//
// Existing screens keep calling ApiService().something(); new code may use the
// smaller pieces directly, e.g. AdminApi().fetchPendingCoolers().

import '../models/user_profile.dart';
import 'admin_api.dart';
import 'auth_api.dart';
import 'coolers_api.dart';
import 'session_store.dart';
import 'sponsors_api.dart';

class ApiService with AuthApi, CoolersApi, SponsorsApi, AdminApi {
  // ─── Session (static, shared by the whole app) ───

  static bool get isLoggedIn => SessionStore.isLoggedIn;
  static UserProfile? get cachedProfile => SessionStore.cachedProfile;

  static void setAdminToken(String? token) => SessionStore.setAdminToken(token);
  static void clearAdminToken() => SessionStore.clearAdminToken();

  static Future<void> setUserToken(String? token) =>
      SessionStore.setUserToken(token);
  static Future<void> clearUserToken() => SessionStore.clearUserToken();

  /// Sent with image requests in the admin screens: unapproved photos are only
  /// served to an admin (or the uploader), so the admin's login token must go along.
  static Map<String, String> get adminImageHeaders => SessionStore.adminHeaders();

  /// Call once at app start: restores a saved login if it is still valid.
  static Future<void> restoreSession() =>
      SessionStore.restoreSession(() => AuthApi().getUserProfile());
}
