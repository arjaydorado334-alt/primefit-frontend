// ============================================================
// body_metrics_service.dart
// Calls body_metrics_api.php to list, add, and delete BMI entries.
// ============================================================

   import 'dart:convert';
import '../config.dart';
import 'package:http/http.dart' as http;
import 'member_api_auth.dart';

class BodyMetricsService {
  static const String apiUrl =
     "${AppConfig.baseUrl}/body_metrics_api.php";

  static Future<Map<String, dynamic>> fetchHistory(int memberId) async {
    try {
      final response = await http.get(Uri.parse("$apiUrl?member_id=$memberId"), headers: await MemberApiAuth.headers());
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
        headers: await MemberApiAuth.headers({"Content-Type": "application/json"}),
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
          .delete(Uri.parse("$apiUrl?metric_id=$metricId&member_id=$memberId"), headers: await MemberApiAuth.headers());
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }
}
