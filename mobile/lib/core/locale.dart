// App language: follows the phone by default, or a choice saved on device.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import 'providers.dart';

const _localeKey = 'app.locale';

class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() {
    final saved = ref.read(cacheStoreProvider).readJson(_localeKey);
    return switch (saved) {
      'ar' => const Locale('ar'),
      'en' => const Locale('en'),
      _ => null, // follow the phone
    };
  }

  void set(Locale? locale) {
    state = locale;
    ref.read(cacheStoreProvider).writeJson(_localeKey, locale?.languageCode ?? 'system');
  }
}

/// null = use the phone's language.
final localeProvider = NotifierProvider<LocaleController, Locale?>(LocaleController.new);

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
