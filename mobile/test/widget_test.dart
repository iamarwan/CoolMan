import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabil/app/app.dart';
import 'package:sabil/features/cooler/cooler_sheet.dart';

import 'fakes.dart';

Widget harness(FakeCoolerRepository repo, Widget child) => ProviderScope(
      overrides: baseOverrides(repo),
      child: SabilApp(home: Scaffold(body: child)),
    );

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
    expect(find.text('Still working'), findsOneWidget);
    expect(find.text('Report empty'), findsOneWidget);
    expect(find.text('Report broken'), findsOneWidget);
  });

  testWidgets('guests are asked to log in before confirming', (tester) async {
    final repo = FakeCoolerRepository();
    await tester.pumpWidget(harness(repo, const CoolerSheet(coolerId: 'c1')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Still working'));
    await tester.pumpAndSettle();

    expect(find.text('Log in to contribute'), findsOneWidget);
    expect(repo.confirmCalls, 0);
  });
}
