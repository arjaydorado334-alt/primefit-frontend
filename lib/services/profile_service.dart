// ============================================================
// profile_service.dart
// Calls profile_api.php to fetch and update a member's profile
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfileService {
  static const String apiUrl = "https://member-account-backend.onrender.com/profile_api.php";

  static Future<Map<String, dynamic>> fetchProfile(int memberId) async {
    try {
      final response = await http.get(Uri.parse("$apiUrl?member_id=$memberId"));
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    required int memberId,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String dateOfBirth, // expected format: "YYYY-MM-DD" or ""
    required String address,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "member_id": memberId,
          "first_name": firstName,
          "last_name": lastName,
          "email": email,
          "phone": phone,
          "date_of_birth": dateOfBirth,
          "address": address,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }
}
