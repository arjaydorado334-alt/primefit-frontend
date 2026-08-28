// ============================================================
// monthly_goals_service.dart
// Calls monthly_goals_api.php to fetch/set the member's current
// month's workout session goal.
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;

class MonthlyGoalsService {
  static const String apiUrl = "http://localhost/memberaccount/monthly_goals_api.php";

  static Future<Map<String, dynamic>> fetchGoal(int memberId) async {
    try {
      final response = await http.get(Uri.parse("$apiUrl?member_id=$memberId"));
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  static Future<Map<String, dynamic>> setTarget({
    required int memberId,
    required int targetSessions,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "member_id": memberId,
          "target_sessions": targetSessions,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }
}
