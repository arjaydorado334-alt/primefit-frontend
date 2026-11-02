import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../screens/user_session.dart';

class ChatbotService {
  static const String _baseUrl = 'https://member-account-backend.onrender.com';

  static final List<Map<String, String>> _history = [];
  static int _historyGeneration = 0;

  static void clearHistory() {
    _history.clear();
    _historyGeneration++;
  }

  /// Helper method to fetch member_id from local storage automatically
  static Future<int> _getMemberId(int? explicitMemberId) async {
    if (explicitMemberId != null && explicitMemberId > 0) {
      return explicitMemberId;
    }

    return UserSession.instance.dbMemberId ?? 0;
  }

  static Future<String> sendTextMessage(String text, {int? memberId}) async {
    final uri = Uri.parse('$_baseUrl/chatbot_api.php');
    
    // Automatically retrieve the stored member ID
    final activeMemberId = await _getMemberId(memberId);
    final historyGeneration = _historyGeneration;

    if (activeMemberId <= 0) {
      throw Exception('Member ID not found. Please log in again.');
    }

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'message': text,
        'history': _history,
        'member_id': activeMemberId,
      }),
    );

    Map<String, dynamic> data = {};
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Server error (${response.statusCode}): ${response.body}');
    }

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['error'] ?? 'Chatbot error: ${response.statusCode}');
    }

    final reply = data['reply'] as String;

    if (historyGeneration == _historyGeneration) {
      _history.add({'role': 'user', 'content': text});
      _history.add({'role': 'assistant', 'content': reply});
    }

    return reply;
  }

  static Future<String> sendImagesMessage(
    List<Uint8List> imagesBytes,
    List<String> filenames, {
    String caption = '',
    int? memberId,
  }) async {
    final uri = Uri.parse('$_baseUrl/chatbot_image_api.php');

    // Automatically retrieve the stored member ID
    final activeMemberId = await _getMemberId(memberId);

    if (activeMemberId <= 0) {
      throw Exception('Member ID not found. Please log in again.');
    }

    final request = http.MultipartRequest('POST', uri);
    request.fields['message'] = caption;
    request.fields['member_id'] = activeMemberId.toString();

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

    Map<String, dynamic> data = {};
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Server error (${response.statusCode}): ${response.body}');
    }

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['error'] ?? 'Chatbot error: ${response.statusCode}');
    }

    return data['reply'] as String;
  }
}
