import 'package:flutter/material.dart';
import '../services/reviews_service.dart';
import '../screens/user_session.dart';
import '../theme/app_theme.dart';
import 'landing_section.dart';
import 'pill_button.dart';

/// Public "Member ratings & reviews" section for the landing page.
///
/// Reads `reviews_api.php` via [ReviewsService]: shows an aggregate rating,
/// a paginated card list, and — for a signed-in member — a submit form.
/// Additive; touches no other page state. Pass [onSignIn] so navigation
/// stays owned by the landing page.
class ReviewsSection extends StatefulWidget {
  final VoidCallback onSignIn;
  const ReviewsSection({super.key, required this.onSignIn});

  @override
  State<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<ReviewsSection> {
  final List<Map<String, dynamic>> _reviews = [];
  int _page = 1;
  int _totalPages = 1;
  int _count = 0;
  double _average = 0;
  bool _loading = true;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _page = 1;
      });
    } else {
      setState(() => _loadingMore = true);
    }

    final res = await ReviewsService.listReviews(page: reset ? 1 : _page + 1);
    if (!mounted) return;

    if (res['success'] == true) {
      final list = (res['reviews'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      setState(() {
        if (reset) {
          _reviews
            ..clear()
            ..addAll(list);
          _page = 1;
        } else {
          _reviews.addAll(list);
          _page += 1;
        }
        _count = int.tryParse('${res['count']}') ?? _count;
        _average = double.tryParse('${res['average']}') ?? _average;
        _totalPages = int.tryParse('${res['total_pages']}') ?? _totalPages;
      });
    }
    setState(() {
      _loading = false;
      _loadingMore = false;
    });
  }

  Future<void> _openSubmitSheet() async {
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => const _SubmitReviewSheet(),
    );
    if (submitted == true) _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = UserSession.instance.dbMemberId != null;
    final w = MediaQuery.of(context).size.width;
    final cols = w < 720 ? 1 : (w < 1100 ? 2 : 3);

    return LandingSection(
      eyebrow: 'Member ratings & reviews',
      title: 'What our members say',
      eyebrowColor: AppColors.cyan,
      background: AppColors.darkBg,
      child: Column(
        children: [
          // Aggregate
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            children: [
              Text(_average > 0 ? _average.toStringAsFixed(1) : '—',
                  style: AppText.pageTitle(size: 34)),
              _Stars(rating: _average.round(), size: 22),
              Text(
                'based on $_count review${_count == 1 ? '' : 's'}',
                style: AppText.bodyText(color: AppColors.textMutedOnDark),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (loggedIn)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: PillButton('Write a review',
                  onPressed: _openSubmitSheet, icon: Icons.rate_review_outlined),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: PillButton('Sign in to leave a review',
                  onPressed: widget.onSignIn,
                  variant: PillVariant.outline,
                  icon: Icons.login),
            ),
          const SizedBox(height: 36),

          if (_loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            )
          else if (_reviews.isEmpty)
            Text('No reviews yet — be the first.',
                style: AppText.bodyText(color: AppColors.textMutedOnDark))
          else ...[
            GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
              childAspectRatio: cols == 1 ? 2.4 : 1.15,
              children: [for (final r in _reviews) _ReviewCard(review: r)],
            ),
            if (_page < _totalPages) ...[
              const SizedBox(height: 28),
              PillButton(
                _loadingMore ? 'Loading…' : 'Load more reviews',
                onPressed: _loadingMore ? null : () => _load(),
                variant: PillVariant.outline,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final name = '${review['name'] ?? 'Member'}';
    final rating = int.tryParse('${review['rating']}') ?? 5;
    final comment = '${review['comment'] ?? ''}';
    final date = _fmtDate('${review['created_at'] ?? ''}');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.darkBorder),
        boxShadow: AppColors.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Stars(rating: rating, size: 16),
          const SizedBox(height: 12),
          Expanded(
            child: Text('"$comment"',
                style: AppText.bodyText(
                    size: 13.5, height: 1.55, color: AppColors.textMutedOnDark),
                overflow: TextOverflow.fade),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: AppColors.cyanTint,
                child: Text(name.characters.first,
                    style: AppText.badgeLabel(
                        color: const Color(0xFF0E7490), weight: FontWeight.w800)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(name,
                    style: AppText.sectionTitle(size: 13.5, color: const Color(0xFFE9EAEE))),
              ),
              if (date.isNotEmpty)
                Text(date, style: AppText.bodySmall(color: AppColors.textMutedOnDark)),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmtDate(String raw) {
    final d = DateTime.tryParse(raw);
    if (d == null) return '';
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${m[d.month - 1]} ${d.year}';
  }
}

class _Stars extends StatelessWidget {
  final int rating;
  final double size;
  const _Stars({required this.rating, required this.size});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: AppColors.gold,
        ),
      ),
    );
  }
}

/// The signed-in submit form, shown in a bottom sheet.
class _SubmitReviewSheet extends StatefulWidget {
  const _SubmitReviewSheet();

  @override
  State<_SubmitReviewSheet> createState() => _SubmitReviewSheetState();
}

class _SubmitReviewSheetState extends State<_SubmitReviewSheet> {
  int _rating = 0;
  final _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final memberId = UserSession.instance.dbMemberId;
    if (memberId == null) return;
    if (_rating < 1) {
      _snack('Please pick a star rating.');
      return;
    }
    if (_controller.text.trim().length < 4) {
      _snack('Please write a short comment.');
      return;
    }
    setState(() => _submitting = true);
    final res = await ReviewsService.submitReview(
      memberId: memberId,
      rating: _rating,
      comment: _controller.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    _snack('${res['message'] ?? (res['success'] == true ? 'Submitted.' : 'Failed.')}');
    if (res['success'] == true) Navigator.of(context).pop(true);
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final name = UserSession.instance.fullName;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.darkBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('Write a review',
              style: AppText.sectionTitle(size: 18, color: const Color(0xFFE9EAEE))),
          const SizedBox(height: 4),
          Text('Posting as $name',
              style: AppText.bodySmall(color: AppColors.textMutedOnDark)),
          const SizedBox(height: 16),
          Row(
            children: List.generate(
              5,
              (i) => IconButton(
                onPressed: () => setState(() => _rating = i + 1),
                icon: Icon(
                  i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 34,
                  color: AppColors.gold,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 4,
            maxLength: 600,
            style: const TextStyle(color: Color(0xFFE9EAEE)),
            decoration: InputDecoration(
              hintText: 'Tell other members about your experience…',
              hintStyle: const TextStyle(color: AppColors.textMutedOnDark),
              filled: true,
              fillColor: AppColors.darkBg,
              counterStyle: const TextStyle(color: AppColors.textMutedOnDark),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.darkBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cyan, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          PillButton(
            _submitting ? 'Submitting…' : 'Submit review',
            expand: true,
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}
