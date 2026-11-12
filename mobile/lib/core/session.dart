// Login state. Restoring a saved login never blocks the UI: the token is used
// immediately and validated in the background. It is only discarded when the
// server explicitly rejects it (being offline keeps the user logged in).

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user.dart';
import 'api_client.dart';
import 'providers.dart';

const trustedThreshold = 500;

@immutable
class SessionState {
  const SessionState({this.token, this.profile});

  final String? token;
  final UserProfile? profile;

  bool get isLoggedIn => token != null && token!.isNotEmpty;
  bool get isTrusted => (profile?.trustScore ?? 0) >= trustedThreshold;
}

class SessionController extends Notifier<SessionState> {
  static const _tokenKey = 'user_token';
  static const _storage = FlutterSecureStorage();

  @override
  SessionState build() => const SessionState();

  ApiClient get _api => ref.read(apiClientProvider);

  Future<void> restore() async {
    String? token;
    try {
      token = await _storage.read(key: _tokenKey).timeout(const Duration(seconds: 3));
    } catch (_) {
      // Unreadable secure storage (e.g. keys lost after reinstall): start fresh.
      try {
        await _storage.deleteAll();
      } catch (_) {}
      return;
    }
    if (token == null || token.isEmpty || !ref.mounted) return;
    state = SessionState(token: token);
    await refreshProfile();
  }

  Future<void> refreshProfile() async {
    if (!state.isLoggedIn) return;
    try {
      final json = await _api.get('/auth/me') as Map<String, dynamic>;
      if (!ref.mounted) return;
      state = SessionState(token: state.token, profile: UserProfile.fromJson(json));
    } on ApiException catch (e) {
      if (e.isAuthError) await logout();
    }
  }

  Future<void> login(String username, String password) => _authenticate('/auth/login', username, password);

  Future<void> register(String username, String password) =>
      _authenticate('/auth/register', username, password);

  Future<void> _authenticate(String path, String username, String password) async {
    final json = await _api.post(path, {'username': username, 'password': password})
        as Map<String, dynamic>;
    final token = json['access_token'] as String;
    state = SessionState(token: token, profile: UserProfile.fromJson(json));
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (_) {
      // Still logged in for this session even if it cannot be saved.
    }
  }

  /// Permanently deletes the account on the server, then logs out.
  Future<void> deleteAccount(String password) async {
    await _api.delete('/auth/me', {'password': password});
    await logout();
  }

  void updateScore(int score) {
    final p = state.profile;
    if (p != null) state = SessionState(token: state.token, profile: p.withScore(score));
  }

  Future<void> logout() async {
    state = const SessionState();
    try {
      await _storage.delete(key: _tokenKey);
    } catch (_) {}
  }
}

final sessionProvider = NotifierProvider<SessionController, SessionState>(SessionController.new);
