import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Nwasy'**
  String get appTitle;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @notSure.
  ///
  /// In en, this message translates to:
  /// **'Not sure'**
  String get notSure;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @errGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errGeneric;

  /// No description provided for @errOffline.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your internet and try again.'**
  String get errOffline;

  /// No description provided for @errTimeout.
  ///
  /// In en, this message translates to:
  /// **'The server is not responding. Please try again.'**
  String get errTimeout;

  /// No description provided for @errServer.
  ///
  /// In en, this message translates to:
  /// **'Server problem. Please try again in a moment.'**
  String get errServer;

  /// No description provided for @errAuth.
  ///
  /// In en, this message translates to:
  /// **'Please log in again.'**
  String get errAuth;

  /// No description provided for @errInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Wrong username or password.'**
  String get errInvalidCredentials;

  /// No description provided for @errUsernameTaken.
  ///
  /// In en, this message translates to:
  /// **'That username is already taken.'**
  String get errUsernameTaken;

  /// No description provided for @errDuplicate.
  ///
  /// In en, this message translates to:
  /// **'A cooler is already listed at this spot.'**
  String get errDuplicate;

  /// No description provided for @errCoolerNotFound.
  ///
  /// In en, this message translates to:
  /// **'This cooler is no longer available.'**
  String get errCoolerNotFound;

  /// No description provided for @errConfirmCooldown.
  ///
  /// In en, this message translates to:
  /// **'You already confirmed this cooler. Try again in {minutes} min.'**
  String errConfirmCooldown(int minutes);

  /// No description provided for @errReportCooldown.
  ///
  /// In en, this message translates to:
  /// **'You already reported this cooler. Try again in {minutes} min.'**
  String errReportCooldown(int minutes);

  /// No description provided for @errTooMany.
  ///
  /// In en, this message translates to:
  /// **'Too many submissions. Please try again later.'**
  String get errTooMany;

  /// No description provided for @errPhotoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'That photo is too large.'**
  String get errPhotoTooLarge;

  /// No description provided for @errPhotoInvalid.
  ///
  /// In en, this message translates to:
  /// **'That file is not a supported photo.'**
  String get errPhotoInvalid;

  /// No description provided for @errValidation.
  ///
  /// In en, this message translates to:
  /// **'Please check the entered details.'**
  String get errValidation;

  /// No description provided for @errCameraGallery.
  ///
  /// In en, this message translates to:
  /// **'Could not open the camera or gallery.'**
  String get errCameraGallery;

  /// No description provided for @errDirections.
  ///
  /// In en, this message translates to:
  /// **'Could not open directions.'**
  String get errDirections;

  /// No description provided for @errContact.
  ///
  /// In en, this message translates to:
  /// **'Could not open contact.'**
  String get errContact;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 min ago} other{{count} min ago}}'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 h ago} other{{count} h ago}}'**
  String timeHoursAgo(int count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String timeDaysAgo(int count);

  /// No description provided for @timeWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 week ago} other{{count} weeks ago}}'**
  String timeWeeksAgo(int count);

  /// No description provided for @timeMonthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 mo ago} other{{count} mo ago}}'**
  String timeMonthsAgo(int count);

  /// No description provided for @distanceMeters.
  ///
  /// In en, this message translates to:
  /// **'{meters} m'**
  String distanceMeters(int meters);

  /// No description provided for @distanceKm.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String distanceKm(String km);

  /// No description provided for @walkMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 min walk} other{{count} min walk}}'**
  String walkMinutes(int count);

  /// No description provided for @walkHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h walk'**
  String walkHours(String hours);

  /// No description provided for @statusWorking.
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get statusWorking;

  /// No description provided for @statusEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get statusEmpty;

  /// No description provided for @statusBroken.
  ///
  /// In en, this message translates to:
  /// **'Broken'**
  String get statusBroken;

  /// No description provided for @statusPendingReview.
  ///
  /// In en, this message translates to:
  /// **'{status} (pending review)'**
  String statusPendingReview(String status);

  /// No description provided for @reportWorking.
  ///
  /// In en, this message translates to:
  /// **'Report working'**
  String get reportWorking;

  /// No description provided for @reportEmpty.
  ///
  /// In en, this message translates to:
  /// **'Report empty'**
  String get reportEmpty;

  /// No description provided for @reportBroken.
  ///
  /// In en, this message translates to:
  /// **'Report broken'**
  String get reportBroken;

  /// No description provided for @cupsUnknown.
  ///
  /// In en, this message translates to:
  /// **'Cups: unknown'**
  String get cupsUnknown;

  /// No description provided for @cupsNone.
  ///
  /// In en, this message translates to:
  /// **'No cups'**
  String get cupsNone;

  /// No description provided for @cupsShared.
  ///
  /// In en, this message translates to:
  /// **'Shared cup'**
  String get cupsShared;

  /// No description provided for @cupsDisposable.
  ///
  /// In en, this message translates to:
  /// **'Disposable cups'**
  String get cupsDisposable;

  /// No description provided for @cupsAvailable.
  ///
  /// In en, this message translates to:
  /// **'Cups available'**
  String get cupsAvailable;

  /// No description provided for @authTitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to contribute'**
  String get authTitle;

  /// No description provided for @authSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browsing is free. An account lets you add coolers, report status and earn trust points.'**
  String get authSubtitle;

  /// No description provided for @authLogin.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get authLogin;

  /// No description provided for @authRegister.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authRegister;

  /// No description provided for @authUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get authUsername;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authUsernameTooShort.
  ///
  /// In en, this message translates to:
  /// **'At least 3 characters'**
  String get authUsernameTooShort;

  /// No description provided for @authUsernameChars.
  ///
  /// In en, this message translates to:
  /// **'English letters, numbers and _ only'**
  String get authUsernameChars;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get authPasswordTooShort;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search coolers'**
  String get searchHint;

  /// No description provided for @searchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get searchClear;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No coolers found'**
  String get searchNoResults;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @myLocation.
  ///
  /// In en, this message translates to:
  /// **'My location'**
  String get myLocation;

  /// No description provided for @addCooler.
  ///
  /// In en, this message translates to:
  /// **'Add cooler'**
  String get addCooler;

  /// No description provided for @locationOff.
  ///
  /// In en, this message translates to:
  /// **'Location is turned off.'**
  String get locationOff;

  /// No description provided for @locationBlocked.
  ///
  /// In en, this message translates to:
  /// **'Location permission is blocked.'**
  String get locationBlocked;

  /// No description provided for @locationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission was denied.'**
  String get locationDenied;

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not find your location. Try again outside.'**
  String get locationUnavailable;

  /// No description provided for @mapOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline: showing saved coolers.'**
  String get mapOffline;

  /// No description provided for @mapEmpty.
  ///
  /// In en, this message translates to:
  /// **'No coolers here yet. Be the first to add one!'**
  String get mapEmpty;

  /// No description provided for @placePinHint.
  ///
  /// In en, this message translates to:
  /// **'Move the map to put the pin on the cooler'**
  String get placePinHint;

  /// No description provided for @confirmLocation.
  ///
  /// In en, this message translates to:
  /// **'Confirm location'**
  String get confirmLocation;

  /// No description provided for @coolerAddedLive.
  ///
  /// In en, this message translates to:
  /// **'Cooler added and live on the map. +50 points'**
  String get coolerAddedLive;

  /// No description provided for @coolerSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted! It will appear after review (+50 points when approved).'**
  String get coolerSubmitted;

  /// No description provided for @guestLogin.
  ///
  /// In en, this message translates to:
  /// **'Log in or create account'**
  String get guestLogin;

  /// No description provided for @directions.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get directions;

  /// No description provided for @lastConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Last confirmed {time}'**
  String lastConfirmed(String time);

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhoto;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get uploading;

  /// No description provided for @photoAdded.
  ///
  /// In en, this message translates to:
  /// **'Photo added. Thank you!'**
  String get photoAdded;

  /// No description provided for @photoSentForReview.
  ///
  /// In en, this message translates to:
  /// **'Photo sent for review. Thank you!'**
  String get photoSentForReview;

  /// No description provided for @verifiedSponsor.
  ///
  /// In en, this message translates to:
  /// **'Verified patron'**
  String get verifiedSponsor;

  /// No description provided for @photoWhat.
  ///
  /// In en, this message translates to:
  /// **'What does the photo show?'**
  String get photoWhat;

  /// No description provided for @photoCooler.
  ///
  /// In en, this message translates to:
  /// **'The cooler'**
  String get photoCooler;

  /// No description provided for @photoCups.
  ///
  /// In en, this message translates to:
  /// **'The cups'**
  String get photoCups;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @addTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a water cooler'**
  String get addTitle;

  /// No description provided for @addNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name or landmark'**
  String get addNameLabel;

  /// No description provided for @addNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Next to El-Tawheed Mosque'**
  String get addNameHint;

  /// No description provided for @addNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please describe where it is'**
  String get addNameRequired;

  /// No description provided for @addNameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please remove < and >'**
  String get addNameInvalid;

  /// No description provided for @addWorkingNow.
  ///
  /// In en, this message translates to:
  /// **'Is it working right now?'**
  String get addWorkingNow;

  /// No description provided for @addCupsQuestion.
  ///
  /// In en, this message translates to:
  /// **'Are there cups?'**
  String get addCupsQuestion;

  /// No description provided for @addPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos (recommended, up to 3)'**
  String get addPhotos;

  /// No description provided for @uploadingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Uploading photo {current} of {total}…'**
  String uploadingPhoto(int current, int total);

  /// No description provided for @photosFailed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo could not be uploaded. You can add it later.} other{{count} photos could not be uploaded. You can add them later.}}'**
  String photosFailed(int count);

  /// No description provided for @pointsUntilTrusted.
  ///
  /// In en, this message translates to:
  /// **'{count} points until your additions go live instantly'**
  String pointsUntilTrusted(int count);

  /// No description provided for @trustedNote.
  ///
  /// In en, this message translates to:
  /// **'Your additions and reports go live instantly.'**
  String get trustedNote;

  /// No description provided for @pointsShort.
  ///
  /// In en, this message translates to:
  /// **'pts'**
  String get pointsShort;

  /// No description provided for @pointsValue.
  ///
  /// In en, this message translates to:
  /// **'{count} pts'**
  String pointsValue(int count);

  /// No description provided for @statCoolers.
  ///
  /// In en, this message translates to:
  /// **'Coolers added'**
  String get statCoolers;

  /// No description provided for @statConfirmations.
  ///
  /// In en, this message translates to:
  /// **'Confirmations'**
  String get statConfirmations;

  /// No description provided for @statPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get statPhotos;

  /// No description provided for @mySubmissions.
  ///
  /// In en, this message translates to:
  /// **'My submissions'**
  String get mySubmissions;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @topContributors.
  ///
  /// In en, this message translates to:
  /// **'Top contributors'**
  String get topContributors;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'{name} (you)'**
  String you(String name);

  /// No description provided for @levelChampion.
  ///
  /// In en, this message translates to:
  /// **'Community champion'**
  String get levelChampion;

  /// No description provided for @levelVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified contributor'**
  String get levelVerified;

  /// No description provided for @levelTrusted.
  ///
  /// In en, this message translates to:
  /// **'Trusted'**
  String get levelTrusted;

  /// No description provided for @levelContributor.
  ///
  /// In en, this message translates to:
  /// **'Contributor'**
  String get levelContributor;

  /// No description provided for @levelNewcomer.
  ///
  /// In en, this message translates to:
  /// **'Newcomer'**
  String get levelNewcomer;

  /// No description provided for @submissionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet. Add a cooler from the map to help others find water.'**
  String get submissionsEmpty;

  /// No description provided for @subRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get subRejected;

  /// No description provided for @subUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get subUnderReview;

  /// No description provided for @subStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Status change pending'**
  String get subStatusPending;

  /// No description provided for @subLive.
  ///
  /// In en, this message translates to:
  /// **'Live on the map'**
  String get subLive;

  /// No description provided for @subAdded.
  ///
  /// In en, this message translates to:
  /// **'{state} · added {time}'**
  String subAdded(String state, String time);

  /// No description provided for @sponsorTitle.
  ///
  /// In en, this message translates to:
  /// **'Patron'**
  String get sponsorTitle;

  /// No description provided for @sponsorTypeMosque.
  ///
  /// In en, this message translates to:
  /// **'Mosque'**
  String get sponsorTypeMosque;

  /// No description provided for @sponsorTypeNgo.
  ///
  /// In en, this message translates to:
  /// **'NGO'**
  String get sponsorTypeNgo;

  /// No description provided for @sponsorTypeBusiness.
  ///
  /// In en, this message translates to:
  /// **'Local business'**
  String get sponsorTypeBusiness;

  /// No description provided for @sponsorThanks.
  ///
  /// In en, this message translates to:
  /// **'This patron helps keep free drinking water available here. Thank you!'**
  String get sponsorThanks;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Phone default'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @onbSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onbSkip;

  /// No description provided for @onbNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onbNext;

  /// No description provided for @onbStart.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onbStart;

  /// No description provided for @onb1Title.
  ///
  /// In en, this message translates to:
  /// **'Find clean water,\nsimple and free'**
  String get onb1Title;

  /// No description provided for @onb1Body.
  ///
  /// In en, this message translates to:
  /// **'Nwasy shows the public water coolers near you, reported by people in the area, with up-to-date status.'**
  String get onb1Body;

  /// No description provided for @onb2Title.
  ///
  /// In en, this message translates to:
  /// **'Add and update\ncoolers around you'**
  String get onb2Title;

  /// No description provided for @onb2Body.
  ///
  /// In en, this message translates to:
  /// **'Spotted a public water cooler? Tap \"Add cooler\" to list it. Empty or broken? Report it so others know.'**
  String get onb2Body;

  /// No description provided for @onb3Title.
  ///
  /// In en, this message translates to:
  /// **'Earn trust\nand level up'**
  String get onb3Title;

  /// No description provided for @onb3Body.
  ///
  /// In en, this message translates to:
  /// **'Earn +50 points for each approved cooler. At 500 points your additions go live instantly.'**
  String get onb3Body;

  /// No description provided for @thanksConfirmPoints.
  ///
  /// In en, this message translates to:
  /// **'Thanks for confirming! +{points} points'**
  String thanksConfirmPoints(int points);

  /// No description provided for @thanksConfirmNoPoints.
  ///
  /// In en, this message translates to:
  /// **'Thanks for confirming!'**
  String get thanksConfirmNoPoints;

  /// No description provided for @statusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Status updated. Thank you!'**
  String get statusUpdated;

  /// No description provided for @reportReviewed.
  ///
  /// In en, this message translates to:
  /// **'Thanks! Your report will be reviewed. You earn 10 points if it is accepted.'**
  String get reportReviewed;

  /// No description provided for @errTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in {minutes} min.'**
  String errTooManyAttempts(int minutes);

  /// No description provided for @errWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong password.'**
  String get errWrongPassword;

  /// No description provided for @errStatusUnchanged.
  ///
  /// In en, this message translates to:
  /// **'The cooler already has this status.'**
  String get errStatusUnchanged;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account, points and history. Coolers and photos you added stay on the map. Enter your password to confirm.'**
  String get deleteAccountBody;

  /// No description provided for @deleteAccountDone.
  ///
  /// In en, this message translates to:
  /// **'Your account was deleted.'**
  String get deleteAccountDone;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @errOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open the page.'**
  String get errOpenLink;

  /// No description provided for @navMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'My reports'**
  String get navReports;

  /// No description provided for @navAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get navAccount;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterWorking.
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get filterWorking;

  /// No description provided for @filterCups.
  ///
  /// In en, this message translates to:
  /// **'Has cups'**
  String get filterCups;

  /// No description provided for @filterPatron.
  ///
  /// In en, this message translates to:
  /// **'With patron'**
  String get filterPatron;

  /// No description provided for @nearestWorking.
  ///
  /// In en, this message translates to:
  /// **'Nearest working cooler'**
  String get nearestWorking;

  /// No description provided for @patronBadge.
  ///
  /// In en, this message translates to:
  /// **'Patron'**
  String get patronBadge;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @cups.
  ///
  /// In en, this message translates to:
  /// **'Cups'**
  String get cups;

  /// No description provided for @stepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepOf(int current, int total);

  /// No description provided for @placeTitle.
  ///
  /// In en, this message translates to:
  /// **'Put the pin on the cooler'**
  String get placeTitle;

  /// No description provided for @placeFree.
  ///
  /// In en, this message translates to:
  /// **'Move the map until the pin is on the cooler.'**
  String get placeFree;

  /// No description provided for @placeInRange.
  ///
  /// In en, this message translates to:
  /// **'Within reach: {meters} m from where you stand'**
  String placeInRange(int meters);

  /// No description provided for @placeTooFar.
  ///
  /// In en, this message translates to:
  /// **'Too far ({distance}). Stand within {max} m of the cooler.'**
  String placeTooFar(String distance, int max);

  /// No description provided for @rangeLocating.
  ///
  /// In en, this message translates to:
  /// **'Getting an accurate location…'**
  String get rangeLocating;

  /// No description provided for @rangeNeedLocation.
  ///
  /// In en, this message translates to:
  /// **'Turn on location to contribute.'**
  String get rangeNeedLocation;

  /// No description provided for @rangeNear.
  ///
  /// In en, this message translates to:
  /// **'You are at this cooler ({meters} m). You can confirm it now.'**
  String rangeNear(int meters);

  /// No description provided for @rangeFar.
  ///
  /// In en, this message translates to:
  /// **'Get within {max} m to confirm. You are {distance} away.'**
  String rangeFar(int max, String distance);

  /// No description provided for @rangeInaccurate.
  ///
  /// In en, this message translates to:
  /// **'Your location is not accurate enough yet. Step into the open and try again.'**
  String get rangeInaccurate;

  /// No description provided for @errTooFar.
  ///
  /// In en, this message translates to:
  /// **'You are {distance} m away. Get within {max} m of the cooler.'**
  String errTooFar(int distance, int max);

  /// No description provided for @stillWorkingPoints.
  ///
  /// In en, this message translates to:
  /// **'Still working (+5 points)'**
  String get stillWorkingPoints;

  /// No description provided for @confirmedTimes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Not confirmed yet} =1{Confirmed working once} other{Confirmed working {count} times}}'**
  String confirmedTimes(int count);

  /// No description provided for @photosTitle.
  ///
  /// In en, this message translates to:
  /// **'Photos ({count})'**
  String photosTitle(int count);

  /// No description provided for @waitingReview.
  ///
  /// In en, this message translates to:
  /// **'Waiting for review. Only you can see this cooler for now.'**
  String get waitingReview;

  /// No description provided for @patronFamily.
  ///
  /// In en, this message translates to:
  /// **'Family dedication'**
  String get patronFamily;

  /// No description provided for @patronImpact.
  ///
  /// In en, this message translates to:
  /// **'Impact'**
  String get patronImpact;

  /// No description provided for @lastChecked.
  ///
  /// In en, this message translates to:
  /// **'Last confirmed'**
  String get lastChecked;

  /// No description provided for @viewOnMap.
  ///
  /// In en, this message translates to:
  /// **'Back to the map'**
  String get viewOnMap;

  /// No description provided for @cupsDisposableHint.
  ///
  /// In en, this message translates to:
  /// **'Single-use cups are provided'**
  String get cupsDisposableHint;

  /// No description provided for @cupsSharedHint.
  ///
  /// In en, this message translates to:
  /// **'One cup shared by everyone'**
  String get cupsSharedHint;

  /// No description provided for @cupsNoneHint.
  ///
  /// In en, this message translates to:
  /// **'Bring your own bottle'**
  String get cupsNoneHint;

  /// No description provided for @cupsUnknownHint.
  ///
  /// In en, this message translates to:
  /// **'I did not check'**
  String get cupsUnknownHint;

  /// No description provided for @submitCooler.
  ///
  /// In en, this message translates to:
  /// **'Submit (+50 points when approved)'**
  String get submitCooler;

  /// No description provided for @reviewNote.
  ///
  /// In en, this message translates to:
  /// **'Every new cooler is reviewed before it appears on the map for everyone.'**
  String get reviewNote;

  /// No description provided for @locationConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Location confirmed'**
  String get locationConfirmed;

  /// No description provided for @trustScore.
  ///
  /// In en, this message translates to:
  /// **'Trust score'**
  String get trustScore;

  /// No description provided for @trustTrack.
  ///
  /// In en, this message translates to:
  /// **'Verified contributor track'**
  String get trustTrack;

  /// No description provided for @myActivity.
  ///
  /// In en, this message translates to:
  /// **'My activity'**
  String get myActivity;

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// No description provided for @rankValue.
  ///
  /// In en, this message translates to:
  /// **'#{rank}'**
  String rankValue(int rank);

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get preferences;

  /// No description provided for @missionTitle.
  ///
  /// In en, this message translates to:
  /// **'Why Nwasy'**
  String get missionTitle;

  /// No description provided for @missionBody.
  ///
  /// In en, this message translates to:
  /// **'Nwasy maps the useful things on every street corner, starting with free cold drinking water, and keeps the map accurate with the help of people nearby.'**
  String get missionBody;

  /// No description provided for @signInPrompt.
  ///
  /// In en, this message translates to:
  /// **'Log in to see the coolers you added and the reports you sent.'**
  String get signInPrompt;

  /// No description provided for @onbAllowTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow location to find water nearby'**
  String get onbAllowTitle;

  /// No description provided for @onbAllowBody.
  ///
  /// In en, this message translates to:
  /// **'Nwasy uses your location only while you use the app: to show coolers near you and the walking distance, and to check you are at a cooler when you confirm it.'**
  String get onbAllowBody;

  /// No description provided for @onbAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow location access'**
  String get onbAllow;

  /// No description provided for @onbNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get onbNotNow;

  /// No description provided for @onbNoTracking.
  ///
  /// In en, this message translates to:
  /// **'No tracking in the background'**
  String get onbNoTracking;

  /// No description provided for @onbFifty.
  ///
  /// In en, this message translates to:
  /// **'Checked within 50 m'**
  String get onbFifty;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
