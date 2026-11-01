import 'package:flutter/foundation.dart';

class AppConfig {
  // Release build (flutter build web --release) = production
  // Debug (flutter run) = local XAMPP
  static const String baseUrl = kReleaseMode
      ? "https://member-account-backend.onrender.com"
      : "http://localhost/memberaccount";
}