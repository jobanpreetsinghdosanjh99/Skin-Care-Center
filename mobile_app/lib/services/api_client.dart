import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
}

class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri uri(String path, [Map<String, String>? query]) => Uri.parse(
    '${ApiConfig.baseUrl}$path',
  ).replace(queryParameters: query);

  Future<dynamic> get(String path, [Map<String, String>? query]) async {
    final response = await _client.get(uri(path, query));
    _ensureOk(response);
    return response.body.isEmpty ? null : jsonDecode(response.body);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body, {int expected = 200}) async {
    final response = await _client.post(
      uri(path),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    _ensureOk(response, expected: expected);
    return response.body.isEmpty ? null : jsonDecode(response.body);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final response = await _client.put(
      uri(path),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    _ensureOk(response);
    return response.body.isEmpty ? null : jsonDecode(response.body);
  }

  Future<void> delete(String path) async {
    final response = await _client.delete(uri(path));
    _ensureOk(response, expected: 204);
  }

  void _ensureOk(http.Response response, {int expected = 200}) {
    if (response.statusCode != expected) {
      throw ApiException('Request failed (${response.statusCode}): ${response.body}');
    }
  }
}
