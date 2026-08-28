// ============================================================
// attendance_stats_service.dart
// Calls attendance_stats_api.php to fetch the member's real
// attendance history, used to power live stats on the Dashboard
// and Progress pages.
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;

class AttendanceStatsService {
  static const String apiUrl = "https://member-account-backend.onrender.com/attendance_stats_api.php";

  static Future<Map<String, dynamic>> fetchStats(int memberId) async {
    try {
      final response = await http.get(Uri.parse("$apiUrl?member_id=$memberId"));
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }
}