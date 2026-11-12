// User-facing text for errors, translated by error code.

import '../l10n/app_localizations.dart';
import 'api_client.dart';
import 'config.dart';

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
    'too_many_attempts' || 'rate_limited' => l.errTooManyAttempts(error.retryAfterMinutes ?? 15),
    'wrong_password' => l.errWrongPassword,
    'status_unchanged' => l.errStatusUnchanged,
    'too_far' => l.errTooFar(error.distanceM ?? 0, AppConfig.maxActionDistanceM),
    'location_required' => l.rangeNeedLocation,
    'location_inaccurate' => l.rangeInaccurate,
    // Unknown code: server messages are English only, so show a translated
    // generic message rather than English text in an Arabic screen.
    _ => l.errGeneric,
  };
}
