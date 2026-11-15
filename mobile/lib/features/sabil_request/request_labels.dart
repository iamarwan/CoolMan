// Translated labels for the codes a build-a-sabil request uses.

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../shared/ui.dart';

typedef Option = ({String code, String label});

List<Option> timingOptions(AppLocalizations l) => [
  (code: 'asap', label: l.reqTimingAsap),
  (code: 'month', label: l.reqTimingMonth),
  (code: 'quarter', label: l.reqTimingQuarter),
  (code: 'flexible', label: l.reqTimingFlexible),
];

List<Option> purposeOptions(AppLocalizations l) => [
  (code: 'memorial', label: l.reqPurposeMemorial),
  (code: 'charity', label: l.reqPurposeCharity),
  (code: 'business', label: l.reqPurposeBusiness),
  (code: 'community', label: l.reqPurposeCommunity),
  (code: 'other', label: l.reqPurposeOther),
];

List<Option> extraOptions(AppLocalizations l) => [
  (code: 'filter', label: l.reqExtraFilter),
  (code: 'shade', label: l.reqExtraShade),
  (code: 'cups', label: l.reqExtraCups),
  (code: 'lighting', label: l.reqExtraLight),
];

List<Option> placeOptions(AppLocalizations l) => [
  (code: 'street', label: l.reqPlaceStreet),
  (code: 'mosque', label: l.reqPlaceMosque),
  (code: 'school', label: l.reqPlaceSchool),
  (code: 'hospital', label: l.reqPlaceHospital),
  (code: 'shop', label: l.reqPlaceShop),
  (code: 'workplace', label: l.reqPlaceWorkplace),
  (code: 'other', label: l.reqPlaceOther),
];

List<Option> permissionOptions(AppLocalizations l) => [
  (code: 'owner', label: l.reqPermOwner),
  (code: 'has_permission', label: l.reqPermHas),
  (code: 'working_on_it', label: l.reqPermAsking),
  (code: 'not_yet', label: l.reqPermNotYet),
];

List<Option> yesNoOptions(AppLocalizations l) => [
  (code: 'yes', label: l.reqYes),
  (code: 'no', label: l.reqNo),
  (code: 'unsure', label: l.reqUnsure),
];

List<Option> contactOptions(AppLocalizations l) => [
  (code: 'call', label: l.reqCall),
  (code: 'whatsapp', label: l.reqWhatsapp),
];

List<Option> bestTimeOptions(AppLocalizations l) => [
  (code: 'morning', label: l.reqMorning),
  (code: 'afternoon', label: l.reqAfternoon),
  (code: 'evening', label: l.reqEvening),
  (code: 'any', label: l.reqAnyTime),
];

({String title, String body, IconData icon}) packageInfo(AppLocalizations l, String code) => switch (code) {
  'care_only' => (title: l.reqPkgCare, body: l.reqPkgCareBody, icon: Icons.build_circle_outlined),
  'company' => (title: l.reqPkgCompany, body: l.reqPkgCompanyBody, icon: Icons.apartment_outlined),
  _ => (title: l.reqPkgFull, body: l.reqPkgFullBody, icon: Icons.volunteer_activism_outlined),
};

const packageCodes = ['full', 'care_only', 'company'];

String labelFor(List<Option> options, String code) =>
    options.firstWhere((o) => o.code == code, orElse: () => (code: code, label: code)).label;

({String label, Color color, Color background}) requestStatus(AppLocalizations l, String status) => switch (status) {
  'contacted' => (label: l.reqStatusContacted, color: AppColors.empty, background: AppColors.emptyBg),
  'site_visit' => (label: l.reqStatusSiteVisit, color: AppColors.empty, background: AppColors.emptyBg),
  'quoted' => (label: l.reqStatusQuoted, color: AppColors.patron, background: AppColors.patronBg),
  'won' => (label: l.reqStatusWon, color: AppColors.working, background: AppColors.workingBg),
  'lost' => (label: l.reqStatusLost, color: AppColors.muted, background: AppColors.surfaceLow),
  _ => (label: l.reqStatusNew, color: AppColors.pending, background: AppColors.pendingBg),
};

/// Egypt's 27 governorates: code → (English, Arabic). Codes match the server.
const governorates = <String, (String, String)>{
  'cairo': ('Cairo', 'القاهرة'),
  'giza': ('Giza', 'الجيزة'),
  'alexandria': ('Alexandria', 'الإسكندرية'),
  'qalyubia': ('Qalyubia', 'القليوبية'),
  'sharqia': ('Sharqia', 'الشرقية'),
  'dakahlia': ('Dakahlia', 'الدقهلية'),
  'gharbia': ('Gharbia', 'الغربية'),
  'monufia': ('Monufia', 'المنوفية'),
  'beheira': ('Beheira', 'البحيرة'),
  'kafr_el_sheikh': ('Kafr El Sheikh', 'كفر الشيخ'),
  'damietta': ('Damietta', 'دمياط'),
  'port_said': ('Port Said', 'بورسعيد'),
  'ismailia': ('Ismailia', 'الإسماعيلية'),
  'suez': ('Suez', 'السويس'),
  'faiyum': ('Faiyum', 'الفيوم'),
  'beni_suef': ('Beni Suef', 'بني سويف'),
  'minya': ('Minya', 'المنيا'),
  'asyut': ('Asyut', 'أسيوط'),
  'sohag': ('Sohag', 'سوهاج'),
  'qena': ('Qena', 'قنا'),
  'luxor': ('Luxor', 'الأقصر'),
  'aswan': ('Aswan', 'أسوان'),
  'red_sea': ('Red Sea', 'البحر الأحمر'),
  'new_valley': ('New Valley', 'الوادي الجديد'),
  'matrouh': ('Matrouh', 'مطروح'),
  'north_sinai': ('North Sinai', 'شمال سيناء'),
  'south_sinai': ('South Sinai', 'جنوب سيناء'),
};

String governorateName(BuildContext context, String code) {
  final names = governorates[code];
  if (names == null) return code;
  return Localizations.localeOf(context).languageCode == 'ar' ? names.$2 : names.$1;
}
