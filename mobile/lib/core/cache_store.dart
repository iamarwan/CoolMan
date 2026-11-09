// Small persistent cache (shared_preferences + JSON) so the map can show the
// last known state instantly on start-up, before any network request.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CacheStore {
  CacheStore(this._prefs);

  final SharedPreferences? _prefs; // null if storage is unavailable

  static Future<CacheStore> open() async {
    try {
      return CacheStore(await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 3)));
    } catch (_) {
      return CacheStore(null);
    }
  }

  Object? readJson(String key) {
    final raw = _prefs?.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> writeJson(String key, Object? value) async {
    try {
      await _prefs?.setString(key, jsonEncode(value));
    } catch (_) {}
  }

  bool getBool(String key, {bool fallback = false}) => _prefs?.getBool(key) ?? fallback;

  Future<void> setBool(String key, bool value) async {
    try {
      await _prefs?.setBool(key, value);
    } catch (_) {}
  }
}
