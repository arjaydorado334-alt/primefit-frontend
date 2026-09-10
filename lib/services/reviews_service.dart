// ============================================================
// reviews_service.dart
// Talks to reviews_api.php — the member ratings & reviews shown on
// the public landing page. Same shape as billing_service.dart:
// every call returns the decoded JSON map, or
// { "success": false, "message": "..." } on a transport error.
//
// A compile-time mock (`--dart-define=REVIEWS_MOCK=true`) lets the
// landing page render real-looking data before reviews_api.php is
// deployed. Remove/ignore once the endpoint is live.
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class ReviewsService {
  static const bool _mock =
      bool.fromEnvironment('REVIEWS_MOCK', defaultValue: false);

  static Uri _url(String query) =>
      Uri.parse('${AppConfig.baseUrl}/reviews_api.php?$query');

  /// GET list_reviews. Returns:
  /// `{ success, reviews: [{ReviewID, name, rating, comment, created_at}],
  ///    count, average, page, total_pages }`
  static Future<Map<String, dynamic>> listReviews({
    int page = 1,
    int limit = 6,
  }) async {
    if (_mock) return _mockList(page, limit);
    try {
      final res = await http
          .get(_url('action=list_reviews&page=$page&limit=$limit'))
          .timeout(const Duration(seconds: 12));
      return _decode(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  /// POST submit_review. Returns `{ success, message }`.
  static Future<Map<String, dynamic>> submitReview({
    required int memberId,
    required int rating,
    required String comment,
  }) async {
    if (_mock) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return {
        'success': true,
        'message': 'Thanks! Your review has been submitted for approval.',
      };
    }
    try {
      final res = await http
          .post(
            _url('action=submit_review'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'member_id': memberId,
              'rating': rating,
              'comment': comment,
            }),
          )
          .timeout(const Duration(seconds: 12));
      return _decode(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static Map<String, dynamic> _decode(http.Response res) {
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'success': false, 'message': 'Unexpected response from server.'};
    } catch (_) {
      return {
        'success': false,
        'message': 'Server returned an unreadable response (HTTP ${res.statusCode}).',
      };
    }
  }

  // ---- mock data -----------------------------------------------------
  static final List<Map<String, dynamic>> _mockReviews = [
    {
      'ReviewID': 1,
      'name': 'Jamie R.',
      'rating': 5,
      'comment':
          'Coaches actually check in on you. Down 12 kg and training pain-free.',
      'created_at': '2026-08-21 09:12:00',
    },
    {
      'ReviewID': 2,
      'name': 'Marco D.',
      'rating': 5,
      'comment': 'Went from never lifting to a 100 kg deadlift. Great community.',
      'created_at': '2026-08-14 18:40:00',
    },
    {
      'ReviewID': 3,
      'name': 'Alyssa T.',
      'rating': 4,
      'comment': 'Clean equipment, friendly staff, never feels intimidating.',
      'created_at': '2026-07-30 07:05:00',
    },
    {
      'ReviewID': 4,
      'name': 'Ken P.',
      'rating': 5,
      'comment': 'Best value gym in Taguig. The 7-month plan pays for itself.',
      'created_at': '2026-07-18 20:15:00',
    },
    {
      'ReviewID': 5,
      'name': 'Bea M.',
      'rating': 5,
      'comment': 'Open early, open late — fits around my shift schedule.',
      'created_at': '2026-07-02 06:22:00',
    },
    {
      'ReviewID': 6,
      'name': 'Rico S.',
      'rating': 4,
      'comment': 'Solid free-weights area. Would love a few more benches.',
      'created_at': '2026-06-25 17:48:00',
    },
    {
      'ReviewID': 7,
      'name': 'Tin G.',
      'rating': 5,
      'comment': 'The trainers meet you where you are. Highly recommend.',
      'created_at': '2026-06-10 12:00:00',
    },
  ];

  static Map<String, dynamic> _mockList(int page, int limit) {
    final count = _mockReviews.length;
    final avg = _mockReviews
            .map((r) => r['rating'] as int)
            .fold<int>(0, (a, b) => a + b) /
        count;
    final start = (page - 1) * limit;
    final slice = start >= count
        ? <Map<String, dynamic>>[]
        : _mockReviews.sublist(start, (start + limit).clamp(0, count));
    return {
      'success': true,
      'reviews': slice,
      'count': count,
      'average': double.parse(avg.toStringAsFixed(1)),
      'page': page,
      'total_pages': (count / limit).ceil(),
    };
  }
}
