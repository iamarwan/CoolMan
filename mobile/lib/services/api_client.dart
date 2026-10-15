// lib/services/api_client.dart
//
// Small helpers shared by every API file. Knows nothing about coolers or users,
// only how to build a URL, read an error message, and label an image upload.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../core/config.dart';

/// Full URL for a server path, e.g. apiUri('/coolers/nearby').
Uri apiUri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

/// The server's error text ("detail"), or [fallback] if there is none.
String extractError(http.Response response, String fallback) {
  try {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['detail'] ?? fallback).toString();
  } catch (_) {
    return fallback;
  }
}

/// The image content type to send for a file, judged by its extension.
MediaType mediaTypeFor(String path) {
  final ext = path.split('.').last.toLowerCase();
  if (ext == 'png') return MediaType('image', 'png');
  if (ext == 'webp') return MediaType('image', 'webp');
  return MediaType('image', 'jpeg');
}
