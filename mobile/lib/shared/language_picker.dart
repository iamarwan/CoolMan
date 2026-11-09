import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/locale.dart';
import 'ui.dart';

Future<void> showLanguagePicker(BuildContext context, WidgetRef ref) {
  final l = context.l10n;
  final current = ref.read(localeProvider)?.languageCode;
  final options = [(null, l.languageSystem), ('en', l.languageEnglish), ('ar', l.languageArabic)];
  return showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SheetHandle(),
          Text(l.language, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 8),
          RadioGroup<String?>(
            groupValue: current,
            onChanged: (code) {
              ref.read(localeProvider.notifier).set(code == null ? null : Locale(code));
              Navigator.pop(ctx);
            },
            child: Column(children: [
              for (final (code, label) in options)
                RadioListTile<String?>(value: code, title: Text(label)),
            ]),
          ),
        ]),
      ),
    ),
  );
}
