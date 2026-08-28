// ============================================================
// body_metrics_service.dart
// Calls body_metrics_api.php to list, add, and delete BMI entries.
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;

class BodyMetricsService {
  static const String apiUrl =
      "http://localhost/memberaccount/body_metrics_api.php";

  static Future<Map<String, dynamic>> fetchHistory(int memberId) async {
    try {
      final response = await http.get(Uri.parse("$apiUrl?member_id=$memberId"));
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  static Future<Map<String, dynamic>> addEntry({
    required int memberId,
    required double weight,
    required double height,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "member_id": memberId,
          "weight": weight,
          "height": height,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  static Future<Map<String, dynamic>> deleteEntry(
      int metricId, int memberId) async {
    try {
      final response = await http
          .delete(Uri.parse("$apiUrl?metric_id=$metricId&member_id=$memberId"));
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }
}
