// ============================================================
// billing_service.dart
// Calls billing_api.php?action=submit_receipt -- lets a member
// submit proof of a manual GCash/Maya payment for a plan. The
// membership stays inactive until an admin reviews the receipt.
//
// Sent as multipart/form-data so the receipt screenshot can be
// uploaded alongside the text fields. The image is passed as raw
// bytes (Uint8List) rather than a dart:io File, so this works on
// Flutter Web as well as desktop/mobile.
// ============================================================

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config.dart';

class BillingService {
  static final Uri _submitReceiptUrl =
      Uri.parse('${AppConfig.baseUrl}/billing_api.php?action=submit_receipt');

  /// POSTs the member's payment receipt for admin review.
  ///
  /// Fields: `member_id`, `plan_id`, `method`; file: `receipt`.
  /// Returns the decoded JSON body, or
  /// `{ "success": false, "message": "..." }` on a transport error.
  static Future<Map<String, dynamic>> submitReceipt({
    required int memberId,
    required int planId,
    required String method,
    required Uint8List receiptBytes,
    String receiptFileName = 'receipt.jpg',
  }) async {
    try {
      final request = http.MultipartRequest('POST', _submitReceiptUrl);
      request.fields['member_id'] = memberId.toString();
      request.fields['plan_id'] = planId.toString();
      request.fields['method'] = method;
      request.files.add(
        http.MultipartFile.fromBytes(
          'receipt',
          receiptBytes,
          filename: receiptFileName,
        ),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
        return {
          'success': false,
          'message': 'Unexpected response from server.',
        };
      } catch (_) {
        return {
          'success': false,
          'message':
              'Server returned an unreadable response (HTTP ${response.statusCode}).',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
}
