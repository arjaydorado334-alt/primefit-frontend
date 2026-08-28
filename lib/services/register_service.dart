// ============================================================
// register_service.dart
// Sample Flutter code showing how to call register_api.php
// ============================================================
//
// 1. Add the http package to your pubspec.yaml:
//
//    dependencies:
//      http: ^1.2.0
//
// 2. Run: flutter pub get
//
// 3. Import and use the function below in your registration screen.

import 'dart:convert';
import 'package:http/http.dart' as http;

class RegisterService {
  // IMPORTANT: Update this URL to match where your PHP files live.
  //
  // - If you're running against the deployed backend:
  //     "https://member-account-backend.onrender.com/register_api.php"
  //   (Find your IP via `ipconfig` on Windows -> look for IPv4 Address)

  static const String apiUrl = "https://member-account-backend.onrender.com/register_api.php";

  static Future<Map<String, dynamic>> registerMember({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String phone = "",
    String dateOfBirth = "", // format: "YYYY-MM-DD"
    String address = "",
  }) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "first_name": firstName,
          "last_name": lastName,
          "email": email,
          "password": password,
          "phone": phone,
          "date_of_birth": dateOfBirth,
          "address": address,
        }),
      );

      // Decode the JSON response coming back from PHP
      final Map<String, dynamic> result = jsonDecode(response.body);
      return result;

    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }
}

// ============================================================
// Example usage inside a widget (e.g. a button's onPressed):
// ============================================================
//
// final result = await RegisterService.registerMember(
//   firstName: firstNameController.text,
//   lastName: lastNameController.text,
//   email: emailController.text,
//   password: passwordController.text,
//   phone: phoneController.text,
//   dateOfBirth: "2000-05-14",
//   address: addressController.text,
// );
//
// if (result["success"] == true) {
//   // Show success message, navigate to login screen, etc.
//   print("Registered! Member ID: ${result['member_id']}");
// } else {
//   // Show error message
//   print("Error: ${result['message']}");
// }
