// lib/core/config.dart
//
// Build-time configuration. Values come from --dart-define so the same code can
// target the emulator, a real phone on your Wi-Fi, or a production server:
//
//   Emulator (default):   flutter run
//   Real phone on Wi-Fi:  flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000
//   Production:           flutter build apk --dart-define=API_BASE_URL=https://api.example.com
//
// mobile/build_apk.ps1 fills these in for you.

class AppConfig {
  AppConfig._();

  /// Backend base URL, without a trailing slash.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000', // Android emulator -> host PC
  );

  /// Map tile URL template. OpenStreetMap's public servers are fine for
  /// development only; use a tile provider (MapTiler, Stadia, Carto, ...) in
  /// production and pass its URL here.
  static const String tileUrlTemplate = String.fromEnvironment(
    'TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

  /// Identifies the app to tile servers (required by OSM's usage policy).
  static const String userAgentPackageName = 'com.example.sabil';

  /// Builds an absolute URL for a server-relative path such as /uploads/x.jpg.
  static String absoluteUrl(String path) =>
      path.startsWith('http') ? path : '$apiBaseUrl$path';
}
