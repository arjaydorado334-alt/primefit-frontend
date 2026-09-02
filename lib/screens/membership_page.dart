import 'dart:convert';
// Web-only download of the per-transaction receipt file. This app ships only
// as a Flutter web build (Chrome), so dart:html is the right tool here; the
// receipt is rendered from that transaction's own recorded data.
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

import 'package:flutter/material.dart';
import '../data/membership_plans.dart';
import '../screens/user_session.dart';
import '../services/membership_service.dart';
import '../services/payment_history_service.dart';
import '../theme/app_theme.dart';
import '../widgets/status_alert_banner.dart';
import 'submit_receipt_page.dart';

/// Dark-mode-aware surface/text tokens for this screen. `sync(context)` is
/// called once at the top of `build()` (and inside each dialog builder,
/// which gets its own context) to snapshot the current brightness before
/// any of these getters are read.
class _Colors {
  static bool _dark = false;
  static void sync(BuildContext c) => _dark = Theme.of(c).brightness == Brightness.dark;

  static Color get bg => _dark ? AppColors.darkBg : AppColors.portalPageBg;
  static Color get cardBg => _dark ? AppColors.darkCard : Colors.white;
  static List<BoxShadow> get cardShadow =>
      _dark ? const [] : AppColors.softCardShadow;
  static Color cardBgFor(Color? accent) =>
      (accent == null || _dark) ? cardBg : AppColors.cardTint(accent);
  static Color cardBorderFor(Color? accent) => (accent == null || _dark)
      ? cardBorder
      : AppColors.cardTintBorder(accent);
  static Color get cardBorder => _dark ? AppColors.darkBorder : Colors.grey.shade200;
  static Color get surfaceAlt => _dark ? const Color(0xFF1C1D22) : Colors.grey.shade50;
  static Color get borderMuted => _dark ? AppColors.darkBorder : Colors.grey.shade300;
  static Color get textSecondary => _dark ? AppColors.textMutedOnDark : Colors.grey.shade600;
  static Color get textMuted => _dark ? AppColors.textMutedOnDark : Colors.grey.shade500;
  static Color get textBody => _dark ? AppColors.textMutedOnDark : Colors.grey.shade800;
  static Color get iconMuted => _dark ? AppColors.textMutedOnDark : Colors.grey.shade700;
  static Color get planHighlightBg => _dark ? const Color(0xFF0E3A42) : Colors.cyan.shade50;
}

class MembershipPage extends StatefulWidget {
  const MembershipPage({super.key});

  @override
  State<MembershipPage> createState() => _MembershipPageState();
}

class _MembershipPageState extends State<MembershipPage> {
  int selectedPlanIndex = 2;

  bool hasActiveMembership = true;
  int currentPlanIndex = 2;
  int membershipDurationIndex = 0;
  DateTime membershipStartDate = DateTime.now().subtract(const Duration(days: 32));
  late final DateTime today;
  bool _isProcessingPurchase = false;

  final List<String> durationNames = const ['4 Months', '5 Months', '7 Months', '1 Year'];

  final List<MembershipPlan> plans = kMembershipPlans;

  List<List<String>> paymentHistory = [
    ['June 10, 2026', '1 Year', '₱4,800', 'Cash', 'Paid'],
    ['May 10, 2026', '7 Months', '₱3,500', 'Cash', 'Paid'],
    ['April 10, 2026', '1 Year', '₱4,800', 'GCash', 'Paid'],
  ];

  @override
  void initState() {
    super.initState();
    today = DateTime.now();
    _loadFromSession();
    _loadPaymentHistory();
  }

  Future<void> _loadPaymentHistory() async {
    final memberId = UserSession.instance.dbMemberId;
    if (memberId == null) return;

    final result = await PaymentHistoryService.fetchHistory(memberId);
    if (!mounted) return;

    if (result['success'] == true && result['history'] is List) {
      final rows = (result['history'] as List).map<List<String>>((h) {
        return [
          _formatDate(DateTime.tryParse(h['date']?.toString() ?? '') ?? DateTime.now()),
          h['plan']?.toString() ?? '—',
          '₱${_formatPrice((h['amount'] as num?)?.round() ?? 0)}',
          h['method']?.toString() ?? '',
          h['status']?.toString() ?? '',
        ];
      }).toList();

      setState(() => paymentHistory = rows);
    }
  }

