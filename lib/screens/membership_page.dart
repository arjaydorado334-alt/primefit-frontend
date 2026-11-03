import 'dart:ui' as ui;
import 'dart:typed_data';
// Web-only download of the per-transaction receipt file. This app ships only
// as a Flutter web build (Chrome), so dart:html is the right tool here; the
// receipt is rendered from that transaction's own recorded data.
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:google_fonts/google_fonts.dart';
// 👇 NEW: used to build the PDF copy of the receipt.  Install with:
//    flutter pub add pdf
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:image_picker/image_picker.dart';
import '../data/membership_plans.dart';
import '../screens/user_session.dart';
import '../services/billing_service.dart';
import '../services/payment_history_service.dart';
import '../services/member_session_service.dart';
import '../theme/app_theme.dart';
import '../widgets/portal_hero.dart';
import '../widgets/status_alert_banner.dart';

/// The only two payment methods PrimeFit actually accepts today, with the
/// real bundled QR images (the account name is baked into each image
/// itself, so no separate account-name/number text is shown here -- that
/// avoided a prior bug where a hardcoded placeholder number didn't match
/// the real QR).
class _PayMethod {
  final String name;
  final IconData icon;
  final String qrAsset;
  const _PayMethod(this.name, this.icon, this.qrAsset);
}

const List<_PayMethod> _kPayMethods = [
  _PayMethod('GCash', Icons.smartphone_outlined, 'assets/qr/gcash_qr.jpg'),
  _PayMethod('Maya', Icons.account_balance_wallet_outlined,
      'assets/qr/maya_qr.jpg'),
];

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
  static Color get cardBorder => _dark ? AppColors.darkBorder : Colors.grey.shade200;
  static Color get surfaceAlt => _dark ? const Color(0xFF1C1D22) : Colors.grey.shade50;
  static Color get borderMuted => _dark ? AppColors.darkBorder : Colors.grey.shade300;
  static Color get textSecondary => _dark ? AppColors.textMutedOnDark : Colors.grey.shade600;
  static Color get textMuted => _dark ? AppColors.textMutedOnDark : Colors.grey.shade500;
  static Color get textBody => _dark ? AppColors.textMutedOnDark : Colors.grey.shade800;
  static Color get iconMuted => _dark ? AppColors.textMutedOnDark : Colors.grey.shade700;

  /// Headings and key numbers: plain dark text (white in dark mode).
  static Color get heading => _dark ? Colors.white : const Color(0xFF1F2937);

  /// Section titles are plain dark text now (they used to be plum).
  static Color get sectionTitle => heading;

  /// Cyan text that stays readable on both the light and dark surfaces.
  static Color get cyanText => _dark ? AppColors.cyan : const Color(0xFF0E7490);

  /// Fill for primary buttons: dark gray in light mode, cyan in dark mode
  /// (replaces the old gold buttons, like the admin portal).
  static Color get primaryFill => _dark ? AppColors.cyan : const Color(0xFF111827);

  /// Icon-badge / status-pill background: a translucent wash of [accent] in
  /// dark mode instead of the light pastel [lightBg] at full strength
  /// (which would read as a jarringly bright chip against a dark card).
  static Color badgeBg(Color accent, Color lightBg) =>
      _dark ? accent.withValues(alpha: 0.16) : lightBg;

  /// Matching badge icon/text colour: lightened toward white in dark mode
  /// so it stays legible against the translucent background above.
  static Color badgeFg(Color accent, Color lightFg) =>
      _dark ? (Color.lerp(accent, Colors.white, 0.45) ?? accent) : lightFg;
}

/// Primary action button style: dark pill (cyan in dark mode).
ButtonStyle _primaryStyle({EdgeInsetsGeometry? padding}) {
  return ElevatedButton.styleFrom(
    backgroundColor: _Colors.primaryFill,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: padding,
    shape: const StadiumBorder(),
    textStyle: const TextStyle(fontWeight: FontWeight.w600),
  );
}

