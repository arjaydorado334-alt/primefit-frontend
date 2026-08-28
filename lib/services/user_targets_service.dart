// ============================================================
// user_targets_service.dart
// Calls user_targets_api.php to fetch/set the member's daily
// calorie & macro targets and target weight.
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;

class UserTargetsService {
  static const String apiUrl =
      "https://member-account-backend.onrender.com/user_targets_api.php";

  static Future<Map<String, dynamic>> fetchTargets(int memberId) async {
    try {
      final response = await http.get(Uri.parse("$apiUrl?member_id=$memberId"));
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  static Future<Map<String, dynamic>> saveTargets({
    required int memberId,
    required int calorieTarget,
    double? proteinTarget,
    double? carbsTarget,
    double? fatsTarget,
    double? targetWeight,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "member_id": memberId,
          "daily_calorie_target": calorieTarget,
          "daily_protein_target": proteinTarget,
          "daily_carbs_target": carbsTarget,
          "daily_fats_target": fatsTarget,
          "target_weight": targetWeight,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }
}
