// ============================================================
// profile_picture_service.dart
// Uploads a profile picture (as bytes) to upload_profile_picture.php
// ============================================================

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ProfilePictureService {
  static const String apiUrl = "http://localhost/memberaccount/upload_profile_picture.php";

  static Future<Map<String, dynamic>> upload({
    required int memberId,
    required Uint8List bytes,
    required String filename,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.fields['member_id'] = memberId.toString();

      // Determine the correct content type from the file extension so
      // the upload is properly labeled (some HTTP clients otherwise
      // default to a generic "application/octet-stream").
      final ext = filename.split('.').last.toLowerCase();
      final mimeSubtype = switch (ext) {
        'png' => 'png',
        'webp' => 'webp',
        _ => 'jpeg', // covers jpg/jpeg and any other case
      };

      request.files.add(http.MultipartFile.fromBytes(
        'photo',
        bytes,
        filename: filename,
        contentType: MediaType('image', mimeSubtype),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }
}
