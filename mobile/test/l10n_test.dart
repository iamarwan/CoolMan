import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabil/app/app.dart';
import 'package:sabil/core/locale.dart';
import 'package:sabil/features/cooler/cooler_sheet.dart';

import 'fakes.dart';

Map<String, dynamic> _arb(String name) =>
    jsonDecode(File('lib/l10n/$name').readAsStringSync()) as Map<String, dynamic>;

void main() {
  test('every English string has an Arabic translation', () {
    keys(Map<String, dynamic> m) => m.keys.where((k) => !k.startsWith('@')).toSet();
    final en = keys(_arb('app_en.arb'));
    final ar = keys(_arb('app_ar.arb'));
    expect(en.difference(ar), isEmpty, reason: 'missing in Arabic');
    expect(ar.difference(en), isEmpty, reason: 'unknown keys in Arabic');
  });

  testWidgets('Arabic switches the app to right-to-left', (tester) async {
    final repo = FakeCoolerRepository();
    final container = ProviderContainer(overrides: baseOverrides(repo));
    container.read(localeProvider.notifier).set(const Locale('ar'));
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const SabilApp(home: Scaffold(body: CoolerSheet(coolerId: 'c1'))),
    ));
    await tester.pumpAndSettle();

    expect(Directionality.of(tester.element(find.byType(CoolerSheet))), TextDirection.rtl);
    expect(find.text('ما زالت تعمل'), findsOneWidget); // Still working
    expect(find.text('تعمل'), findsOneWidget); // Working
    expect(find.text('آخر تأكيد منذ 25 دقيقة'), findsOneWidget);
    expect(find.text('الإبلاغ: فارغة'), findsOneWidget);
    container.dispose();
  });
}
