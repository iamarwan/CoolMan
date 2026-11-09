// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Sabil';

  @override
  String get tryAgain => 'Try again';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get loading => 'Loading…';

  @override
  String get settings => 'Settings';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get notSure => 'Not sure';

  @override
  String get submit => 'Submit';

  @override
  String get saving => 'Saving…';

  @override
  String get errGeneric => 'Something went wrong. Please try again.';

  @override
  String get errOffline => 'No connection. Check your internet and try again.';

  @override
  String get errTimeout => 'The server is not responding. Please try again.';

  @override
  String get errServer => 'Server problem. Please try again in a moment.';

  @override
  String get errAuth => 'Please log in again.';

  @override
  String get errInvalidCredentials => 'Wrong username or password.';

  @override
  String get errUsernameTaken => 'That username is already taken.';

  @override
  String get errDuplicate => 'A cooler is already listed at this spot.';

  @override
  String get errCoolerNotFound => 'This cooler is no longer available.';

  @override
  String errConfirmCooldown(int minutes) {
    return 'You already confirmed this cooler. Try again in $minutes min.';
  }

  @override
  String errReportCooldown(int minutes) {
    return 'You already reported this cooler. Try again in $minutes min.';
  }

  @override
  String get errTooMany => 'Too many submissions. Please try again later.';

  @override
  String get errPhotoTooLarge => 'That photo is too large.';

  @override
  String get errPhotoInvalid => 'That file is not a supported photo.';

  @override
  String get errValidation => 'Please check the entered details.';

  @override
  String get errCameraGallery => 'Could not open the camera or gallery.';

  @override
  String get errDirections => 'Could not open directions.';

  @override
  String get errContact => 'Could not open contact.';

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min ago',
      one: '1 min ago',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count h ago',
      one: '1 h ago',
    );
    return '$_temp0';
  }

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String timeWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks ago',
      one: '1 week ago',
    );
    return '$_temp0';
  }

  @override
  String timeMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mo ago',
      one: '1 mo ago',
    );
    return '$_temp0';
  }

  @override
  String distanceMeters(int meters) {
    return '$meters m';
  }

  @override
  String distanceKm(String km) {
    return '$km km';
  }

  @override
  String walkMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min walk',
      one: '1 min walk',
    );
    return '$_temp0';
  }

  @override
  String walkHours(String hours) {
    return '$hours h walk';
  }

  @override
  String get statusWorking => 'Working';

  @override
  String get statusEmpty => 'Empty';

  @override
  String get statusBroken => 'Broken';

  @override
  String statusPendingReview(String status) {
    return '$status (pending review)';
  }

  @override
  String get reportWorking => 'Report working';

  @override
  String get reportEmpty => 'Report empty';

  @override
  String get reportBroken => 'Report broken';

  @override
  String get cupsUnknown => 'Cups: unknown';

  @override
  String get cupsNone => 'No cups';

  @override
  String get cupsShared => 'Shared cup';

  @override
  String get cupsDisposable => 'Disposable cups';

  @override
  String get cupsAvailable => 'Cups available';

  @override
  String get authTitle => 'Log in to contribute';

  @override
  String get authSubtitle =>
      'Browsing is free. An account lets you add coolers, report status and earn trust points.';

  @override
  String get authLogin => 'Log in';

  @override
  String get authRegister => 'Create account';

  @override
  String get authUsername => 'Username';

  @override
  String get authPassword => 'Password';

  @override
  String get authUsernameTooShort => 'At least 3 characters';

  @override
  String get authUsernameChars => 'English letters, numbers and _ only';

  @override
  String get authPasswordTooShort => 'At least 8 characters';

  @override
  String get searchHint => 'Search coolers';

  @override
  String get searchClear => 'Clear';

  @override
  String get searchNoResults => 'No coolers found';

  @override
  String get profile => 'Profile';

  @override
  String get myLocation => 'My location';

  @override
  String get addCooler => 'Add cooler';

  @override
  String get locationOff => 'Location is turned off.';

  @override
  String get locationBlocked => 'Location permission is blocked.';

  @override
  String get locationDenied => 'Location permission was denied.';

  @override
  String get locationUnavailable =>
      'Could not find your location. Try again outside.';

  @override
  String get mapOffline => 'Offline: showing saved coolers.';

  @override
  String get mapEmpty => 'No coolers here yet. Be the first to add one!';

  @override
  String get placePinHint => 'Move the map to put the pin on the cooler';

  @override
  String get confirmLocation => 'Confirm location';

  @override
  String get coolerAddedLive => 'Cooler added and live on the map. +50 points';

  @override
  String get coolerSubmitted =>
      'Submitted! It will appear after review (+50 points when approved).';

  @override
  String get guestLogin => 'Log in or create account';

  @override
  String get directions => 'Directions';

  @override
  String lastConfirmed(String time) {
    return 'Last confirmed $time';
  }

  @override
  String get stillWorking => 'Still working';

  @override
  String get somethingChanged => 'Something changed?';

  @override
  String get addPhoto => 'Add photo';

  @override
  String get uploading => 'Uploading…';

  @override
  String get thanksConfirm => 'Thanks for confirming! +5 points';

  @override
  String get statusUpdatedPoints => 'Status updated. +10 points';

  @override
  String get reportReviewedPoints =>
      'Thanks! Your report will be reviewed. +10 points';

  @override
  String get photoAdded => 'Photo added. Thank you!';

  @override
  String get photoSentForReview => 'Photo sent for review. Thank you!';

  @override
  String maintainedBy(String name) {
    return 'Maintained by $name';
  }

  @override
  String get verifiedSponsor => 'Verified sponsor';

  @override
  String get photoWhat => 'What does the photo show?';

  @override
  String get photoCooler => 'The cooler';

  @override
  String get photoCups => 'The cups';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get addTitle => 'Add a water cooler';

  @override
  String get addNameLabel => 'Name or landmark';

  @override
  String get addNameHint => 'e.g. Next to El-Tawheed Mosque';

  @override
  String get addNameRequired => 'Please describe where it is';

  @override
  String get addNameInvalid => 'Please remove < and >';

  @override
  String get addWorkingNow => 'Is it working right now?';

  @override
  String get addCupsQuestion => 'Are there cups?';

  @override
  String get addPhotos => 'Photos (recommended, up to 3)';

  @override
  String uploadingPhoto(int current, int total) {
    return 'Uploading photo $current of $total…';
  }

  @override
  String photosFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos could not be uploaded. You can add them later.',
      one: '1 photo could not be uploaded. You can add it later.',
    );
    return '$_temp0';
  }

  @override
  String pointsUntilTrusted(int count) {
    return '$count points until your additions go live instantly';
  }

  @override
  String get trustedNote => 'Your additions and reports go live instantly.';

  @override
  String get pointsShort => 'pts';

  @override
  String pointsValue(int count) {
    return '$count pts';
  }

  @override
  String get statCoolers => 'Coolers added';

  @override
  String get statConfirmations => 'Confirmations';

  @override
  String get statPhotos => 'Photos';

  @override
  String get mySubmissions => 'My submissions';

  @override
  String get sponsors => 'Sponsors';

  @override
  String get logout => 'Log out';

  @override
  String get topContributors => 'Top contributors';

  @override
  String you(String name) {
    return '$name (you)';
  }

  @override
  String get levelChampion => 'Community champion';

  @override
  String get levelVerified => 'Verified contributor';

  @override
  String get levelTrusted => 'Trusted';

  @override
  String get levelContributor => 'Contributor';

  @override
  String get levelNewcomer => 'Newcomer';

  @override
  String get submissionsEmpty =>
      'Nothing yet. Add a cooler from the map to help others find water.';

  @override
  String get subRejected => 'Rejected';

  @override
  String get subUnderReview => 'Under review';

  @override
  String get subStatusPending => 'Status change pending';

  @override
  String get subLive => 'Live on the map';

  @override
  String subAdded(String state, String time) {
    return '$state · added $time';
  }

  @override
  String get sponsorTitle => 'Sponsor';

  @override
  String get sponsorTypeMosque => 'Mosque';

  @override
  String get sponsorTypeIndividual => 'Individual donor';

  @override
  String get sponsorTypeNgo => 'NGO';

  @override
  String get sponsorTypeBusiness => 'Local business';

  @override
  String get sponsorThanks =>
      'This sponsor helps keep public water coolers working. Thank you!';

  @override
  String get sponsorsEmpty => 'No sponsors yet.';

  @override
  String sponsorCoolerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count coolers',
      one: '1 cooler',
    );
    return '$_temp0';
  }

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'Phone default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get onbSkip => 'Skip';

  @override
  String get onbNext => 'Next';

  @override
  String get onbStart => 'Get started';

  @override
  String get onb1Title => 'Find clean water,\nsimple and free';

  @override
  String get onb1Body =>
      'Sabil shows community-reported public water coolers near you, with up-to-date status.';

  @override
  String get onb2Title => 'Add and update\ncoolers around you';

  @override
  String get onb2Body =>
      'Spotted a public water cooler? Tap \"Add cooler\" to list it. Empty or broken? Report it so others know.';

  @override
  String get onb3Title => 'Earn trust\nand level up';

  @override
  String get onb3Body =>
      'Earn +50 points for each approved cooler. At 500 points your additions go live instantly.';
}
