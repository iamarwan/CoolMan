// User-facing text for errors. Phase 4 (localization) translates these by code.

import 'api_client.dart';

String errorText(Object error) {
  if (error is! ApiException) return 'Something went wrong. Please try again.';
  return switch (error.code) {
    'offline' => 'No connection. Check your internet and try again.',
    'timeout' => 'The server is not responding. Please try again.',
    'server_error' => 'Server problem. Please try again in a moment.',
    'auth_required' || 'token_expired' || 'token_invalid' => 'Please log in again.',
    'invalid_credentials' => 'Wrong username or password.',
    'username_taken' => 'That username is already taken.',
    'cooler_duplicate' => 'A cooler is already listed at this spot.',
    'cooler_not_found' => 'This cooler is no longer available.',
    'confirm_cooldown' =>
      'You already confirmed this cooler. Try again in ${error.retryAfterMinutes ?? 60} min.',
    'status_report_cooldown' =>
      'You already reported this cooler. Try again in ${error.retryAfterMinutes ?? 60} min.',
    'cooler_limit' || 'photo_limit' => 'Too many submissions. Please try again later.',
    'photo_too_large' => 'That photo is too large.',
    'photo_invalid' => 'That file is not a supported photo.',
    'validation_error' => 'Please check the entered details.',
    _ => error.message,
  };
}
