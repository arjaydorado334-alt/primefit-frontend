// ============================================================
// plan_service.dart
// Fetches the real PlanID for each plan from get_plans.php
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;

class PlanService {
  // Update this to match where your PHP files live (see register_service.dart
  // for notes on localhost vs. your PC's IP address).
  static const String apiUrl = "https://member-account-backend.onrender.com/get_plans.php";

  /// Returns a map of { DurationLabel : PlanID }, e.g. { "1 Year": 4 }.
  /// Returns an empty map if the request fails -- callers should handle
  /// that gracefully (e.g. disable checkout, or retry).
  static Future<Map<String, int>> fetchPlanIdMap() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      final data = jsonDecode(response.body);

      if (data is Map && data["success"] == true && data["plans"] is List) {
        final Map<String, int> map = {};
        for (final p in data["plans"]) {
          final label = p["DurationLabel"]?.toString();
          final id = int.tryParse(p["PlanID"].toString());
          if (label != null && id != null) {
            map[label] = id;
          }
        }
        return map;
      }
      return {};
    } catch (e) {
      return {};
    }
  }
}
