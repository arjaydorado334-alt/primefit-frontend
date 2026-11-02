import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:primefit/screens/user_session.dart';
import 'package:primefit/services/member_session_service.dart';
import 'package:primefit/services/session_token_storage.dart' as transient;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final token = 'a' * 64;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    transient.clearTransientToken();
    UserSession.reset();
  });

  test('restores only after server validates the session', () async {
    await MemberSessionService.saveLogin(token, 99);
    expect((await SharedPreferences.getInstance()).getString('member_session_token'), isNull);
    expect(transient.readTransientToken(), token);
    final client = MockClient((request) async {
      expect(request.headers['authorization'], 'Bearer $token');
      expect(jsonDecode(request.body)['action'], 'restore');
      return http.Response(jsonEncode({'success': true, 'member': {
        'member_id': 42, 'first_name': 'Test', 'last_name': 'Member',
        'email': 'test@example.invalid', 'member_since': '2026-01-01',
        'session_credits': 30, 'sessions_used': 1,
      }}), 200);
    });
    expect(await MemberSessionService.restore(client: client), SessionRestoreResult.authenticated);
    expect(UserSession.instance.dbMemberId, 42);
    expect(UserSession.instance.sessionsUsed, 1);
    expect((await SharedPreferences.getInstance()).getInt('member_id'), 42);
    client.close();
  });

  test('a stored member ID alone never restores a session', () async {
    SharedPreferences.setMockInitialValues({'member_id': 42});
    final client = MockClient((_) async => throw StateError('Unexpected request'));
    expect(await MemberSessionService.restore(client: client), SessionRestoreResult.signedOut);
    expect((await SharedPreferences.getInstance()).getInt('member_id'), isNull);
    client.close();
  });

  test('expired or revoked session is cleared', () async {
    await MemberSessionService.saveLogin(token, 42);
    final client = MockClient((_) async => http.Response('{}', 401));
    expect(await MemberSessionService.restore(client: client), SessionRestoreResult.signedOut);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('member_session_token'), isNull);
    expect(transient.readTransientToken(), isNull);
    expect(prefs.getInt('member_id'), isNull);
    client.close();
  });

  test('server failure does not erase the saved session', () async {
    await MemberSessionService.saveLogin(token, 42, rememberMe: true);
    final client = MockClient((_) async => http.Response('{}', 503));
    expect(await MemberSessionService.restore(client: client), SessionRestoreResult.unavailable);
    expect((await SharedPreferences.getInstance()).getString('member_session_token'), token);
    client.close();
  });

  test('keep me logged in persists the token for the next browser session', () async {
    await MemberSessionService.saveLogin(token, 42, rememberMe: true);
    expect(transient.readTransientToken(), isNull);
    expect((await SharedPreferences.getInstance()).getString('member_session_token'), token);
    final client = MockClient((_) async => http.Response(jsonEncode({'success': true, 'member': {
      'member_id': 42, 'first_name': 'Test', 'last_name': 'Member',
      'email': 'test@example.invalid', 'member_since': '2026-01-01',
    }}), 200));
    expect(await MemberSessionService.restore(client: client), SessionRestoreResult.authenticated);
    client.close();
  });

  test('without keep me logged in, closing the tab ends the local session', () async {
    await MemberSessionService.saveLogin(token, 42);
    transient.clearTransientToken(); // Browser session storage is cleared on close.
    final client = MockClient((_) async => throw StateError('Unexpected request'));
    expect(await MemberSessionService.restore(client: client), SessionRestoreResult.signedOut);
    client.close();
  });

  test('logout clears member data and asks server to revoke token', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
    await MemberSessionService.saveLogin(token, 42);
    UserSession.instance.dbMemberId = 42;
    final client = MockClient((request) async {
      expect(request.headers['authorization'], 'Bearer $token');
      expect(jsonDecode(request.body)['action'], 'logout');
      return http.Response('{"success":true}', 200);
    });
    await MemberSessionService.signOut(client: client);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('member_session_token'), isNull);
    expect(transient.readTransientToken(), isNull);
    expect(prefs.getInt('member_id'), isNull);
    expect(prefs.getString('theme_mode'), 'dark');
    expect(UserSession.instance.dbMemberId, isNull);
    client.close();
  });

  test('offline logout still clears the local session', () async {
    await MemberSessionService.saveLogin(token, 42, rememberMe: true);
    UserSession.instance.dbMemberId = 42;
    final client = MockClient((_) async => throw Exception('Offline'));
    await MemberSessionService.signOut(client: client);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('member_session_token'), isNull);
    expect(prefs.getInt('member_id'), isNull);
    expect(UserSession.instance.dbMemberId, isNull);
    client.close();
  });
}
