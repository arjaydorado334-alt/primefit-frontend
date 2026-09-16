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
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import '../config.dart';

class CompleteRegistrationService {
  // Built from AppConfig.baseUrl (see config.dart) instead of a
  // separately-hardcoded host, so this can't drift out of sync with the
  // rest of the app's services (login/register/plan/membership) again --
  // that drift (this pointed at a local http://127.0.0.1:8080 with no
  // server behind it) was the root cause of the registration step's
  // "Failed to fetch" connection error.
  static const String apiUrl =
      "${AppConfig.baseUrl}/complete_registration_api.php";

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

      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
        return {
          "success": false,
          "message": "Unexpected response from server.",
        };
      } catch (_) {
        // Body wasn't valid JSON on its own -- this happens when the PHP
        // script emits warnings/notices (e.g. a filesystem permission
        // error) before its actual json_encode() output, so the real JSON
        // is a trailing "{...}" buried after some HTML. Try to recover
        // just that trailing object so the server's real error message
        // (e.g. "Failed to save receipt image.") reaches the user instead
        // of a generic parse failure.
        final match = RegExp(r'\{.*\}\s*$', dotAll: true).firstMatch(response.body);
        if (match != null) {
          try {
            final recovered = jsonDecode(match.group(0)!);
            if (recovered is Map<String, dynamic>) return recovered;
          } catch (_) {
            // Fall through to the generic message below.
          }
        }
        debugPrint(
            'CompleteRegistrationService.register unreadable response '
            '(HTTP ${response.statusCode}): ${response.body}');
        return {
          "success": false,
          "message":
              "Server returned an unreadable response (HTTP ${response.statusCode}).",
        };
      }
    } catch (e) {
      // A transport-level failure (server unreachable, DNS failure, CORS
      // block, etc.) -- log the raw exception for developers, but hand the
      // user a plain-language message instead of the bare "ClientException:
      // Failed to fetch, uri=..." string.
      debugPrint('CompleteRegistrationService.register transport error: $e');
      return {
        "success": false,
        "message":
            "Could not reach the server. Please check your internet connection and try again.",
      };
    }
  }
}
