import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabil/app/app.dart';
import 'package:sabil/core/location_service.dart';
import 'package:sabil/features/cooler/cooler_sheet.dart';

import 'fakes.dart';

Widget harness(FakeCoolerRepository repo, Widget child, {Fix? at, bool noLocation = false}) => ProviderScope(
      overrides: baseOverrides(repo, at: at, noLocation: noLocation),
      child: NwasyApp(home: Scaffold(body: child)),
    );

FilledButton confirmButton(WidgetTester tester) => tester.widget<FilledButton>(
    find.ancestor(of: find.text('Still working (+5 points)'), matching: find.byWidgetPredicate((w) => w is FilledButton)));

void main() {
  testWidgets('app shell builds', (tester) async {
    await tester.pumpWidget(harness(FakeCoolerRepository(), const Text('home')));
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('cooler sheet shows details and actions', (tester) async {
    final repo = FakeCoolerRepository();
    await tester.pumpWidget(harness(repo, const CoolerSheet(coolerId: 'c1')));
    await tester.pumpAndSettle();

    expect(find.text('Maadi Metro Station'), findsOneWidget);
    expect(find.text('Working'), findsOneWidget);
    expect(find.text('Disposable cups'), findsOneWidget);
    expect(find.text('Last confirmed 25 min ago'), findsOneWidget);
    expect(find.text('Still working (+5 points)'), findsOneWidget);
    expect(find.text('Report empty'), findsOneWidget);
    expect(find.text('Report broken'), findsOneWidget);
  });

  testWidgets('guests are asked to log in before confirming', (tester) async {
    final repo = FakeCoolerRepository();
    await tester.pumpWidget(harness(repo, const CoolerSheet(coolerId: 'c1')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Still working (+5 points)'));
    await tester.tap(find.text('Still working (+5 points)'));
    await tester.pumpAndSettle();

    expect(find.text('Log in to contribute'), findsOneWidget);
    expect(repo.confirmCalls, 0);
  });

  testWidgets('near the cooler: confirming is allowed and says so', (tester) async {
    await tester.pumpWidget(harness(FakeCoolerRepository(), const CoolerSheet(coolerId: 'c1')));
    await tester.pumpAndSettle();
    expect(find.textContaining('You are at this cooler'), findsOneWidget);
    expect(confirmButton(tester).onPressed, isNotNull);
  });

  testWidgets('far from the cooler: actions are disabled and the distance is explained', (tester) async {
    await tester.pumpWidget(harness(
      FakeCoolerRepository(),
      const CoolerSheet(coolerId: 'c1'),
      at: FakeLocationService.farFromCooler(),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Get within 50 m to confirm'), findsOneWidget);
    expect(confirmButton(tester).onPressed, isNull);
  });

  testWidgets('no location: the sheet asks to turn it on', (tester) async {
    await tester.pumpWidget(harness(FakeCoolerRepository(), const CoolerSheet(coolerId: 'c1'), noLocation: true));
    await tester.pumpAndSettle();
    expect(find.text('Turn on location to contribute.'), findsOneWidget);
    expect(confirmButton(tester).onPressed, isNull);
  });
}
