// ============================================================
// food_search_service.dart
// Calls food_search_api.php to search USDA FoodData Central for
// food name / macro autocomplete suggestions.
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;

class FoodSearchService {
  static const String apiUrl =
      "https://member-account-backend.onrender.com/food_search_api.php";

  static Future<Map<String, dynamic>> searchFoods(String query) async {
    try {
      final response = await http
          .get(Uri.parse("$apiUrl?query=${Uri.encodeQueryComponent(query)}"));
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }
}
