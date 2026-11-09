// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'سبيل';

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
  String get stillWorking => 'ما زالت تعمل';

  @override
  String get somethingChanged => 'هل تغيّر شيء؟';

  @override
  String get addPhoto => 'إضافة صورة';

  @override
  String get uploading => 'جارٍ الرفع…';

  @override
  String get thanksConfirm => 'شكرًا على التأكيد! +5 نقاط';

  @override
  String get statusUpdatedPoints => 'تم تحديث الحالة. +10 نقاط';

  @override
  String get reportReviewedPoints => 'شكرًا! ستتم مراجعة بلاغك. +10 نقاط';

  @override
  String get photoAdded => 'تمت إضافة الصورة. شكرًا لك!';

  @override
  String get photoSentForReview => 'تم إرسال الصورة للمراجعة. شكرًا لك!';

  @override
  String maintainedBy(String name) {
    return 'برعاية $name';
  }

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
  String get sponsors => 'الرعاة';

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
  String get sponsorTypeIndividual => 'متبرع فرد';

  @override
  String get sponsorTypeNgo => 'جمعية أهلية';

  @override
  String get sponsorTypeBusiness => 'نشاط تجاري محلي';

  @override
  String get sponsorThanks =>
      'يساعد هذا الراعي في استمرار عمل مبردات المياه العامة. شكرًا لهم!';

  @override
  String get sponsorsEmpty => 'لا يوجد رعاة بعد.';

  @override
  String sponsorCoolerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مبردًا',
      few: '$count مبردات',
      two: 'مبردان',
      one: 'مبرد واحد',
      zero: 'لا مبردات',
    );
    return '$_temp0';
  }

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
      'يعرض لك سبيل مبردات المياه العامة القريبة منك كما يبلغ عنها المجتمع، مع حالتها المحدثة.';

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
}
