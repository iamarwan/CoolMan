// One HTTP client for the whole app: base URL, timeouts, auth header and
// consistent error mapping. Every failure becomes an [ApiException].

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'config.dart';

class ApiException implements Exception {
  const ApiException(this.code, this.message, {this.status, this.retryAfterMinutes});

  /// Stable code from the server (e.g. "cooler_duplicate") or a client-side
  /// one: "offline", "timeout", "server_error", "validation_error", "unknown".
  final String code;
  final String message;
  final int? status;
  final int? retryAfterMinutes;

  bool get isAuthError => status == 401;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({
    http.Client? httpClient,
    String? baseUrl,
    this.tokenProvider,
    this.timeout = const Duration(seconds: 15),
  })  : _http = httpClient ?? http.Client(),
        _base = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _http;
  final String _base;
  final Duration timeout;

  /// Returns the current user token, if any.
  final String? Function()? tokenProvider;

  Uri uri(String path, [Map<String, Object?>? query]) {
    final q = <String, String>{
      for (final e in (query ?? const {}).entries)
        if (e.value != null) e.key: '${e.value}',
    };
    return Uri.parse('$_base$path').replace(queryParameters: q.isEmpty ? null : q);
  }

  Map<String, String> _headers({bool json = false}) {
    final token = tokenProvider?.call();
    return {
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String path, {Map<String, Object?>? query}) =>
      _send(() => _http.get(uri(path, query), headers: _headers()));

  Future<dynamic> post(String path, [Object? body]) => _send(() => _http.post(
        uri(path),
        headers: _headers(json: body != null),
        body: body == null ? null : jsonEncode(body),
      ));

  Future<dynamic> patch(String path, [Object? body]) => _send(() => _http.patch(
        uri(path),
        headers: _headers(json: body != null),
        body: body == null ? null : jsonEncode(body),
      ));

  Future<dynamic> delete(String path) =>
      _send(() => _http.delete(uri(path), headers: _headers()));

  Future<dynamic> uploadFile(
    String path, {
    required String filePath,
    String field = 'file',
    Map<String, String> fields = const {},
  }) {
    return _send(() async {
      final req = http.MultipartRequest('POST', uri(path))
        ..headers.addAll(_headers())
        ..fields.addAll(fields)
        ..files.add(await http.MultipartFile.fromPath(
          field,
          filePath,
          contentType: _mediaType(filePath),
        ));
      return http.Response.fromStream(await _http.send(req));
    }, timeout: const Duration(seconds: 60));
  }

  Future<dynamic> _send(
    Future<http.Response> Function() request, {
    Duration? timeout,
  }) async {
    final http.Response res;
    try {
      res = await request().timeout(timeout ?? this.timeout);
    } on TimeoutException {
      throw const ApiException('timeout', 'The server took too long to respond.');
    } on SocketException {
      throw const ApiException('offline', 'No connection to the server.');
    } on http.ClientException {
      throw const ApiException('offline', 'No connection to the server.');
    }

    final body = _decode(res);
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    throw errorFrom(res.statusCode, body);
  }

  static dynamic _decode(http.Response res) {
    if (res.bodyBytes.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      return null;
    }
  }

  static ApiException errorFrom(int status, dynamic body) {
    if (body is Map<String, dynamic>) {
      final detail = body['detail'];
      final code = body['code'] as String?;
      if (detail is String) {
        return ApiException(
          code ?? (status >= 500 ? 'server_error' : 'unknown'),
          detail,
          status: status,
          retryAfterMinutes: body['retry_after_minutes'] as int?,
        );
      }
      if (detail is List) {
        return ApiException('validation_error', 'Please check the entered details.',
            status: status);
      }
    }
    if (status >= 500) {
      return ApiException('server_error', 'Server error. Please try again.', status: status);
    }
    return ApiException('unknown', 'Request failed ($status).', status: status);
  }

  static MediaType _mediaType(String path) {
    final ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'png' => MediaType('image', 'png'),
      'webp' => MediaType('image', 'webp'),
      'heic' || 'heif' => MediaType('image', 'heic'),
      _ => MediaType('image', 'jpeg'),
    };
  }
}
