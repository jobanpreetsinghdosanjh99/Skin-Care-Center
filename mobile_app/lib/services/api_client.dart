import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
}

/// Holds the current session's bearer token in memory (and mirrors it to
/// persistent storage via [AuthApi]) so every [ApiClient] call can attach
/// `Authorization: Bearer <token>` without threading it through every
/// screen/widget individually.
class AuthSession {
  AuthSession._();

  static String? _token;
  static String? _role;

  static String? get token => _token;
  static String? get role => _role;

  static bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  /// 'manager' accounts get restricted access (Patients + Medicines fully,
  /// Prescriptions view-only); every other role (admin, doctor, ...) keeps
  /// full access, matching the backend's permission checks.
  static bool get isManager => _role == 'manager';
  static bool get isAdmin => _role == 'admin';
  static bool get canViewSales => _role == 'admin' || _role == 'doctor';

  static void setToken(String? token) {
    _token = token;
  }

  static void setRole(String? role) {
    _role = role;
  }

  /// Fired whenever the session becomes unauthenticated (explicit logout or
  /// a 401 from the backend), so the UI can drop back to the login screen.
  static final loggedOut = _LoggedOutSignal();
}

class _LoggedOutSignal {
  final List<void Function()> _listeners = [];

  void addListener(void Function() listener) => _listeners.add(listener);

  void removeListener(void Function() listener) => _listeners.remove(listener);

  void notify() {
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }
}

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri uri(String path, [Map<String, String>? query]) =>
      Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: query);

  Map<String, String> _headers({bool json = false}) {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    final token = AuthSession.token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> get(String path, [Map<String, String>? query]) async {
    final response = await _client.get(uri(path, query), headers: _headers());
    _ensureOk(response);
    return response.body.isEmpty ? null : jsonDecode(response.body);
  }

  Future<dynamic> post(
    String path,
    Map<String, dynamic> body, {
    int expected = 200,
  }) async {
    final response = await _client.post(
      uri(path),
      headers: _headers(json: true),
      body: jsonEncode(body),
    );
    _ensureOk(response, expected: expected);
    return response.body.isEmpty ? null : jsonDecode(response.body);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final response = await _client.put(
      uri(path),
      headers: _headers(json: true),
      body: jsonEncode(body),
    );
    _ensureOk(response);
    return response.body.isEmpty ? null : jsonDecode(response.body);
  }

  Future<void> delete(String path) async {
    final response = await _client.delete(uri(path), headers: _headers());
    _ensureOk(response, expected: 204);
  }

  void _ensureOk(http.Response response, {int expected = 200}) {
    if (response.statusCode == 401) {
      AuthSession.setToken(null);
      AuthSession.loggedOut.notify();
    }
    if (response.statusCode != expected) {
      throw ApiException(
        'Request failed (${response.statusCode}): ${response.body}',
        statusCode: response.statusCode,
      );
    }
  }
}
