// ============================================================
// membership_service.dart
// Calls membership_api.php to create a Membership + Payment record
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;

class MembershipService {
  static const String apiUrl = "http://localhost/memberaccount/membership_api.php";

  static Future<Map<String, dynamic>> createMembership({
    required int memberId,
    required int planId,
    required String paymentMethod,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "member_id": memberId,
          "plan_id": planId,
          "payment_method": paymentMethod,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }
}
