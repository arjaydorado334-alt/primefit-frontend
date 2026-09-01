import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ChatbotService {
  static const String _baseUrl = 'https://member-account-backend.onrender.com';

  static final List<Map<String, String>> _history = [];

  static Future<String> sendTextMessage(String text, {int? memberId}) async {
    final uri = Uri.parse('$_baseUrl/chatbot_api.php');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'message': text,
        'history': _history,
        'member_id': memberId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Chatbot error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Unknown chatbot error');
    }

    final reply = data['reply'] as String;

    _history.add({'role': 'user', 'content': text});
    _history.add({'role': 'assistant', 'content': reply});

    return reply;
  }

  static Future<String> sendImagesMessage(
    List<Uint8List> imagesBytes,
    List<String> filenames, {
    String caption = '',
  }) async {
    final uri = Uri.parse('$_baseUrl/chatbot_image_api.php');

    final request = http.MultipartRequest('POST', uri);
    request.fields['message'] = caption;

    for (var i = 0; i < imagesBytes.length; i++) {
      final filename = filenames[i];
      final lowerName = filename.toLowerCase();
      final mimeType = lowerName.endsWith('.png')
          ? 'image/png'
          : lowerName.endsWith('.webp')
              ? 'image/webp'
              : 'image/jpeg';

      request.files.add(http.MultipartFile.fromBytes(
        'images[]',
        imagesBytes[i],
        filename: filename,
        contentType: MediaType.parse(mimeType),
      ));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('Chatbot error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Unknown chatbot error');
    }

    return data['reply'] as String;
  }
}