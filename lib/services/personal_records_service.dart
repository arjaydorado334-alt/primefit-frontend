// ============================================================
// personal_records_service.dart
// Calls personal_records_api.php to list, add, and delete PRs.
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'member_api_auth.dart';

class PersonalRecordsService {
  static const String apiUrl = "${AppConfig.baseUrl}/personal_records_api.php";

  static Future<Map<String, dynamic>> fetchRecords(int memberId) async {
    try {
      final response = await http.get(Uri.parse("$apiUrl?member_id=$memberId"), headers: await MemberApiAuth.headers());
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  static Future<Map<String, dynamic>> addRecord({
    required int memberId,
    required String exercise,
    required String muscle,
    required double weight,
    required int sets,
    required int reps,
    // Optional -- only relevant for time-based exercises (planks, cardio).
    int? durationSeconds,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: await MemberApiAuth.headers({"Content-Type": "application/json"}),
        body: jsonEncode({
          "member_id": memberId,
          "exercise": exercise,
          "muscle": muscle,
          "weight": weight,
          "sets": sets,
          "reps": reps,
          "duration_seconds": durationSeconds,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  static Future<Map<String, dynamic>> deleteRecord(int prId) async {
    try {
      final response = await http.delete(Uri.parse("$apiUrl?pr_id=$prId"), headers: await MemberApiAuth.headers());
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }
}
