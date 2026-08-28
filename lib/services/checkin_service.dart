// ============================================================
// checkin_service.dart
// Calls checkin_api.php to log a gym visit and deduct a credit
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;

class CheckinService {
  static const String apiUrl = "http://member-account-backend.infinityfreeapp.com/checkin_api.php";

  /// Preferred: check in using the member's signed, tamper-proof QR token.
  static Future<Map<String, dynamic>> checkInWithQr({required String qrData}) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"qr_data": qrData}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  /// Fallback: check in with a raw member_id (used only if no QR token
  /// is available yet, e.g. very old accounts created before this
  /// feature existed).
  static Future<Map<String, dynamic>> checkIn({required int memberId}) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"member_id": memberId}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }
}
