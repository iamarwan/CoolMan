import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sabil/core/api_client.dart';

ApiClient clientWith(MockClientHandler handler, {String? token}) => ApiClient(
      httpClient: MockClient(handler),
      baseUrl: 'http://api.test',
      tokenProvider: () => token,
    );

void main() {
  test('decodes JSON and sends the bearer token', () async {
    late http.Request seen;
    final api = clientWith((req) async {
      seen = req;
      return http.Response(jsonEncode({'ok': true}), 200);
    }, token: 'abc');
    final body = await api.get('/x', query: {'a': 1, 'skip': null});
    expect(body, {'ok': true});
    expect(seen.headers['Authorization'], 'Bearer abc');
    expect(seen.url.toString(), 'http://api.test/x?a=1');
  });

  test('server error codes are preserved', () async {
    final api = clientWith((_) async => http.Response(
          jsonEncode({'detail': 'Wait', 'code': 'confirm_cooldown', 'retry_after_minutes': 12}),
          429,
        ));
    await expectLater(
      api.post('/c'),
      throwsA(isA<ApiException>()
          .having((e) => e.code, 'code', 'confirm_cooldown')
          .having((e) => e.retryAfterMinutes, 'retry', 12)
          .having((e) => e.status, 'status', 429)),
    );
  });

  test('validation errors and 5xx get client-side codes', () async {
    final v = clientWith((_) async => http.Response(jsonEncode({'detail': [{'msg': 'bad'}]}), 422));
    await expectLater(v.get('/x'), throwsA(isA<ApiException>().having((e) => e.code, 'code', 'validation_error')));

    final s = clientWith((_) async => http.Response('oops', 502));
    await expectLater(s.get('/x'), throwsA(isA<ApiException>().having((e) => e.code, 'code', 'server_error')));
  });

  test('network failures become offline / timeout', () async {
    final offline = clientWith((_) async => throw const SocketException('down'));
    await expectLater(offline.get('/x'), throwsA(isA<ApiException>().having((e) => e.code, 'code', 'offline')));

    final slow = ApiClient(
      httpClient: MockClient((_) => Future.delayed(const Duration(seconds: 1), () => http.Response('{}', 200))),
      baseUrl: 'http://api.test',
      timeout: const Duration(milliseconds: 20),
    );
    await expectLater(slow.get('/x'), throwsA(isA<ApiException>().having((e) => e.code, 'code', 'timeout')));
  });

  test('decodes UTF-8 (Arabic) correctly', () async {
    final api = clientWith((_) async => http.Response.bytes(utf8.encode(jsonEncode({'name': 'مسجد'})), 200));
    expect(await api.get('/x'), {'name': 'مسجد'});
  });

  test('a rejected login token triggers the unauthorized hook; a wrong password does not', () async {
    var calls = 0;
    ApiClient make(String code) => ApiClient(
          httpClient: MockClient((_) async =>
              http.Response(jsonEncode({'detail': 'x', 'code': code}), 401)),
          baseUrl: 'http://api.test',
          tokenProvider: () => 'abc',
          onUnauthorized: () => calls++,
        );
    await expectLater(make('token_expired').get('/x'), throwsA(isA<ApiException>()));
    expect(calls, 1);
    await expectLater(make('invalid_credentials').post('/auth/login', {}), throwsA(isA<ApiException>()));
    expect(calls, 1);
  });

  test('DELETE can carry a JSON body', () async {
    late http.Request seen;
    final api = clientWith((req) async {
      seen = req;
      return http.Response('', 204);
    });
    await api.delete('/auth/me', {'password': 'p'});
    expect(seen.method, 'DELETE');
    expect(jsonDecode(seen.body), {'password': 'p'});
  });
}