/// Secondary action button style: outlined pill.
ButtonStyle _outlineStyle({EdgeInsetsGeometry? padding, Color? color}) {
  final c = color ?? _Colors.heading;
  return OutlinedButton.styleFrom(
    foregroundColor: c,
    side: BorderSide(color: c.withValues(alpha: 0.35)),
    padding: padding,
    shape: const StadiumBorder(),
    textStyle: const TextStyle(fontWeight: FontWeight.w600),
  );
}

/// Small uppercase gray card title (Haws Prints style).
class _PanelTitle extends StatelessWidget {
  final String text;
  const _PanelTitle(this.text);

  @override
  Widget build(BuildContext context) {
    _Colors.sync(context);
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: _Colors.textSecondary,
      ),
    );
  }
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
  final bool _isProcessingPurchase = false;

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
    _refreshMembershipFromServer();
    _loadPaymentHistory();
  }

  Future<void> _refreshMembershipFromServer() async {
    await MemberSessionService.restore();
    if (mounted) _loadFromSession();
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
      builder: (context) {
        _Colors.sync(context);
        return AlertDialog(
        title: Text('Cancel membership?', style: AppText.sectionTitle(size: 20, color: _Colors.sectionTitle)),
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
        );
      },
    );
  }

  /// Renewal = re-buying the same plan the member is already on; Upgrade =
  /// picking a different plan while a membership already exists; New
  /// Registration = no active membership at all. This is purely a label for
  /// the admin's Pending Payments queue -- it doesn't change how the payment
  /// is processed.
  String _purposeFor(int planIndex) {
    if (!hasActiveMembership) return 'New Registration';
    return planIndex == currentPlanIndex ? 'Renewal' : 'Upgrade';
  }

  void _startPurchaseFlow(int planIndex) {
    showDialog(
      context: context,
      builder: (context) => _PayAndUploadDialog(
        plan: plans[planIndex],
        purpose: _purposeFor(planIndex),
        formatPrice: _formatPrice,
        onSubmitted: _loadPaymentHistory,
      ),
    );
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
            const PortalHero(
              eyebrow: 'Membership',
              icon: Icons.credit_card,
              title: 'Membership & Payments',
              subtitle: 'Manage your subscription and billing information',
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
                Flexible(
                  child: Text(
                    'No active membership',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _Colors.heading),
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
      // Colored left bar only when the membership needs attention.
      accent: needsAttention ? AppColors.accentAmber : null,
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
                        style: AppText.sectionTitle(size: 18, color: _Colors.sectionTitle),
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
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: _Colors.heading,
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
                style: TextStyle(
                  fontSize: 13,
                  color: _Colors.cyanText,
                  fontWeight: FontWeight.w600,
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
          const _PanelTitle('Included Features'),
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
                style: _outlineStyle(
                  color: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
              color: AppColors.cyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: AppColors.cyan),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _Colors.heading),
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
          const Icon(Icons.check_circle, size: 16, color: AppColors.cyan),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _PanelTitle('Available Plans'),
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
        color: _Colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        // The current plan keeps a cyan outline; everything else is neutral.
        border: Border.all(
          color: isCurrent ? AppColors.cyan : _Colors.cardBorder,
          width: isCurrent ? 1.5 : 1,
        ),
        boxShadow: _Colors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isCurrent)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.cyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'CURRENT PLAN',
                style: TextStyle(
                  fontSize: 10,
                  color: _Colors.cyanText,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          Text(
            plan.duration,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _Colors.heading),
          ),
          const SizedBox(height: 8),
          Text(
            '₱${_formatPrice(plan.price)}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: _Colors.heading,
            ),
          ),
          const SizedBox(height: 16),
          ...plan.features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 15,
                    color: AppColors.cyan,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(f,
                        style: TextStyle(fontSize: 12, color: _Colors.textBody)),
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
                    style: _outlineStyle(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                    child: const Text('Renew Plan'),
                  )
                : ElevatedButton(
                    onPressed: _isProcessingPurchase ? null : () => _startPurchaseFlow(planIndex),
                    style: _primaryStyle(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
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
          const _PanelTitle('Payment History'),
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
      // Hairline dividers between rows.
      border: TableBorder(
        horizontalInside: BorderSide(color: _Colors.cardBorder),
      ),
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
              _cell(r[2], color: _Colors.heading, bold: true),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Download',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _Colors.cyanText),
                        ),
                        Icon(
                          Icons.arrow_forward,
                          size: 12,
                          color: _Colors.cyanText,
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

  /// Opens the receipt for one payment-history row in a simple receipt
  /// preview, with buttons to download it as a PDF or a PNG copy. Each row
  /// gets its own receipt, rendered from that transaction's recorded data
  /// (date, plan, amount, method, status) plus the member's identity.
  void _downloadReceipt(List<String> row) {
    showDialog(
      context: context,
      builder: (_) => _ReceiptDialog(row: row),
    );
  }

  Widget _headerCell(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      text.toUpperCase(),
      style: AppText.tableHeader(color: _Colors.textMuted),
    ),
  );

  Widget _cell(String text, {Color? color, bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        color: color,
        fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
      ),
    ),
  );

  /// Neutral white card with a hairline border and soft shadow. [accent]
  /// draws a thin colored bar on the left edge, reserved for cards that
  /// need attention.
  Widget _card({required Widget child, Color? accent}) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _Colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Colors.cardBorder),
        boxShadow: _Colors.cardShadow,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: child,
          ),
          if (accent != null)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 4, color: accent),
            ),
        ],
      ),
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
        color: _Colors.badgeBg(color.shade500, color.shade50),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: AppText.badgeLabel(color: _Colors.badgeFg(color.shade500, color.shade700))),
    );
  }
}

