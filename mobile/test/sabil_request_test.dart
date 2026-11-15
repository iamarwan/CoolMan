import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sabil/app/app.dart';
import 'package:sabil/core/api_client.dart';
import 'package:sabil/features/sabil_request/sabil_request_repository.dart';
import 'package:sabil/features/sabil_request/sabil_request_screen.dart';
import 'package:sabil/models/sabil_request.dart';

import 'fakes.dart';

class FakeRequestRepository extends SabilRequestRepository {
  FakeRequestRepository() : super(ApiClient(baseUrl: 'http://fake'));

  final List<Map<String, Object?>> sent = [];

  @override
  Future<SabilRequest> send(SabilRequestDraft draft) async {
    sent.add(draft.toJson());
    return SabilRequest.fromJson({
      'id': 'r1', 'status': 'new', 'created_at': DateTime.now().toIso8601String(),
      'package': draft.package, 'quantity': 1, 'taps': draft.taps, 'extras': <String>[],
      'timing': draft.timing, 'purpose': draft.purpose, 'governorate': draft.governorate, 'area': draft.area,
    });
  }

  @override
  Future<List<SabilRequest>> mine() async => [];
}

Future<FakeRequestRepository> openForm(WidgetTester tester, {Size size = const Size(900, 7000)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repo = FakeRequestRepository();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      ...baseOverrides(FakeCoolerRepository()),
      sabilRequestRepositoryProvider.overrideWithValue(repo),
    ],
    child: const NwasyApp(home: Navigator(onGenerateRoute: _route)),
  ));
  await tester.pumpAndSettle();
  return repo;
}

Route<void> _route(RouteSettings _) => MaterialPageRoute(builder: (_) => const SabilRequestScreen());

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).first);
  await tester.tap(find.text(text).first);
  await tester.pumpAndSettle();
}

void main() {
  test('Egyptian mobile numbers are normalised like the server does', () {
    expect(normalizeEgMobile('010 1234 5678'), '01012345678');
    expect(normalizeEgMobile('+201112345678'), '01112345678');
    expect(normalizeEgMobile('00201512345678'), '01512345678');
    expect(normalizeEgMobile('٠١٠١٢٣٤٥٦٧٨'), '01012345678');
    expect(normalizeEgMobile('01312345678'), isNull);
    expect(normalizeEgMobile('12345'), isNull);
  });

  testWidgets('an empty form is not sent and the missing answers are marked', (tester) async {
    final repo = await openForm(tester);
    await tapText(tester, 'Send request');
    expect(repo.sent, isEmpty);
    // timing, purpose, place type, permission, area, name, phone
    expect(find.text('Required'), findsNWidgets(7));
    expect(find.text('Some answers are missing. Check the marked fields.'), findsOneWidget);
  });

  testWidgets('a filled form is sent with the right codes and says thanks', (tester) async {
    final repo = await openForm(tester);

    await tapText(tester, 'Company network');
    expect(find.text('Number of coolers'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tapText(tester, '3 taps');
    await tapText(tester, 'Water filter');
    await tapText(tester, 'Within a month');
    await tapText(tester, 'In memory of someone');
    await tester.enterText(find.widgetWithText(TextFormField, 'Name on the sabil (optional)'), 'Hagg Mahmoud');
    await tester.enterText(find.widgetWithText(TextFormField, 'Area or district'), 'Maadi');
    await tapText(tester, 'Outside a shop');
    await tapText(tester, 'I have the owner\'s permission');
    await tester.enterText(find.widgetWithText(TextFormField, 'Your name'), 'Mona');
    await tester.enterText(find.widgetWithText(TextFormField, 'Mobile number'), '+20 100 123 4567');
    await tapText(tester, 'WhatsApp');
    await tapText(tester, 'Send request');

    expect(repo.sent, hasLength(1));
    final body = repo.sent.single;
    expect(body['package'], 'company');
    expect(body['quantity'], 3);
    expect(body['taps'], 3);
    expect(body['extras'], ['filter']);
    expect(body['timing'], 'month');
    expect(body['purpose'], 'memorial');
    expect(body['dedication_name'], 'Hagg Mahmoud');
    expect(body['governorate'], 'cairo');
    expect(body['area'], 'Maadi');
    expect(body['place_type'], 'shop');
    expect(body['permission'], 'has_permission');
    expect(body['electricity'], 'unsure');
    expect(body['phone'], '01001234567');
    expect(body['contact_method'], 'whatsapp');
    expect(body['plaque_text'], isNull);
    expect(find.text('Request sent'), findsOneWidget);
  });

  testWidgets('a bad phone number is explained', (tester) async {
    await openForm(tester);
    await tester.enterText(find.widgetWithText(TextFormField, 'Mobile number'), '0123');
    await tapText(tester, 'Send request');
    expect(find.text('Enter an Egyptian mobile number, e.g. 010 1234 5678.'), findsOneWidget);
  });

  testWidgets('answers at the top survive scrolling to the bottom of a phone screen', (tester) async {
    final repo = await openForm(tester, size: const Size(400, 800));
    final page = find.byType(Scrollable).first;
    await tapText(tester, 'Within a month');
    final dedication = find.widgetWithText(TextFormField, 'Name on the sabil (optional)');
    await tester.ensureVisible(dedication);
    await tester.enterText(dedication, 'Hagg Mahmoud');
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Send request'), 400, scrollable: page);
    await tester.enterText(find.widgetWithText(TextFormField, 'Your name'), 'Mona');
    await tapText(tester, 'Send request');

    expect(repo.sent, isEmpty); // other answers are still missing
    await tester.scrollUntilVisible(find.text('Within a month'), -400, scrollable: page);
    expect(find.text('Hagg Mahmoud'), findsOneWidget);
    final chip = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Within a month'));
    expect(chip.selected, isTrue);
    // purpose, area, place type, permission and phone are flagged; timing is not
    expect(find.text('Required'), findsNWidgets(5));
  });
}
