// lib/core/config.dart
//
// App-wide settings. Change the server address HERE and nowhere else.

class ApiConfig {
  ApiConfig._();

  /// Where the backend server is.
  ///
  /// 10.0.2.2 is how the Android EMULATOR reaches the computer it runs on
  /// (port 8000 = the FastAPI server). On a real phone use your computer's
  /// Wi-Fi address instead, e.g. 'http://192.168.1.20:8000'.
  static const String baseUrl = 'http://10.0.2.2:8000';

  /// How long to wait for the server before giving up.
  static const Duration timeout = Duration(seconds: 15);
}
