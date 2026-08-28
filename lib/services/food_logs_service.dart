// ============================================================
// food_logs_service.dart
// Calls food_logs_api.php to list, add, and delete food log entries.
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;

class FoodLogsService {
  static const String apiUrl =
      "http://member-account-backend.infinityfreeapp.com/food_logs_api.php";

  static Future<Map<String, dynamic>> fetchLogs(int memberId,
      {DateTime? date}) async {
    try {
      final dateParam = date == null
          ? ""
          : "&date=${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final response =
          await http.get(Uri.parse("$apiUrl?member_id=$memberId$dateParam"));
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  static Future<Map<String, dynamic>> addEntry({
    required int memberId,
    required String foodName,
    required String mealType,
    required int calories,
    required double protein,
    required double carbs,
    required double fats,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "member_id": memberId,
          "food_name": foodName,
          "meal_type": mealType,
          "calories": calories,
          "protein": protein,
          "carbs": carbs,
          "fats": fats,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  static Future<Map<String, dynamic>> deleteEntry(
      int logId, int memberId) async {
    try {
      final response = await http
          .delete(Uri.parse("$apiUrl?log_id=$logId&member_id=$memberId"));
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }
}
