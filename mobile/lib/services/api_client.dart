// lib/services/api_client.dart
//
// Small helpers shared by every API file. Knows nothing about coolers or users,
// only how to build a URL, read an error message, and label an image upload.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
  } on FormatException {
    return fallback; // the reply was not JSON
  } on TypeError {
    return fallback; // JSON, but not the shape we expect
  }
}

/// Thrown when the server says the saved login is no longer valid (HTTP 401).
/// Different from "could not reach the server": only this should log the user out.
class AuthRejectedException implements Exception {
  const AuthRejectedException();
  @override
  String toString() => 'Your login has expired. Please log in again.';
}

/// A message safe to show the person for anything that went wrong with a call:
/// the server's own words when it gave some, a plain hint when the network
/// failed, or [fallback].
String friendlyError(Object error, String fallback) {
  if (error is TimeoutException) {
    return 'The server took too long to answer. Check your connection and try again.';
  }
  if (error is SocketException || error is http.ClientException) {
    return 'Could not reach the server. Check your internet and try again.';
  }
  if (error is Exception) {
    final text = error.toString().replaceFirst('Exception: ', '').trim();
    if (text.isNotEmpty) return text;
  }
  return fallback;
}

/// The image content type to send for a file, judged by its extension.
MediaType mediaTypeFor(String path) {
  final ext = path.split('.').last.toLowerCase();
  if (ext == 'png') return MediaType('image', 'png');
  if (ext == 'webp') return MediaType('image', 'webp');
  return MediaType('image', 'jpeg');
}
