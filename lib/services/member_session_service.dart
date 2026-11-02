import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../screens/user_session.dart';
import 'chatbot_service.dart';
import 'session_token_storage.dart' as transient;

enum SessionRestoreResult { authenticated, signedOut, unavailable }

class MemberSessionService {
  static const _tokenKey = 'member_session_token';
  static const _memberKey = 'member_id';
  static final Uri _endpoint = Uri.parse('${AppConfig.baseUrl}/member_session_api.php');

  static Future<void> saveLogin(String token, int memberId, {bool rememberMe = false}) async {
    ChatbotService.clearHistory();
    final prefs = await SharedPreferences.getInstance();
    if (rememberMe) {
      await prefs.setString(_tokenKey, token);
      transient.clearTransientToken();
    } else {
      transient.writeTransientToken(token);
      await prefs.remove(_tokenKey);
    }
    await prefs.setInt(_memberKey, memberId);
  }

  static Future<SessionRestoreResult> restore({http.Client? client}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = transient.readTransientToken() ?? prefs.getString(_tokenKey);
      if (token == null || !RegExp(r'^[a-f0-9]{64}$').hasMatch(token)) {
        await prefs.remove(_tokenKey);
        await prefs.remove(_memberKey);
        transient.clearTransientToken();
        ChatbotService.clearHistory();
        UserSession.reset();
        return SessionRestoreResult.signedOut;
      }
      final headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
      final body = jsonEncode({'action': 'restore'});
      final response = await (client == null
          ? http.post(_endpoint, headers: headers, body: body)
          : client.post(_endpoint, headers: headers, body: body))
          .timeout(const Duration(seconds: 12));
      if (response.statusCode == 401) {
        await prefs.remove(_tokenKey);
        await prefs.remove(_memberKey);
        transient.clearTransientToken();
        ChatbotService.clearHistory();
        UserSession.reset();
        return SessionRestoreResult.signedOut;
      }
      if (response.statusCode != 200) return SessionRestoreResult.unavailable;
      final data = jsonDecode(response.body);
      if (data is! Map || data['success'] != true || data['member'] is! Map) {
        return SessionRestoreResult.unavailable;
      }
      final member = Map<String, dynamic>.from(data['member'] as Map);
      final id = int.tryParse('${member['member_id'] ?? member['MemberID']}');
      if (id == null || id <= 0) return SessionRestoreResult.unavailable;
      UserSession.reset();
      UserSession.instance.applyMemberResponse(member);
      await prefs.setInt(_memberKey, id);
      return SessionRestoreResult.authenticated;
    } catch (_) {
      return SessionRestoreResult.unavailable;
    }
  }

  static Future<void> signOut({http.Client? client}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = transient.readTransientToken() ?? prefs.getString(_tokenKey);
    transient.clearTransientToken();
    ChatbotService.clearHistory();
    await prefs.remove(_tokenKey);
    await prefs.remove(_memberKey);
    UserSession.reset();
    if (token == null || token.isEmpty) return;
    try {
      final headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
      final body = jsonEncode({'action': 'logout'});
      await (client == null
          ? http.post(_endpoint, headers: headers, body: body)
          : client.post(_endpoint, headers: headers, body: body))
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Local logout still completes when the server is unavailable.
    }
  }
}
