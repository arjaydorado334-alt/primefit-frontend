// ============================================================
// programs_service.dart
// Fetches the full workout programs catalog (with nested days
// and exercises) from programs_api.php.
// ============================================================

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ProgramsService {
  static const String apiUrl = "http://localhost/memberaccount/programs_api.php";

  static Future<Map<String, dynamic>> fetchPrograms() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  /// Creates a new custom program with its days/exercises, and an
  /// optional cover image (diagram/photo).
  ///
  /// [days] should look like:
  /// [
  ///   {
  ///     "label": "Day A - Focus",
  ///     "exercises": [
  ///       {"name": "Push Up", "tip": "", "sets": "3", "reps": "10-12", "rest": "60s"},
  ///       ...
  ///     ]
  ///   },
  ///   ...
  /// ]
  static Future<Map<String, dynamic>> createProgram({
    required int memberId,
    required String programName,
    required String muscleGroup,
    required String description,
    required String durationRange,
    required int frequencyPerWeek,
    required String level,
    required List<Map<String, dynamic>> days,
    Uint8List? imageBytes,
    String? imageFilename,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.fields['member_id'] = memberId.toString();
      request.fields['program_name'] = programName;
      request.fields['muscle_group'] = muscleGroup;
      request.fields['description'] = description;
      request.fields['duration_range'] = durationRange;
      request.fields['frequency_per_week'] = frequencyPerWeek.toString();
      request.fields['level'] = level;
      request.fields['days_json'] = jsonEncode(days);

      if (imageBytes != null && imageFilename != null) {
        final ext = imageFilename.split('.').last.toLowerCase();
        final mimeSubtype = switch (ext) {
          'png' => 'png',
          'webp' => 'webp',
          _ => 'jpeg',
        };
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: imageFilename,
          contentType: MediaType('image', mimeSubtype),
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }
}
