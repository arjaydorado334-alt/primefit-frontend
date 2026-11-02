String? _token;

String? readTransientToken() => _token;
void writeTransientToken(String token) => _token = token;
void clearTransientToken() => _token = null;
