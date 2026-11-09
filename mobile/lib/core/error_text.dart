// User-facing text for errors, translated by error code.

import '../l10n/app_localizations.dart';
import 'api_client.dart';

String errorText(AppLocalizations l, Object error) {
  if (error is! ApiException) return l.errGeneric;
  return switch (error.code) {
    'offline' => l.errOffline,
    'timeout' => l.errTimeout,
    'server_error' => l.errServer,
    'auth_required' || 'token_expired' || 'token_invalid' => l.errAuth,
    'invalid_credentials' => l.errInvalidCredentials,
    'username_taken' => l.errUsernameTaken,
    'cooler_duplicate' => l.errDuplicate,
    'cooler_not_found' => l.errCoolerNotFound,
    'confirm_cooldown' => l.errConfirmCooldown(error.retryAfterMinutes ?? 60),
    'status_report_cooldown' => l.errReportCooldown(error.retryAfterMinutes ?? 60),
    'cooler_limit' || 'photo_limit' => l.errTooMany,
    'photo_too_large' => l.errPhotoTooLarge,
    'photo_invalid' => l.errPhotoInvalid,
    'validation_error' => l.errValidation,
    // Unknown server error: show its message if any, else a generic one.
    _ => error.message.isEmpty ? l.errGeneric : error.message,
  };
}
