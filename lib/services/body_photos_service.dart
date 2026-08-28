// ============================================================
// body_photos_service.dart
// Calls body_photos_api.php to upload, list, and delete photos.
// ============================================================

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class BodyPhotosService {
  static const String apiUrl = "http://localhost/memberaccount/body_photos_api.php";

  static Future<Map<String, dynamic>> fetchPhotos(int memberId) async {
    try {
      final response = await http.get(Uri.parse("$apiUrl?member_id=$memberId"));
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  static Future<Map<String, dynamic>> upload({
    required int memberId,
    required Uint8List bytes,
    required String filename,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.fields['member_id'] = memberId.toString();

      final ext = filename.split('.').last.toLowerCase();
      final mimeSubtype = switch (ext) {
        'png' => 'png',
        'webp' => 'webp',
        _ => 'jpeg',
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

  static Future<Map<String, dynamic>> deletePhoto(int photoId) async {
    try {
      final response = await http.delete(Uri.parse("$apiUrl?photo_id=$photoId"));
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }
}
