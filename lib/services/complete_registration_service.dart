// ============================================================
// complete_registration_service.dart
// Calls complete_registration_api.php -- creates the Member,
// Membership, and Payment records together in one API call,
// only once the customer has confirmed payment.
//
// UPDATED: sends the request as multipart/form-data so the member's
// payment receipt image (proof of payment) can be uploaded together
// with the registration data. The receipt is passed as raw bytes
// (Uint8List) rather than a dart:io File, since File is not
// supported on Flutter Web -- this version works on web, desktop,
// and mobile alike.
// ============================================================

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class CompleteRegistrationService {
  static const String apiUrl =
      "http://localhost/memberaccount/complete_registration_api.php";

  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required int planId,
    required String paymentMethod,
    String phone = "",
    String dateOfBirth = "",
    String address = "",
    // NEW: the proof-of-payment screenshot/photo picked on the QR payment
    // screen, as raw bytes (works on web + desktop + mobile). Optional
    // here (defaults to null) so existing callers that don't pass it yet
    // won't break, but the API should treat it as required for the
    // "Pending confirmation" flow.
    Uint8List? receiptBytes,
    String receiptFileName = "receipt.jpg",
  }) async {
    try {
      final request = http.MultipartRequest("POST", Uri.parse(apiUrl));

      request.fields["first_name"] = firstName;
      request.fields["last_name"] = lastName;
      request.fields["email"] = email;
      request.fields["password"] = password;
      request.fields["phone"] = phone;
      request.fields["date_of_birth"] = dateOfBirth;
      request.fields["address"] = address;
      request.fields["plan_id"] = planId.toString();
      request.fields["payment_method"] = paymentMethod;

      if (receiptBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            "receipt",
            receiptBytes,
            filename: receiptFileName,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }
}
