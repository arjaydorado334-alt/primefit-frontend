// ============================================================
// personal_records_service.dart
// Calls personal_records_api.php to list, add, and delete PRs.
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;

class PersonalRecordsService {
  static const String apiUrl = "http://member-account-backend.infinityfreeapp.com/personal_records_api.php";

  static Future<Map<String, dynamic>> fetchRecords(int memberId) async {
    try {
      final response = await http.get(Uri.parse("$apiUrl?member_id=$memberId"));
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  static Future<Map<String, dynamic>> addRecord({
    required int memberId,
    required String exercise,
    required String muscle,
    required int weight,
    required int sets,
    required int reps,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "member_id": memberId,
          "exercise": exercise,
          "muscle": muscle,
          "weight": weight,
          "sets": sets,
          "reps": reps,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  static Future<Map<String, dynamic>> deleteRecord(int prId) async {
    try {
      final response = await http.delete(Uri.parse("$apiUrl?pr_id=$prId"));
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }
}
