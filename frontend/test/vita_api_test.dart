import 'dart:convert';
import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vita_mobile/core/api/vita_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'), (_) async => null);
  test(
    'login uses backend credentials and protected identity endpoint',
    () async {
      final api = VitaApi(
        baseUrl: 'http://localhost:8080',
        client: MockClient((r) async {
          if (r.url.path.endsWith('/login')) {
            expect(jsonDecode(r.body), {
              'email': 'nurse@example.test',
              'password': 'synthetic-password',
            });
            return http.Response(
              '{"data":{"access_token":"access","refresh_token":"refresh"}}',
              200,
            );
          }
          expect(r.headers['Authorization'], 'Bearer access');
          return http.Response(
            '{"data":{"role":"nurse","name":"Synthetic Nurse"}}',
            200,
          );
        }),
      );
      expect(
        (await api.login('nurse@example.test', 'synthetic-password'))['role'],
        'nurse',
      );
      api.close();
    },
  );
  test('unauthenticated calls fail without network', () async {
    final api = VitaApi(baseUrl: 'http://localhost:8080');
    await expectLater(
      api.me(),
      throwsA(isA<ApiFailure>().having((e) => e.status, 'status', 401)),
    );
    api.close();
  });
}
