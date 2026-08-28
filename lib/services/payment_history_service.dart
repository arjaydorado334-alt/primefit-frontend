// ============================================================
// payment_history_service.dart
// Calls payment_history_api.php to fetch the member's real,
// complete payment history from the database.
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentHistoryService {
  static const String apiUrl = "http://localhost/memberaccount/payment_history_api.php";

  static Future<Map<String, dynamic>> fetchHistory(int memberId) async {
    try {
      final response = await http.get(Uri.parse("$apiUrl?member_id=$memberId"));
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }
}