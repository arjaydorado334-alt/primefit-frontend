// ============================================================
// session_status_service.dart
// Calls session_status_api.php to poll for the member's LIVE
// session credit status -- used for real-time UI updates after
// an admin scans the member's QR at the front desk.
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;

class SessionStatusService {
  static const String apiUrl = "http://member-account-backend.infinityfreeapp.com/session_status_api.php";

  static Future<Map<String, dynamic>> fetchStatus(int memberId) async {
    try {
      final response = await http.get(Uri.parse("$apiUrl?member_id=$memberId"));
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }
}