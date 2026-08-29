// ============================================================
// login_service.dart
// Calls login_api.php to verify a member's email + password
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;

class LoginService {
  static const String apiUrl = "https://member-account-backend.onrender.com/login_api.php";

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }
}

/// Parses a JSON-encoded array of date strings (e.g. from
/// `Checkins.CheckedInDates`) into a list of [DateTime] objects.
/// Returns an empty list when the value is null, empty, or not a valid JSON array.
List<DateTime> parseVisitDates(dynamic val) {
  if (val == null) return [];
  final str = val.toString();
  if (str.isEmpty || str == 'null') return [];
  try {
    final decoded = jsonDecode(str);
    if (decoded is List) {
      return decoded.map((e) => DateTime.parse(e.toString())).toList();
    }
  } catch (_) {}
  return [];
}

// ============================================================
// Example usage inside your login screen:
// ============================================================
//
// final result = await LoginService.login(
//   email: emailController.text.trim(),
//   password: passwordController.text,
// );
//
// if (result["success"] == true) {
//   final member = result["member"];
//   // member["member_id"], member["first_name"], member["last_name"],
//   // member["email"], member["phone"], etc.
//   //
//   // Save these into your UserSession (like create_account.dart does
//   // after registration), then navigate to the dashboard:
//   //
//   // UserSession.instance.applyLogin(
//   //   memberId: member["member_id"].toString(),
//   //   firstName: member["first_name"],
//   //   lastName: member["last_name"],
//   //   email: member["email"],
//   //   phone: member["phone"] ?? "",
//   // );
//   // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MemberPortalScreen()));
// } else {
//   // Show result["message"] to the user (e.g. via a SnackBar)
// }