  void _loadFromSession() {
    final session = UserSession.instance;
    setState(() {
      hasActiveMembership = session.membershipStatus == 'Active';
      membershipStartDate = session.memberSince;
      membershipDurationIndex = _durationIndexForPlan(session.membershipPlan);
      currentPlanIndex = membershipDurationIndex;
      selectedPlanIndex = currentPlanIndex;
    });
  }

  int _durationIndexForPlan(String plan) {
    switch (plan) {
      case '4 Months':
        return 0;
      case '5 Months':
        return 1;
      case '7 Months':
        return 2;
      case '1 Year':
        return 3;
      default:
        return 2;
    }
  }

  // Payment history is now fetched via _loadPaymentHistory() from the
  // real Payments table, not reconstructed from the current session.

  void _confirmCancelMembership() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel membership?'),
        content: const Text(
          'Are you sure you want to cancel your membership? This action cannot be undone and no refund will be issued for the remaining period.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep membership'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                hasActiveMembership = false;
                UserSession.instance.membershipStatus = 'Cancelled';
              });
            },
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );
  }

  void _startPurchaseFlow(int planIndex) {
    final plan = plans[planIndex];
    final price = plan.price;

    showDialog(
      context: context,
      builder: (context) {
        _Colors.sync(context);
        return AlertDialog(
        title: const Text('Select payment method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${plan.duration}  ·  ₱${_formatPrice(price)}',
              style: TextStyle(fontSize: 13, color: _Colors.textSecondary),
            ),
            const SizedBox(height: 16),
            _paymentMethodTile('GCash', Colors.blue, planIndex),
            _paymentMethodTile('Maya', Colors.green, planIndex),
            _paymentMethodTile('InstaPay', Colors.indigo, planIndex),
            _paymentMethodTile('QRPh', Colors.deepOrange, planIndex),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      );
      },
    );
  }

  Widget _paymentMethodTile(String method, MaterialColor color, int planIndex) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton(
        onPressed: () {
          Navigator.pop(context);
          _showQrPaymentDialog(planIndex, method, color);
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          alignment: Alignment.centerLeft,
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.qr_code_2, size: 16, color: color.shade700),
            ),
            const SizedBox(width: 12),
            Text(
              method,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  void _showQrPaymentDialog(int planIndex, String method, MaterialColor color) {
    final plan = plans[planIndex];
    final price = plan.price;

    showDialog(
      context: context,
      builder: (context) {
        _Colors.sync(context);
        return AlertDialog(
        title: Text('Pay via $method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                border: Border.all(color: _Colors.borderMuted),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.qr_code_2,
                size: 130,
                color: _Colors.iconMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '₱${_formatPrice(price)}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFCB8A00),
              ),
            ),
            Text(
              plan.duration,
              style: TextStyle(fontSize: 12, color: _Colors.textSecondary),
            ),
            const SizedBox(height: 12),
            Text(
              'Scan this QR code using your $method app to complete payment.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: _Colors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan.shade500,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _selectPlan(planIndex, method: method);
            },
            child: const Text("I've paid"),
          ),
        ],
      );
      },
    );
  }

  Future<void> _selectPlan(int planIndex, {required String method}) async {
    if (_isProcessingPurchase) return;
    setState(() => _isProcessingPurchase = true);

    final plan = plans[planIndex];
    final memberId = UserSession.instance.dbMemberId;

    if (memberId == null) {
      setState(() => _isProcessingPurchase = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to identify member. Please log in again.')),
        );
      }
      return;
    }

    // Tawagin ang aktwal na membership_api.php -- dito nangyayari ang
    // pag-save sa Memberships/Payments table, at doon din ma-trigger
    // ang webhook papunta sa Admin/Owner app (Laravel).
    final result = await MembershipService.createMembership(
      memberId: memberId,
      planId: plan.planId,
      paymentMethod: method,
    );

    setState(() => _isProcessingPurchase = false);

    if (result['success'] != true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to process membership.')),
        );
      }
      return;
    }

    final purchaseDate = today;

    // Kunin ang totoong NextRenewalDate mula sa response ng membership_api.php
    // (hindi natin ito dapat i-estimate lang client-side), para tumpak ang
    // "days until expiry" na kinakalkula ng StatusAlertBanner.
    DateTime? newRenewalDate;
    final rawRenewalDate = result['next_renewal_date']?.toString();
    if (rawRenewalDate != null && rawRenewalDate.isNotEmpty) {
      try {
        newRenewalDate = DateTime.parse(rawRenewalDate);
      } catch (_) {}
    }

    setState(() {
      currentPlanIndex = planIndex;
      hasActiveMembership = true;
      membershipDurationIndex = planIndex;
      membershipStartDate = purchaseDate;
      UserSession.instance.membershipPlan = plan.duration;
      UserSession.instance.planPrice = plan.price.toDouble();
      UserSession.instance.memberSince = purchaseDate;
      UserSession.instance.membershipStatus = 'Active';
      UserSession.instance.renewalDateOverride = newRenewalDate;
    });

    _loadPaymentHistory();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Membership activated successfully!')),
      );
    }
  }

  DateTime _addMonths(DateTime date, int months) {
    var newDate = DateTime(date.year, date.month + months, date.day);
    if (newDate.month != (date.month + months - 1) % 12 + 1) {
      return DateTime(date.year, date.month + months + 1, 0);
    }
    return newDate;
  }

  int _monthsForPlan(int planIndex) {
    switch (planIndex) {
      case 0:
        return 4;
      case 1:
        return 5;
      case 2:
        return 7;
      case 3:
        return 12;
      default:
        return 1;
    }
  }

  String _formatDate(DateTime date) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  int _totalPaidThisYear() {
    int total = 0;
    for (final row in paymentHistory) {
      final amountStr = row[2].replaceAll('₱', '').replaceAll(',', '');
      final amount = int.tryParse(amountStr) ?? 0;
      if (row[0].endsWith(today.year.toString())) {
        total += amount;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    _Colors.sync(context);
    final session = UserSession.instance;
    final plan = plans[currentPlanIndex];
    final price = plan.price;
    final durationMonths = _monthsForPlan(currentPlanIndex);
    final renewalDate = _addMonths(membershipStartDate, durationMonths);

    return Scaffold(
      backgroundColor: _Colors.bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Membership & Payments',
              style: AppText.pageTitle(size: 28),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage your subscription and billing information',
              style: TextStyle(fontSize: 14, color: _Colors.textSecondary),
            ),
            const SizedBox(height: 20),
            StatusAlertBanner(session: session),
            const SizedBox(height: 4),
            _buildCurrentMembershipCard(session, plan, price, durationMonths, renewalDate),
            const SizedBox(height: 24),
            _buildChangePlanSection(),
            const SizedBox(height: 24),
            _buildPaymentHistoryTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentMembershipCard(UserSession session, MembershipPlan plan, int price, int durationMonths, DateTime renewalDate) {
    if (!hasActiveMembership) {
      return _card(
        accent: AppColors.accentAmber,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Flexible(
                  child: Text(
                    'No active membership',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                _statusBadge('Cancelled', Colors.red),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a plan below to reactivate your membership.',
              style: TextStyle(fontSize: 13, color: _Colors.textSecondary),
            ),
          ],
        ),
      );
    }

    final needsAttention =
        session.isMembershipExpired || session.isMembershipExpiringSoon;
    return _card(
      accent: needsAttention ? AppColors.accentAmber : AppColors.accentGreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${plan.duration} Membership',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _statusBadge('Active', Colors.green),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₱${_formatPrice(price)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFCB8A00),
                    ),
                  ),
                  Text(
                    plan.duration,
                    style: TextStyle(fontSize: 12, color: _Colors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Duration: ',
                style: TextStyle(fontSize: 13, color: _Colors.textSecondary),
              ),
              Text(
                plan.duration,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Builder(builder: (context) {
            final boxes = [
              _infoBox(Icons.calendar_today, 'Start Date', _formatDate(membershipStartDate)),
              _infoBox(Icons.access_time, 'Next Renewal', _formatDate(renewalDate)),
              _infoBox(Icons.attach_money, 'Total Paid (${today.year})',
                  '₱${_formatPrice(_totalPaidThisYear())}'),
            ];
            if (context.isMobile) {
              return Column(
                children: [
                  for (int i = 0; i < boxes.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    boxes[i],
                  ],
                ],
              );
            }
            return Row(
              children: [
                for (int i = 0; i < boxes.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(child: boxes[i]),
                ],
              ],
            );
          }),
          const SizedBox(height: 20),
          const Text(
            'Included Features',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: plan.features
                      .asMap()
                      .entries
                      .where((e) => e.key.isEven)
                      .map((e) => _featureRow(e.value))
                      .toList(),
                ),
              ),
              Expanded(
                child: Column(
                  children: plan.features
                      .asMap()
                      .entries
                      .where((e) => e.key.isOdd)
                      .map((e) => _featureRow(e.value))
                      .toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Spacer(),
              OutlinedButton(
                onPressed: _confirmCancelMembership,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red.shade200),
                  backgroundColor: Colors.red.shade50,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Cancel Membership'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoBox(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _Colors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _Colors._dark
                  ? AppColors.cyan.withValues(alpha: 0.16)
                  : AppColors.cyanTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF0E7490)),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(fontSize: 11.5, color: _Colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _featureRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.blue.shade400),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(fontSize: 13, color: _Colors.textBody),
          ),
        ],
      ),
    );
  }

  Widget _buildChangePlanSection() {
    return _card(
      accent: AppColors.accentCyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Available Plans',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (_isProcessingPurchase)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _buildPlansGrid(context),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const SubmitReceiptPage()),
                );
              },
              icon: const Icon(Icons.receipt_long_outlined, size: 18),
              label: const Text('Pay via GCash / Maya'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.cyan.shade700,
                side: BorderSide(color: Colors.cyan.shade400),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pay manually and upload your receipt for admin review.',
            style: TextStyle(fontSize: 12, color: _Colors.textSecondary),
          ),
        ],
      ),
    );
  }

  // Column count is based on the actual content width available here
  // (via LayoutBuilder), not full screen width -- the sidebar already
  // eats ~260px on tablet/desktop, so screen-width breakpoints alone
  // would overestimate how much room this section really has.
  Widget _buildPlansGrid(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final availableWidth = constraints.maxWidth;
      if (availableWidth >= 900) {
        // Wide enough for the original 4-across Row, unchanged.
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: plans
              .asMap()
              .entries
              .map(
                (entry) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _planCard(entry.value, entry.key),
                  ),
                ),
              )
              .toList(),
        );
      }

      const spacing = 12.0;
      final columns = availableWidth >= 480 ? 2 : 1;
      final cardWidth = (availableWidth - spacing * (columns - 1)) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: plans
            .asMap()
            .entries
            .map((entry) => SizedBox(
                width: cardWidth, child: _planCard(entry.value, entry.key)))
            .toList(),
      );
    });
  }

  Widget _planCard(MembershipPlan plan, int planIndex) {
    final isCurrent = hasActiveMembership && planIndex == currentPlanIndex;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isCurrent ? _Colors.planHighlightBg : _Colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? Colors.cyan.shade400 : _Colors.borderMuted,
          width: isCurrent ? 1.5 : 1,
        ),
        boxShadow: isCurrent ? const [] : _Colors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isCurrent)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.cyan.shade500,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'CURRENT PLAN',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Text(
            plan.duration,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '₱${_formatPrice(plan.price)}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFFCB8A00),
            ),
          ),
          const SizedBox(height: 16),
          ...plan.features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 15,
                    color: Colors.blue.shade400,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(f, style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: isCurrent
                ? OutlinedButton(
                    onPressed: _isProcessingPurchase ? null : () => _startPurchaseFlow(planIndex),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.cyan.shade700,
                      side: BorderSide(color: Colors.cyan.shade400),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Renew Plan'),
                  )
                : ElevatedButton(
                    onPressed: _isProcessingPurchase ? null : () => _startPurchaseFlow(planIndex),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan.shade500,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      hasActiveMembership ? 'Upgrade' : 'Choose Plan',
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryTable() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment History',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildPaymentHistoryTableBody(context),
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryTableBody(BuildContext context) {
    final table = Table(
      // Every column is left-aligned (header + cells) and vertically centred,
      // so the badge/link columns line up with the plain-text ones.
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      // On mobile, fixed pixel widths (inside a horizontal scroll) so
      // columns stay legible instead of being squeezed by Flex; tablet
      // and desktop keep the original Flex-based sizing, which already
      // fits without scrolling.
      columnWidths: context.isMobile
          ? const {
              0: FixedColumnWidth(90),
              1: FixedColumnWidth(90),
              2: FixedColumnWidth(90),
              3: FixedColumnWidth(80),
              4: FixedColumnWidth(80),
              5: FixedColumnWidth(110),
            }
          : const {
              0: FlexColumnWidth(1.2),
              1: FlexColumnWidth(1.5),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
              4: FlexColumnWidth(1),
              5: FlexColumnWidth(1),
            },
      children: [
        TableRow(
          children: [
            _headerCell('Date'),
            _headerCell('Plan'),
            _headerCell('Amount'),
            _headerCell('Method'),
            _headerCell('Status'),
            _headerCell('Receipt'),
          ],
        ),
        ...paymentHistory.map(
          (r) => TableRow(
            children: [
              _cell(r[0]),
              _cell(r[1]),
              _cell(r[2], color: const Color(0xFFCB8A00), bold: true),
              _cell(r[3]),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _statusBadge(r[4], Colors.green),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: () => _downloadReceipt(r),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Download',
                          style: TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                        Icon(
                          Icons.arrow_forward,
                          size: 12,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (!context.isMobile) return table;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(width: 90 + 90 + 90 + 80 + 80 + 110, child: table),
    );
  }

  /// Builds and downloads the receipt for one payment-history row. Each row
  /// gets its own file, rendered from that transaction's recorded data
  /// (date, plan, amount, method, status) plus the member's identity — i.e.
  /// the receipt as it stood when that payment was completed.
  void _downloadReceipt(List<String> row) {
    final session = UserSession.instance;
    final date = row.isNotEmpty ? row[0] : '';
    final plan = row.length > 1 ? row[1] : '';
    final amount = row.length > 2 ? row[2] : '';
    final method = row.length > 3 ? row[3] : '';
    final status = row.length > 4 ? row[4] : '';

    String esc(String s) => const HtmlEscape().convert(s);
    String slug(String s) => s.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-');

    final receiptHtml = '''<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<title>PrimeFit Receipt — ${esc(plan)} — ${esc(date)}</title>
<style>
  body{font-family:-apple-system,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;background:#f6f8fb;margin:0;padding:32px;color:#1a1a1a}
  .r{max-width:520px;margin:0 auto;background:#fff;border:1px solid #e5e7eb;border-radius:14px;overflow:hidden}
  .h{background:linear-gradient(135deg,#22b8d8,#1ba0b8);color:#fff;padding:20px 24px}
  .h h1{margin:0;font-size:18px}.h p{margin:2px 0 0;font-size:12px;opacity:.85}
  .b{padding:24px}
  .lbl{color:#6b7280;font-size:11px;letter-spacing:.5px;text-transform:uppercase;margin-top:16px}
  .val{font-size:14px;font-weight:600;margin-top:2px}
  .sub{font-size:12px;color:#6b7280;margin-top:2px}
  .row{display:flex;justify-content:space-between;padding:10px 0;border-bottom:1px solid #eef0f3;font-size:14px}
  .badge{display:inline-block;background:#ecfdf5;color:#047857;font-weight:700;font-size:12px;padding:3px 10px;border-radius:20px}
  .total{display:flex;justify-content:space-between;font-size:16px;font-weight:800;margin-top:14px;padding-top:14px;border-top:2px solid #1a1a1a}
  .foot{color:#9ca3af;font-size:11px;text-align:center;margin-top:20px}
</style></head>
<body><div class="r">
  <div class="h"><h1>PrimeFit Fitness Gym</h1><p>Official Payment Receipt</p></div>
  <div class="b">
    <div class="lbl">Member</div>
    <div class="val">${esc(session.fullName)}</div>
    <div class="sub">${esc(session.memberId)} &middot; ${esc(session.email)}</div>
    <div class="lbl">Transaction Date</div>
    <div class="val">${esc(date)}</div>
    <div style="margin-top:18px">
      <div class="row"><span>${esc(plan)} Membership</span><span>${esc(amount)}</span></div>
      <div class="row"><span>Payment method</span><span>${esc(method)}</span></div>
      <div class="row"><span>Status</span><span class="badge">${esc(status)}</span></div>
    </div>
    <div class="total"><span>Total Paid</span><span>${esc(amount)}</span></div>
  </div>
</div>
<div class="foot">Generated from your PrimeFit payment history.</div>
</body></html>''';

    final blob = html.Blob(<String>[receiptHtml], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'PrimeFit-Receipt-${slug(plan)}-${slug(date)}.html')
      ..style.display = 'none'
      ..click();
    html.Url.revokeObjectUrl(url);

    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Receipt downloaded.')));
    }
  }

  Widget _headerCell(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      text,
      style: TextStyle(fontSize: 12, color: _Colors.textMuted),
    ),
  );

  Widget _cell(String text, {Color? color, bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        color: color,
        fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
      ),
    ),
  );

  Widget _card({required Widget child, Color? accent}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _Colors.cardBgFor(accent),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Colors.cardBorderFor(accent)),
        boxShadow: _Colors.cardShadow,
      ),
      child: child,
    );
  }

  String _formatPrice(int price) {
    final str = price.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i != 0 && (str.length - i) % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  Widget _statusBadge(String text, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, color: color.shade700)),
    );
  }
}