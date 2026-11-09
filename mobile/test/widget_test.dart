import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sabil/main.dart';

void main() {
  testWidgets('App builds and shows the provided home screen', (tester) async {
    await tester.pumpWidget(const SabilApp(home: Text('home')));
    expect(find.text('home'), findsOneWidget);
  });
}
