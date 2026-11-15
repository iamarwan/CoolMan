// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'نواصي';

  @override
  String get tryAgain => 'حاول مرة أخرى';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get cancel => 'إلغاء';

  @override
  String get loading => 'جارٍ التحميل…';

  @override
  String get settings => 'الإعدادات';

  @override
  String get yes => 'نعم';

  @override
  String get no => 'لا';

  @override
  String get notSure => 'غير متأكد';

  @override
  String get submit => 'إرسال';

  @override
  String get saving => 'جارٍ الحفظ…';

  @override
  String get errGeneric => 'حدث خطأ ما. حاول مرة أخرى.';

  @override
  String get errOffline => 'لا يوجد اتصال. تحقق من الإنترنت وحاول مرة أخرى.';

  @override
  String get errTimeout => 'الخادم لا يستجيب. حاول مرة أخرى.';

  @override
  String get errServer => 'مشكلة في الخادم. حاول مرة أخرى بعد قليل.';

  @override
  String get errAuth => 'يرجى تسجيل الدخول مرة أخرى.';

  @override
  String get errInvalidCredentials => 'اسم المستخدم أو كلمة المرور غير صحيحة.';

  @override
  String get errUsernameTaken => 'اسم المستخدم هذا مستخدم بالفعل.';

  @override
  String get errDuplicate => 'يوجد مبرد مياه مسجّل بالفعل في هذا المكان.';

  @override
  String get errCoolerNotFound => 'هذا المبرد لم يعد متاحًا.';

  @override
  String errConfirmCooldown(int minutes) {
    return 'لقد أكدت هذا المبرد بالفعل. حاول مرة أخرى بعد $minutes دقيقة.';
  }

  @override
  String errReportCooldown(int minutes) {
    return 'لقد أبلغت عن هذا المبرد بالفعل. حاول مرة أخرى بعد $minutes دقيقة.';
  }

  @override
  String get errTooMany => 'عدد كبير من الإضافات. حاول مرة أخرى لاحقًا.';

  @override
  String get errPhotoTooLarge => 'حجم الصورة كبير جدًا.';

  @override
  String get errPhotoInvalid => 'هذا الملف ليس صورة مدعومة.';

  @override
  String get errValidation => 'يرجى مراجعة البيانات المُدخلة.';

  @override
  String get errCameraGallery => 'تعذّر فتح الكاميرا أو المعرض.';

  @override
  String get errDirections => 'تعذّر فتح الاتجاهات.';

  @override
  String get errContact => 'تعذّر فتح وسيلة التواصل.';

  @override
  String get timeJustNow => 'الآن';

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count دقيقة',
      few: 'منذ $count دقائق',
      two: 'منذ دقيقتين',
      one: 'منذ دقيقة',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count ساعة',
      few: 'منذ $count ساعات',
      two: 'منذ ساعتين',
      one: 'منذ ساعة',
    );
    return '$_temp0';
  }

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count يومًا',
      few: 'منذ $count أيام',
      two: 'منذ يومين',
      one: 'منذ يوم',
    );
    return '$_temp0';
  }

  @override
  String timeWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count أسبوعًا',
      few: 'منذ $count أسابيع',
      two: 'منذ أسبوعين',
      one: 'منذ أسبوع',
    );
    return '$_temp0';
  }

  @override
  String timeMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count شهرًا',
      few: 'منذ $count أشهر',
      two: 'منذ شهرين',
      one: 'منذ شهر',
    );
    return '$_temp0';
  }

  @override
  String distanceMeters(int meters) {
    return '$meters م';
  }

  @override
  String distanceKm(String km) {
    return '$km كم';
  }

  @override
  String walkMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count دقيقة سيرًا',
      few: '$count دقائق سيرًا',
      two: 'دقيقتان سيرًا',
      one: 'دقيقة سيرًا',
    );
    return '$_temp0';
  }

  @override
  String walkHours(String hours) {
    return '$hours ساعة سيرًا';
  }

  @override
  String get statusWorking => 'تعمل';

  @override
  String get statusEmpty => 'فارغة';

  @override
  String get statusBroken => 'معطلة';

  @override
  String statusPendingReview(String status) {
    return '$status (قيد المراجعة)';
  }

  @override
  String get reportWorking => 'الإبلاغ: تعمل';

  @override
  String get reportEmpty => 'الإبلاغ: فارغة';

  @override
  String get reportBroken => 'الإبلاغ: معطلة';

  @override
  String get cupsUnknown => 'الأكواب: غير معروف';

  @override
  String get cupsNone => 'لا توجد أكواب';

  @override
  String get cupsShared => 'كوب مشترك';

  @override
  String get cupsDisposable => 'أكواب للاستخدام مرة واحدة';

  @override
  String get cupsAvailable => 'توجد أكواب';

  @override
  String get authTitle => 'سجّل الدخول للمساهمة';

  @override
  String get authSubtitle =>
      'التصفح مجاني. الحساب يتيح لك إضافة مبردات المياه والإبلاغ عن حالتها وكسب نقاط الثقة.';

  @override
  String get authLogin => 'تسجيل الدخول';

  @override
  String get authRegister => 'إنشاء حساب';

  @override
  String get authUsername => 'اسم المستخدم';

  @override
  String get authPassword => 'كلمة المرور';

  @override
  String get authUsernameTooShort => '3 أحرف على الأقل';

  @override
  String get authUsernameChars => 'حروف إنجليزية وأرقام و _ فقط';

  @override
  String get authPasswordTooShort => '8 أحرف على الأقل';

  @override
  String get searchHint => 'ابحث عن مبرد مياه';

  @override
  String get searchClear => 'مسح';

  @override
  String get searchNoResults => 'لم يتم العثور على مبردات';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get myLocation => 'موقعي';

  @override
  String get addCooler => 'إضافة مبرد';

  @override
  String get locationOff => 'خدمة الموقع متوقفة.';

  @override
  String get locationBlocked => 'إذن الموقع محظور.';

  @override
  String get locationDenied => 'تم رفض إذن الموقع.';

  @override
  String get locationUnavailable =>
      'تعذّر تحديد موقعك. حاول مرة أخرى في مكان مفتوح.';

  @override
  String get mapOffline => 'غير متصل: يتم عرض المبردات المحفوظة.';

  @override
  String get mapEmpty => 'لا توجد مبردات هنا بعد. كن أول من يضيف واحدًا!';

  @override
  String get placePinHint => 'حرّك الخريطة لوضع الدبوس على مبرد المياه';

  @override
  String get confirmLocation => 'تأكيد الموقع';

  @override
  String get coolerAddedLive => 'تمت إضافة المبرد وظهر على الخريطة. +50 نقطة';

  @override
  String get coolerSubmitted =>
      'تم الإرسال! سيظهر بعد المراجعة (+50 نقطة عند الموافقة).';

  @override
  String get guestLogin => 'تسجيل الدخول أو إنشاء حساب';

  @override
  String get directions => 'الاتجاهات';

  @override
  String lastConfirmed(String time) {
    return 'آخر تأكيد $time';
  }

  @override
  String get addPhoto => 'إضافة صورة';

  @override
  String get uploading => 'جارٍ الرفع…';

  @override
  String get photoAdded => 'تمت إضافة الصورة. شكرًا لك!';

  @override
  String get photoSentForReview => 'تم إرسال الصورة للمراجعة. شكرًا لك!';

  @override
  String get verifiedSponsor => 'راعٍ موثّق';

  @override
  String get photoWhat => 'ماذا تُظهر الصورة؟';

  @override
  String get photoCooler => 'المبرد';

  @override
  String get photoCups => 'الأكواب';

  @override
  String get camera => 'الكاميرا';

  @override
  String get gallery => 'المعرض';

  @override
  String get addTitle => 'إضافة مبرد مياه';

  @override
  String get addNameLabel => 'الاسم أو علامة مميزة';

  @override
  String get addNameHint => 'مثال: بجوار مسجد التوحيد';

  @override
  String get addNameRequired => 'يرجى وصف مكانه';

  @override
  String get addNameInvalid => 'يرجى حذف الرمزين < و >';

  @override
  String get addWorkingNow => 'هل يعمل الآن؟';

  @override
  String get addCupsQuestion => 'هل توجد أكواب؟';

  @override
  String get addPhotos => 'صور (يُفضّل إضافتها، حتى 3)';

  @override
  String uploadingPhoto(int current, int total) {
    return 'جارٍ رفع الصورة $current من $total…';
  }

  @override
  String photosFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تعذّر رفع $count صور. يمكنك إضافتها لاحقًا.',
      two: 'تعذّر رفع صورتين. يمكنك إضافتهما لاحقًا.',
      one: 'تعذّر رفع صورة واحدة. يمكنك إضافتها لاحقًا.',
    );
    return '$_temp0';
  }

  @override
  String pointsUntilTrusted(int count) {
    return 'باقي $count نقطة لتظهر إضافاتك فورًا';
  }

  @override
  String get trustedNote => 'إضافاتك وبلاغاتك تظهر فورًا.';

  @override
  String get pointsShort => 'نقطة';

  @override
  String pointsValue(int count) {
    return '$count نقطة';
  }

  @override
  String get statCoolers => 'مبردات أضفتها';

  @override
  String get statConfirmations => 'تأكيدات';

  @override
  String get statPhotos => 'صور';

  @override
  String get mySubmissions => 'إضافاتي';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get topContributors => 'أكثر المساهمين';

  @override
  String you(String name) {
    return '$name (أنت)';
  }

  @override
  String get levelChampion => 'بطل المجتمع';

  @override
  String get levelVerified => 'مساهم موثّق';

  @override
  String get levelTrusted => 'موثوق';

  @override
  String get levelContributor => 'مساهم';

  @override
  String get levelNewcomer => 'عضو جديد';

  @override
  String get submissionsEmpty =>
      'لا شيء بعد. أضف مبردًا من الخريطة لتساعد الآخرين على إيجاد الماء.';

  @override
  String get subRejected => 'مرفوض';

  @override
  String get subUnderReview => 'قيد المراجعة';

  @override
  String get subStatusPending => 'تغيير الحالة قيد المراجعة';

  @override
  String get subLive => 'ظاهر على الخريطة';

  @override
  String subAdded(String state, String time) {
    return '$state · أُضيف $time';
  }

  @override
  String get sponsorTitle => 'الراعي';

  @override
  String get sponsorTypeMosque => 'مسجد';

  @override
  String get sponsorTypeNgo => 'جمعية أهلية';

  @override
  String get sponsorTypeBusiness => 'نشاط تجاري محلي';

  @override
  String get sponsorThanks =>
      'يساعد هذا الراعي في توفير مياه الشرب المجانية هنا. شكرًا لهم!';

  @override
  String get language => 'اللغة';

  @override
  String get languageSystem => 'لغة الهاتف';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get onbSkip => 'تخطي';

  @override
  String get onbNext => 'التالي';

  @override
  String get onbStart => 'ابدأ';

  @override
  String get onb1Title => 'اعثر على ماء نظيف\nبسهولة ومجانًا';

  @override
  String get onb1Body =>
      'يعرض لك نواصي مبردات المياه العامة القريبة منك كما يبلغ عنها أهل المنطقة، مع حالتها المحدثة.';

  @override
  String get onb2Title => 'أضف وحدّث\nالمبردات من حولك';

  @override
  String get onb2Body =>
      'رأيت مبرد مياه عامًا؟ اضغط \"إضافة مبرد\" لتسجيله. فارغ أو معطل؟ أبلغ عنه ليعرف الآخرون.';

  @override
  String get onb3Title => 'اكسب الثقة\nوارتقِ بمستواك';

  @override
  String get onb3Body =>
      'اكسب 50 نقطة عن كل مبرد تتم الموافقة عليه. عند 500 نقطة تظهر إضافاتك فورًا.';

  @override
  String thanksConfirmPoints(int points) {
    return 'شكرًا على التأكيد! +$points نقاط';
  }

  @override
  String get thanksConfirmNoPoints => 'شكرًا على التأكيد!';

  @override
  String get statusUpdated => 'تم تحديث الحالة. شكرًا لك!';

  @override
  String get reportReviewed =>
      'شكرًا! ستتم مراجعة بلاغك، وتحصل على 10 نقاط عند قبوله.';

  @override
  String errTooManyAttempts(int minutes) {
    return 'محاولات كثيرة. حاول مرة أخرى بعد $minutes دقيقة.';
  }

  @override
  String get errWrongPassword => 'كلمة المرور غير صحيحة.';

  @override
  String get errStatusUnchanged => 'المبرد بهذه الحالة بالفعل.';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get deleteAccountTitle => 'حذف حسابك؟';

  @override
  String get deleteAccountBody =>
      'سيتم حذف حسابك ونقاطك وسجلك نهائيًا. تبقى المبردات والصور التي أضفتها على الخريطة. أدخل كلمة المرور للتأكيد.';

  @override
  String get deleteAccountDone => 'تم حذف حسابك.';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get errOpenLink => 'تعذّر فتح الصفحة.';

  @override
  String get navMap => 'الخريطة';

  @override
  String get navReports => 'بلاغاتي';

  @override
  String get navAccount => 'حسابي';

  @override
  String get filterAll => 'الكل';

  @override
  String get filterWorking => 'تعمل الآن';

  @override
  String get filterCups => 'بها أكواب';

  @override
  String get filterPatron => 'برعاية';

  @override
  String get nearestWorking => 'أقرب مبرد يعمل';

  @override
  String get patronBadge => 'راعٍ';

  @override
  String get details => 'التفاصيل';

  @override
  String get distance => 'المسافة';

  @override
  String get cups => 'الأكواب';

  @override
  String stepOf(int current, int total) {
    return 'الخطوة $current من $total';
  }

  @override
  String get placeTitle => 'ضع الدبوس على المبرد';

  @override
  String get placeFree => 'حرّك الخريطة حتى يكون الدبوس على المبرد.';

  @override
  String placeInRange(int meters) {
    return 'في النطاق: على بُعد $meters م من مكانك';
  }

  @override
  String placeTooFar(String distance, int max) {
    return 'بعيد ($distance). قف على بُعد $max م من المبرد على الأكثر.';
  }

  @override
  String get rangeLocating => 'جارٍ تحديد موقعك بدقة…';

  @override
  String get rangeNeedLocation => 'فعّل خدمة الموقع لتتمكن من المساهمة.';

  @override
  String rangeNear(int meters) {
    return 'أنت عند هذا المبرد ($meters م). يمكنك التأكيد الآن.';
  }

  @override
  String rangeFar(int max, String distance) {
    return 'اقترب حتى $max م لتتمكن من التأكيد. أنت على بُعد $distance.';
  }

  @override
  String get rangeInaccurate =>
      'موقعك غير دقيق بعد. قف في مكان مفتوح وحاول مرة أخرى.';

  @override
  String errTooFar(int distance, int max) {
    return 'أنت على بُعد $distance م. اقترب حتى $max م من المبرد.';
  }

  @override
  String get stillWorkingPoints => 'ما زالت تعمل (+5 نقاط)';

  @override
  String confirmedTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم تأكيد عمله $count مرة',
      few: 'تم تأكيد عمله $count مرات',
      two: 'تم تأكيد عمله مرتين',
      one: 'تم تأكيد عمله مرة واحدة',
      zero: 'لم يتم تأكيده بعد',
    );
    return '$_temp0';
  }

  @override
  String photosTitle(int count) {
    return 'الصور ($count)';
  }

  @override
  String get waitingReview =>
      'في انتظار المراجعة. لا يرى هذا المبرد غيرك حاليًا.';

  @override
  String get patronFamily => 'وقف عائلي';

  @override
  String get patronImpact => 'الأثر';

  @override
  String get lastChecked => 'آخر تأكيد';

  @override
  String get viewOnMap => 'العودة للخريطة';

  @override
  String get cupsDisposableHint => 'تتوفر أكواب للاستخدام مرة واحدة';

  @override
  String get cupsSharedHint => 'كوب واحد يستخدمه الجميع';

  @override
  String get cupsNoneHint => 'أحضر زجاجتك معك';

  @override
  String get cupsUnknownHint => 'لم أتحقق';

  @override
  String get submitCooler => 'إرسال (+50 نقطة عند الموافقة)';

  @override
  String get reviewNote =>
      'تتم مراجعة كل مبرد جديد قبل ظهوره للجميع على الخريطة.';

  @override
  String get locationConfirmed => 'تم تأكيد الموقع';

  @override
  String get trustScore => 'نقاط الثقة';

  @override
  String get trustTrack => 'مسار المساهم الموثّق';

  @override
  String get myActivity => 'نشاطي';

  @override
  String get leaderboard => 'لوحة المتصدرين';

  @override
  String rankValue(int rank) {
    return '#$rank';
  }

  @override
  String get preferences => 'الإعدادات';

  @override
  String get missionTitle => 'لماذا نواصي';

  @override
  String get missionBody =>
      'نواصي يرسم خريطة ما ينفع الناس على كل ناصية، بدايةً بمياه الشرب الباردة المجانية، ويحافظ على دقتها بمساعدة أهل المنطقة.';

  @override
  String get signInPrompt =>
      'سجّل الدخول لترى المبردات التي أضفتها والبلاغات التي أرسلتها.';

  @override
  String get onbAllowTitle => 'اسمح بالموقع للعثور على الماء القريب';

  @override
  String get onbAllowBody =>
      'يستخدم نواصي موقعك أثناء استخدام التطبيق فقط: لعرض المبردات القريبة ومسافة السير، وللتأكد من وجودك عند المبرد وقت التأكيد.';

  @override
  String get onbAllow => 'السماح بالوصول للموقع';

  @override
  String get onbNotNow => 'ليس الآن';

  @override
  String get onbNoTracking => 'لا تتبّع في الخلفية';

  @override
  String get onbFifty => 'تحقق في حدود 50 م';

  @override
  String get reqEntryTitle => 'ابنِ سبيلًا';

  @override
  String get reqEntryBody =>
      'مبرّد مياه باسم من تحب، نركّبه ونعتني به. أخبرنا بما تريد وسنتصل بك.';

  @override
  String get reqEntryButton => 'اطلب سبيلًا';

  @override
  String get reqTitle => 'بناء سبيل';

  @override
  String get reqIntro =>
      'املأ هذه البيانات وسيتصل بك فريقنا خلال يومي عمل ومعه السعر. لا تدفع شيئًا الآن.';

  @override
  String get reqStepWhat => 'ماذا نبني';

  @override
  String get reqStepWho => 'لمن السبيل';

  @override
  String get reqStepWhere => 'المكان';

  @override
  String get reqStepContact => 'طريقة التواصل';

  @override
  String get reqPkgFull => 'سبيل كامل';

  @override
  String get reqPkgFullBody =>
      'مبرّد وتركيب ولوحة وسنة من الرعاية، وتتابع تأكيده في التطبيق.';

  @override
  String get reqPkgCare => 'خطة رعاية';

  @override
  String get reqPkgCareBody =>
      'لديك مبرّد بالفعل. ننظفه ونصلحه ونتابعه لمدة سنة.';

  @override
  String get reqPkgCompany => 'شبكة لشركة';

  @override
  String get reqPkgCompanyBody =>
      'عدة مبرّدات لشركة أو مؤسسة، واسمكم على كل منها.';

  @override
  String get reqQuantity => 'عدد المبرّدات';

  @override
  String get reqTaps => 'عدد الحنفيات';

  @override
  String get reqExtras => 'إضافات';

  @override
  String get reqExtraFilter => 'فلتر مياه';

  @override
  String get reqExtraShade => 'مظلة أو غطاء';

  @override
  String get reqExtraCups => 'حامل أكواب';

  @override
  String get reqExtraLight => 'إضاءة ليلية';

  @override
  String get reqTiming => 'متى تريده؟';

  @override
  String get reqTimingAsap => 'في أقرب وقت';

  @override
  String get reqTimingMonth => 'خلال شهر';

  @override
  String get reqTimingQuarter => 'خلال 3 أشهر';

  @override
  String get reqTimingFlexible => 'غير مستعجل';

  @override
  String get reqPurpose => 'ما الغرض منه؟';

  @override
  String get reqPurposeMemorial => 'على روح شخص';

  @override
  String get reqPurposeCharity => 'صدقة جارية';

  @override
  String get reqPurposeBusiness => 'من شركة أو محل';

  @override
  String get reqPurposeCommunity => 'مسجد أو مدرسة أو منطقة';

  @override
  String get reqPurposeOther => 'أخرى';

  @override
  String get reqDedication => 'الاسم على السبيل (اختياري)';

  @override
  String get reqDedicationHint => 'مثال: على روح الحاج محمود';

  @override
  String get reqPlaque => 'نص اللوحة (اختياري)';

  @override
  String get reqPlaqueHint => 'مثال: اشرب وادعُ له';

  @override
  String get reqShowPublicly => 'إظهار الاسم في التطبيق';

  @override
  String get reqShowPubliclyBody => 'سيظهر لمن يفتح صفحة المبرّد.';

  @override
  String get reqGovernorate => 'المحافظة';

  @override
  String get reqArea => 'المنطقة أو الحي';

  @override
  String get reqAreaHint => 'مثال: المعادي';

  @override
  String get reqAddress => 'الشارع وعلامة مميزة (اختياري)';

  @override
  String get reqUseLocation => 'أضف موقعي الحالي';

  @override
  String get reqLocationAdded => 'تمت إضافة موقعك';

  @override
  String get reqLocationRemove => 'إزالة';

  @override
  String get reqLocationFailed => 'تعذّر تحديد موقعك. يمكنك إرسال الطلب بدونه.';

  @override
  String get reqPlaceType => 'نوع المكان';

  @override
  String get reqPlaceStreet => 'شارع أو رصيف';

  @override
  String get reqPlaceMosque => 'مسجد';

  @override
  String get reqPlaceSchool => 'مدرسة أو جامعة';

  @override
  String get reqPlaceHospital => 'مستشفى أو عيادة';

  @override
  String get reqPlaceShop => 'أمام محل';

  @override
  String get reqPlaceWorkplace => 'مقر عمل أو مصنع';

  @override
  String get reqPlaceOther => 'أخرى';

  @override
  String get reqPermission => 'تصريح المكان';

  @override
  String get reqPermOwner => 'المكان ملكي';

  @override
  String get reqPermHas => 'معي موافقة المالك';

  @override
  String get reqPermAsking => 'أطلب الموافقة';

  @override
  String get reqPermNotYet => 'ليس بعد';

  @override
  String get reqElectricity => 'كهرباء قريبة؟';

  @override
  String get reqWaterLine => 'ماسورة مياه قريبة؟';

  @override
  String get reqYes => 'نعم';

  @override
  String get reqNo => 'لا';

  @override
  String get reqUnsure => 'لست متأكدًا';

  @override
  String get reqName => 'اسمك';

  @override
  String get reqPhone => 'رقم الموبايل';

  @override
  String get reqPhoneInvalid => 'أدخل رقم موبايل مصري، مثال: 010 1234 5678.';

  @override
  String get reqContactMethod => 'تواصلوا معي عبر';

  @override
  String get reqCall => 'مكالمة';

  @override
  String get reqWhatsapp => 'واتساب';

  @override
  String get reqBestTime => 'أفضل وقت للاتصال';

  @override
  String get reqMorning => 'صباحًا';

  @override
  String get reqAfternoon => 'ظهرًا';

  @override
  String get reqEvening => 'مساءً';

  @override
  String get reqAnyTime => 'أي وقت';

  @override
  String get reqNotes => 'ملاحظات أخرى؟ (اختياري)';

  @override
  String get reqPrivacy => 'نستخدم رقمك فقط لمتابعة هذا الطلب.';

  @override
  String get reqSubmit => 'إرسال الطلب';

  @override
  String get reqRequired => 'مطلوب';

  @override
  String get reqChoose => 'اختر';

  @override
  String get reqFixErrors => 'بعض البيانات ناقصة. راجع الحقول المحددة.';

  @override
  String get reqSentTitle => 'تم إرسال الطلب';

  @override
  String get reqSentBody =>
      'شكرًا لك. سيتصل بك فريقنا خلال يومي عمل، ويمكنك متابعة طلبك من صفحة الحساب.';

  @override
  String get reqDone => 'تم';

  @override
  String get reqTooMany => 'أرسلت عدة طلبات اليوم. سنتصل بك بخصوصها قريبًا.';

  @override
  String get myRequests => 'طلبات السبيل';

  @override
  String get myRequestsEmpty => 'لم تطلب سبيلًا بعد.';

  @override
  String get reqStatusNew => 'تم الاستلام';

  @override
  String get reqStatusContacted => 'تواصلنا معك';

  @override
  String get reqStatusSiteVisit => 'زيارة الموقع';

  @override
  String get reqStatusQuoted => 'تم إرسال السعر';

  @override
  String get reqStatusWon => 'تم التأكيد';

  @override
  String get reqStatusLost => 'مغلق';

  @override
  String get patronBuildOne => 'ابنِ سبيلًا مثله';

  @override
  String reqTapsValue(int count) {
    return '$count حنفيات';
  }

  @override
  String reqQuote(String amount) {
    return 'السعر: $amount جنيه';
  }
}
