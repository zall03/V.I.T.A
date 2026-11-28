import 'dart:convert';

import 'biometric_session.dart';

import 'package:http/http.dart' as http;

/// Backend transport. Credentials remain in memory; never use demo patient IDs.
class VitaApi {
  VitaApi({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;
  String? _accessToken;
  String? _refreshToken;
  Future<void>? _refreshing;
  final biometrics = BiometricSession();
  bool _biometricEnabled = false;

  Future<bool> enableBiometrics() async {
    if (_refreshToken == null || !await biometrics.authenticate()) return false;
    await biometrics.save(baseUrl, _refreshToken!);
    _biometricEnabled = true;
    return true;
  }

  Future<Map<String, dynamic>> biometricLogin() async {
    final token = await biometrics.unlock(baseUrl);
    if (token == null) {
      throw const ApiFailure(401, 'biometric_session_unavailable');
    }
    _refreshToken = token;
    _biometricEnabled = true;
    await refresh();
    return me();
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final request = http.Request(method, Uri.parse('$baseUrl/api/v1$path'));
    request.headers['Content-Type'] = 'application/json';
    if (authenticated) {
      if (_accessToken == null) throw const ApiFailure(401, 'unauthorized');
      request.headers['Authorization'] = 'Bearer $_accessToken';
    }
    if (body != null) request.body = jsonEncode(body);
    final response = await http.Response.fromStream(
      await _client.send(request).timeout(const Duration(seconds: 20)),
    ).timeout(const Duration(seconds: 20));
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw ApiFailure(response.statusCode, 'invalid_server_response');
    }
    if (decoded is! Map<String, dynamic>) {
      throw ApiFailure(response.statusCode, 'invalid_server_response');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = decoded['error'];
      throw ApiFailure(
        response.statusCode,
        error is Map && error['code'] is String
            ? error['code'] as String
            : 'request_failed',
      );
    }
    return decoded['data'];
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await _send(
      'POST',
      '/auth/login',
      authenticated: false,
      body: {
        email.contains('@') ? 'email' : 'nurse_id': email,
        'password': password,
      },
    );
    _setTokens(data);
    if (biometrics.supported) await biometrics.clear(baseUrl);
    _biometricEnabled = false;
    return me();
  }

  void _setTokens(dynamic data) {
    if (data is! Map ||
        data['access_token'] is! String ||
        data['refresh_token'] is! String) {
      throw const ApiFailure(502, 'invalid_token_response');
    }
    _accessToken = data['access_token'] as String;
    _refreshToken = data['refresh_token'] as String;
  }

  /// Serialize refresh rotation. Never automatically replay mutation requests.
  Future<void> refresh() =>
      _refreshing ??= _rotate().whenComplete(() => _refreshing = null);

  Future<void> _rotate() async {
    if (_refreshToken == null) throw const ApiFailure(401, 'unauthorized');
    try {
      _setTokens(
        await _send(
          'POST',
          '/auth/refresh',
          authenticated: false,
          body: {'refresh_token': _refreshToken},
        ),
      );
      if (_biometricEnabled) await biometrics.save(baseUrl, _refreshToken!);
    } catch (_) {
      if (_biometricEnabled) await biometrics.clear(baseUrl);
      _biometricEnabled = false;
      _accessToken = null;
      _refreshToken = null;
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      if (_refreshToken != null) {
        await _send(
          'POST',
          '/auth/logout',
          body: {'refresh_token': _refreshToken},
        );
      }
    } finally {
      _accessToken = null;
      _refreshToken = null;
      _biometricEnabled = false;
      await biometrics.clear(baseUrl);
    }
  }

  Future<Map<String, dynamic>> me() async =>
      Map<String, dynamic>.from(await _send('GET', '/auth/me') as Map);
  Future<Map<String, dynamic>> facility() async =>
      Map<String, dynamic>.from(await _send('GET', '/facilities/me') as Map);
  Future<dynamic> patients({int offset = 0}) =>
      _send('GET', '/patients?limit=20&offset=$offset');
  Future<dynamic> createPatient(Map<String, dynamic> demographics) =>
      _send('POST', '/patients', body: demographics);
  Future<dynamic> createEncounter(String patientId) =>
      _send('POST', '/encounters', body: {'patient_id': patientId});
  Future<dynamic> startEncounter(String id, int version) =>
      _send('POST', '/encounters/$id/start', body: {'version': version});
  Future<dynamic> submitTranscript(
    String id,
    String reference,
    String text, {
    String source = 'manual_text',
  }) => _send(
    'POST',
    '/encounters/$id/transcriptions',
    body: {
      'client_reference_id': reference,
      'transcript': text,
      'language': 'id-ID',
      'source': source,
    },
  );
  Future<dynamic> extract(
    String id,
    String requestId,
    String transcriptionId,
  ) => _send(
    'POST',
    '/encounters/$id/extractions',
    body: {'request_id': requestId, 'transcription_id': transcriptionId},
  );
  Future<dynamic> extraction(String id, String extractionId) =>
      _send('GET', '/encounters/$id/extractions/$extractionId');
  Future<dynamic> assessment(String id) =>
      _send('GET', '/encounters/$id/assessment');
  Future<dynamic> assessmentHistory(String id) =>
      _send('GET', '/encounters/$id/assessment/history');
  Future<dynamic> transcripts(String id) =>
      _send('GET', '/encounters/$id/transcriptions');
  Future<dynamic> saveAssessment(
    String id,
    int version,
    Map<String, dynamic> data, {
    bool initial = false,
  }) => _send(
    initial ? 'POST' : 'PATCH',
    '/encounters/$id/${initial ? 'assessments' : 'assessment'}',
    body: {'version': version, 'data': data},
  );
  Future<dynamic> verify(String id, String assessmentId, int version) => _send(
    'POST',
    '/encounters/$id/assessment/verify',
    body: {'assessment_id': assessmentId, 'version': version},
  );
  void close() => _client.close();
}

class ApiFailure implements Exception {
  const ApiFailure(this.status, this.code);
  final int status;
  final String code;
  @override
  String toString() => 'ApiFailure($status, $code)';
}
