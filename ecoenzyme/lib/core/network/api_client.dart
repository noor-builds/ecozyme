import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiClient {
  ApiClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

  final http.Client _httpClient;

  String get _baseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  Future<Map<String, dynamic>> request(
    String path, {
    String method = 'GET',
    Map<String, Object?>? body,
  }) async {
    final accessToken =
        Supabase.instance.client.auth.currentSession?.accessToken;
    if (accessToken == null) {
      throw StateError('Sign in to connect to the Ecoenzyme server.');
    }

    final uri = Uri.parse(_baseUrl).resolve(path);
    final response = await _httpClient
        .send(
          http.Request(method, uri)
            ..headers.addAll({
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            })
            ..body = body == null ? '' : jsonEncode(body),
        )
        .then(http.Response.fromStream)
        .timeout(const Duration(seconds: 90));

    final Object? payload;
    try {
      payload = jsonDecode(response.body);
    } on FormatException {
      throw const FormatException(
        'The Ecoenzyme server returned an invalid response.',
      );
    }

    if (payload is! Map<String, dynamic>) {
      throw const FormatException(
        'The Ecoenzyme server returned an invalid response.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = payload['error'];
      throw Exception(
        message is String ? message : 'The server request failed.',
      );
    }
    return payload;
  }
}