// ---------------------------------------------------------------------------
// Real payment dialog: GCash / Maya QR + receipt upload, submitted through
// the same reviewed path as registration (billing_api.php's submit_receipt),
// so an upgrade/renewal payment lands in the admin's Pending Payments queue
// instead of being instantly marked Paid.
// ---------------------------------------------------------------------------

class _PayAndUploadDialog extends StatefulWidget {
  final MembershipPlan plan;
  final String purpose;
  final String Function(int) formatPrice;
  final VoidCallback onSubmitted;

  const _PayAndUploadDialog({
    required this.plan,
    required this.purpose,
    required this.formatPrice,
    required this.onSubmitted,
  });

  @override
  State<_PayAndUploadDialog> createState() => _PayAndUploadDialogState();
}

class _PayAndUploadDialogState extends State<_PayAndUploadDialog> {
  _PayMethod _method = _kPayMethods.first;
  Uint8List? _receiptBytes;
  String? _receiptName;
  bool _submitting = false;
  bool _submitted = false;
  String? _errorMessage;

  bool get _canSubmit => _receiptBytes != null && !_submitting;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await ImagePicker()
          .pickImage(source: source, imageQuality: 80, maxWidth: 1600);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      if (bytes.length > 10 * 1024 * 1024) {
        setState(() {
          _receiptBytes = null;
          _receiptName = null;
          _errorMessage = 'Receipt image must be under 10 MB. Please choose a smaller image.';
        });
        return;
      }
      setState(() {
        _receiptBytes = bytes;
        _receiptName = picked.name;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the image: $e')),
      );
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _Colors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetCtx) {
        _Colors.sync(sheetCtx);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: _Colors.iconMuted),
                title: Text('Choose from gallery', style: TextStyle(color: _Colors.textBody)),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera_outlined, color: _Colors.iconMuted),
                title: Text('Take a photo', style: TextStyle(color: _Colors.textBody)),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    final memberId = UserSession.instance.dbMemberId;
    if (_receiptBytes == null) return;
    if (memberId == null) {
      setState(() =>
          _errorMessage = 'Unable to identify member. Please log in again.');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final methodParam = _method.name == 'GCash' ? 'gcash' : 'paymaya';
    final result = await BillingService.submitReceipt(
      memberId: memberId,
      planId: widget.plan.planId,
      method: methodParam,
      receiptBytes: _receiptBytes!,
      receiptFileName: _receiptName ?? 'receipt.jpg',
      purpose: widget.purpose,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result['success'] == true) {
      setState(() => _submitted = true);
      widget.onSubmitted();
    } else {
      setState(() => _errorMessage =
          result['message']?.toString() ?? 'Submission failed. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    _Colors.sync(context);

    return AlertDialog(
      // Wider dialog (was 380) so the GCash / Maya QR codes can be shown
      // large enough to scan comfortably.
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      title: Text(
        _submitted ? 'Receipt submitted' : 'Pay for ${widget.plan.duration}',
        style: AppText.sectionTitle(size: 20, color: _Colors.sectionTitle),
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: _submitted ? _buildSuccess() : _buildForm(),
        ),
      ),
      actions: _submitted
          ? [
              ElevatedButton(
                style: _primaryStyle(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12)),
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ]
          : [
              TextButton(
                onPressed: _submitting ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: _primaryStyle(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12)),
                onPressed: _canSubmit ? _submit : null,
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Submit Receipt'),
              ),
            ],
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${widget.plan.duration}  ·  ₱${widget.formatPrice(widget.plan.price)}',
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, color: _Colors.textBody),
        ),
        const SizedBox(height: 4),
        Text(
          'Scan the QR below to pay via ${_method.name}, then upload a '
          'screenshot of your payment confirmation. Your plan is activated '
          'once an admin reviews it.',
          style: TextStyle(fontSize: 12.5, color: _Colors.textSecondary),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            for (final m in _kPayMethods) ...[
              Expanded(child: _methodButton(m)),
              if (m != _kPayMethods.last) const SizedBox(width: 10),
            ],
          ],
        ),
        const SizedBox(height: 16),
        _qrCard(),
        const SizedBox(height: 16),
        _uploadBox(),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _Colors.badgeBg(AppColors.danger, const Color(0xFFFEF2F2)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline,
                    color: _Colors.badgeFg(AppColors.danger, AppColors.danger), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_errorMessage!,
                      style: TextStyle(
                          color: _Colors.badgeFg(AppColors.danger, AppColors.danger),
                          fontSize: 12.5)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Payment-method pill: dark when selected (cyan in dark mode), white with
  /// a hairline border otherwise.
  Widget _methodButton(_PayMethod m) {
    final selected = _method.name == m.name;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => setState(() => _method = m),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? _Colors.primaryFill : _Colors.cardBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? _Colors.primaryFill : _Colors.borderMuted,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(m.icon, size: 16, color: selected ? Colors.white : _Colors.textSecondary),
            const SizedBox(width: 6),
            Text(m.name,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: selected ? Colors.white : _Colors.textBody)),
          ],
        ),
      ),
    );
  }

  Widget _qrCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Colors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Colors.cardBorder),
      ),
      child: Column(
        children: [
          // White backing behind the QR so it scans reliably, even in dark
          // mode (a QR on a dark card is hard for phone cameras to read).
          // The QR images are tall (portrait), so they're shown 340px tall
          // instead of being squeezed into a small square.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              _method.qrAsset,
              height: 340,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stack) => SizedBox(
                height: 340,
                child: Icon(Icons.qr_code_2,
                    size: 80, color: Colors.grey.shade400),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Scan with your ${_method.name} app to complete payment.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: _Colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _uploadBox() {
    final hasImage = _receiptBytes != null;
    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: Container(
        width: double.infinity,
        height: hasImage ? 160 : 100,
        decoration: BoxDecoration(
          color: _Colors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasImage ? AppColors.cyan : _Colors.borderMuted,
            width: hasImage ? 1.5 : 1,
          ),
        ),
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.memory(_receiptBytes!, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Change', style: TextStyle(color: Colors.white, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_outlined, size: 22, color: _Colors.textSecondary),
                  const SizedBox(height: 6),
                  Text('Tap to upload your payment receipt',
                      style: TextStyle(fontSize: 12, color: _Colors.textSecondary)),
                ],
              ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _Colors.badgeBg(AppColors.success, const Color(0xFFE7F9EF)),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_rounded,
              color: _Colors.badgeFg(AppColors.success, AppColors.success), size: 30),
        ),
        const SizedBox(height: 14),
        Text(
          'Your ${widget.purpose.toLowerCase()} payment is awaiting admin review. '
          'Your plan will be activated once it is approved.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: _Colors.textSecondary),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Receipt preview + download (PDF / PNG)
// ---------------------------------------------------------------------------

/// Shows the payment receipt in a simple receipt layout and lets the member
/// download it as a PNG image or a PDF. The receipt is drawn once as a
/// Flutter widget; both files are made from that exact picture, so what you
/// see in the preview is what you get in the download.
class _ReceiptDialog extends StatefulWidget {
  /// [date, plan, amount, method, status] -- one payment-history row.
  final List<String> row;
  const _ReceiptDialog({required this.row});

  @override
  State<_ReceiptDialog> createState() => _ReceiptDialogState();
}

class _ReceiptDialogState extends State<_ReceiptDialog> {
  final GlobalKey _paperKey = GlobalKey();
  bool _busy = false;

  String _cell(int i) => widget.row.length > i ? widget.row[i] : '';
  String _slug(String s) => s.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-');
  String get _baseName =>
      'PrimeFit-Receipt-${_slug(_cell(1))}-${_slug(_cell(0))}';

  /// Draws the receipt widget into a PNG (3x for a sharp image).
  Future<Uint8List?> _capturePng() async {
    final boundary =
        _paperKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  void _saveBytes(Uint8List bytes, String mime, String filename) {
    final blob = html.Blob(<Uint8List>[bytes], mime);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..style.display = 'none'
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _download({required bool asPdf}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final png = await _capturePng();
      if (png == null) throw 'Could not draw the receipt.';

      if (asPdf) {
        final doc = pw.Document();
        final img = pw.MemoryImage(png);
        doc.addPage(
          pw.Page(
            pageFormat: pdf.PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(48),
            build: (_) => pw.Align(
              alignment: pw.Alignment.topCenter,
              child: pw.SizedBox(width: 300, child: pw.Image(img)),
            ),
          ),
        );
        final bytes = await doc.save();
        _saveBytes(Uint8List.fromList(bytes), 'application/pdf', '$_baseName.pdf');
      } else {
        _saveBytes(png, 'image/png', '$_baseName.png');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
            content: Text(asPdf ? 'Receipt PDF downloaded.' : 'Receipt PNG downloaded.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Could not download the receipt: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _Colors.sync(context);
    final session = UserSession.instance;

    return Dialog(
      backgroundColor: _Colors.cardBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Payment Receipt',
                        style: AppText.sectionTitle(
                            size: 18, color: _Colors.sectionTitle)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: _Colors.iconMuted),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // The receipt itself, on a soft background so the white
              // "paper" stands out. Only the paper is captured for download.
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _Colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _Colors.cardBorder),
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: RepaintBoundary(
                      key: _paperKey,
                      child: _ReceiptPaper(
                        date: _cell(0),
                        plan: _cell(1),
                        amount: _cell(2),
                        method: _cell(3),
                        status: _cell(4),
                        memberName: session.fullName,
                        memberId: session.memberId,
                        email: session.email,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _download(asPdf: false),
                      icon: const Icon(Icons.image_outlined, size: 18),
                      label: const Text('Download PNG'),
                      style: _outlineStyle(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _busy ? null : () => _download(asPdf: true),
                      icon: _busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.picture_as_pdf_outlined, size: 18),
                      label: const Text('Download PDF'),
                      style: _primaryStyle(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The receipt "paper": a simple, centered, thermal-receipt style layout --
/// store name on top, dashed separators, label/value lines, a bold total and
/// a thank-you note. Always white with dark text (it is a printed document,
/// so it does not follow the app's light/dark theme).
class _ReceiptPaper extends StatelessWidget {
  final String date;
  final String plan;
  final String amount;
  final String method;
  final String status;
  final String memberName;
  final String memberId;
  final String email;

  const _ReceiptPaper({
    required this.date,
    required this.plan,
    required this.amount,
    required this.method,
    required this.status,
    required this.memberName,
    required this.memberId,
    required this.email,
  });

  static const Color _ink = Color(0xFF111827);
  static const Color _soft = Color(0xFF6B7280);

  TextStyle _t(double size,
          {FontWeight weight = FontWeight.w500,
          Color color = _ink,
          double spacing = 0,
          double height = 1.35}) =>
      GoogleFonts.inter(
          fontSize: size,
          fontWeight: weight,
          color: color,
          letterSpacing: spacing,
          height: height);

  Widget _dashes() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: LayoutBuilder(builder: (context, c) {
          final count = (c.maxWidth / 7).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              count,
              (_) => Container(
                  width: 4, height: 1.4, color: const Color(0xFF9CA3AF)),
            ),
          );
        }),
      );

  Widget _line(String label, String value, {bool boldValue = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _t(12, color: _soft)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: _t(12.5,
                  weight: boldValue ? FontWeight.w700 : FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(26, 28, 26, 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---- header ----
          Text('PRIMEFIT FITNESS GYM',
              textAlign: TextAlign.center,
              style: _t(15, weight: FontWeight.w800, spacing: 1)),
          const SizedBox(height: 4),
          Text('31 Bernardo St, near Army Road,\nCentral Signal, Taguig City',
              textAlign: TextAlign.center,
              style: _t(10.5, color: _soft, height: 1.45)),
          const SizedBox(height: 12),
          Text('OFFICIAL RECEIPT',
              textAlign: TextAlign.center,
              style: _t(12, weight: FontWeight.w700, spacing: 2)),
          _dashes(),

          // ---- who / when ----
          _line('Date', date),
          _line('Member', memberName),
          _line('Member ID', memberId),
          _line('Email', email),
          _dashes(),

          // ---- what was paid for ----
          Row(
            children: [
              Text('DESCRIPTION',
                  style: _t(10.5, weight: FontWeight.w700, color: _soft, spacing: 0.8)),
              const Spacer(),
              Text('AMOUNT',
                  style: _t(10.5, weight: FontWeight.w700, color: _soft, spacing: 0.8)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text('$plan Membership',
                    style: _t(13, weight: FontWeight.w600)),
              ),
              const SizedBox(width: 12),
              Text(amount, style: _t(13, weight: FontWeight.w600)),
            ],
          ),
          _dashes(),

          // ---- total ----
          Row(
            children: [
              Text('TOTAL PAID', style: _t(14, weight: FontWeight.w800)),
              const Spacer(),
              Text(amount, style: _t(18, weight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 10),
          _line('Payment method', method),
          _line('Status', status.toUpperCase(), boldValue: true),
          _dashes(),

          // ---- footer ----
          const SizedBox(height: 2),
          Text('Thank you for training with us!',
              textAlign: TextAlign.center,
              style: _t(12, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Keep this receipt as your proof of payment.',
              textAlign: TextAlign.center, style: _t(10.5, color: _soft)),
        ],
      ),
    );
  }
}
