import 'package:web/web.dart' as web;

const _key = 'primefit_member_session';

String? readTransientToken() => web.window.sessionStorage.getItem(_key);
void writeTransientToken(String token) => web.window.sessionStorage.setItem(_key, token);
void clearTransientToken() => web.window.sessionStorage.removeItem(_key);
