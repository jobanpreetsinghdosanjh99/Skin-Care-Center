import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

const _tokenPrefsKey = 'skc_auth_token';
const _rolePrefsKey = 'skc_auth_role';

class LoggedInUser {
  LoggedInUser({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    required this.clinicId,
  });

  factory LoggedInUser.fromJson(Map<String, dynamic> json) => LoggedInUser(
    userId: json['user_id'] as String,
    fullName: json['full_name'] as String,
    email: json['email'] as String,
    role: json['role'] as String,
    clinicId: json['clinic_id'] as String,
  );

  final String userId;
  final String fullName;
  final String email;
  final String role;
  final String clinicId;
}

class AuthApi {
  AuthApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// Logs in against the backend, stores the bearer token both in memory
  /// ([AuthSession]) and in [SharedPreferences] (so the session survives an
  /// app reload/relaunch), and returns the logged-in user's profile.
  Future<LoggedInUser> login(String email, String password) async {
    final data =
        await _client.post('/auth/login', {
              'email': email,
              'password': password,
            })
            as Map<String, dynamic>;

    final token = data['access_token'] as String;
    final user = LoggedInUser.fromJson(data);
    AuthSession.setToken(token);
    AuthSession.setRole(user.role);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenPrefsKey, token);
    await prefs.setString(_rolePrefsKey, user.role);

    return user;
  }

  /// Restores a previously stored session (if any) into [AuthSession] so the
  /// app can skip the login screen on relaunch. Returns whether a token was
  /// restored.
  Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenPrefsKey);
    if (token == null || token.isEmpty) return false;
    AuthSession.setToken(token);
    AuthSession.setRole(prefs.getString(_rolePrefsKey));
    return true;
  }

  Future<void> logout() async {
    AuthSession.setToken(null);
    AuthSession.setRole(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenPrefsKey);
    await prefs.remove(_rolePrefsKey);
  }
}
