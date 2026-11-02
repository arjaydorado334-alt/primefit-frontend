import 'package:shared_preferences/shared_preferences.dart';

import 'session_token_storage.dart' as transient;

/// Adds the current signed-in member's bearer token to private member APIs.
class MemberApiAuth {
  static const tokenKey = 'member_session_token';

  static Future<String?> readToken() async {
    final token = transient.readTransientToken();
    if (token != null && token.isNotEmpty) return token;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(tokenKey);
    return saved != null && saved.isNotEmpty ? saved : null;
  }

  static Future<Map<String, String>> headers([
    Map<String, String> base = const {},
  ]) async {
    final result = Map<String, String>.from(base);
    final token = await readToken();
    if (token != null) result['Authorization'] = 'Bearer $token';
    return result;
  }
}
