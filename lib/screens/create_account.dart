import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../widgets/prime_fit_logo.dart';
// 👇 Adjust this path if member_portal_screen.dart lives somewhere else.
// If create_account.dart and member_portal_screen.dart are in the same
// folder (e.g. both under lib/screens/), this relative import works as-is.
import 'member_portal_screen.dart';
import 'user_session.dart';
// 👇 Connects this screen to your PHP registration+payment API
// (complete_registration_api.php). Adjust the path if
// complete_registration_service.dart lives somewhere else.
import '../services/complete_registration_service.dart';
import '../services/plan_service.dart';
// 👇 Connects the "Sign in" link on the Account step to your LoginPage.
// Adjust this path if login_page.dart lives somewhere else (it should be
// in the same folder as create_account.dart based on its own imports).
import 'login_page.dart';

/// Shared typography for the onboarding flow, kept consistent with the
/// PrimeFit landing page: Archivo Black for bold step headings, Inter
/// for everything else (subtitles, labels, body copy, buttons).
class _AuthFonts {
  // Step heading — bold, confident, not oversized.
  static TextStyle heading({double size = 26, Color color = Colors.black}) =>
      GoogleFonts.archivoBlack(
        fontSize: size,
        color: color,
        height: 1.15,
        letterSpacing: -0.3,
      );

  // Subtitle under the heading — kept black so it stays clearly
  // legible over the glass cell.
  static TextStyle subtitle({double size = 13.5, Color color = Colors.black}) =>
      GoogleFonts.inter(
          fontSize: size,
          color: color,
          height: 1.4,
          fontWeight: FontWeight.w400);

  // Form field labels.
  static TextStyle label({double size = 13, Color color = Colors.black}) =>
      GoogleFonts.inter(
          fontSize: size, fontWeight: FontWeight.w600, color: color);

  // Body / description text.
  static TextStyle body(
          {double size = 13,
          Color color = Colors.black,
          double height = 1.5}) =>
      GoogleFonts.inter(
          fontSize: size,
          color: color,
          height: height,
          fontWeight: FontWeight.w400);

  // Links.
  static TextStyle link(
          {double size = 13,
          required Color color,
          FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.inter(fontSize: size, color: color, fontWeight: weight);

  // Primary button label — bold, uppercase.
  static TextStyle button({double size = 14.5, Color color = Colors.white}) =>
      GoogleFonts.inter(
          fontSize: size,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5);

  // Sidebar step titles.
  static TextStyle stepTitle(
          {required Color color, required FontWeight weight}) =>
      GoogleFonts.inter(fontSize: 15, color: color, fontWeight: weight);
}

/// Genuinely translucent frosted-glass panel that floats the form over
/// the background photo — a strong backdrop blur diffuses the image
/// into soft color/light so the low-opacity white tint still reads as
/// legible "glass" rather than a flat white card, while the photo
/// stays subtly visible through it.
class _GlassCell extends StatelessWidget {
  final Widget child;
  const _GlassCell({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 50,
                  offset: const Offset(0, 22)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// PrimeFit onboarding simulation.
/// Flow: Create Account -> Choose Plan -> Payment Method -> Order Summary -> Done (Receipt)
///
/// Drop this file into your project (e.g. lib/create_account.dart) and
/// navigate to `const CreateAccountPage()` from wherever your "Sign up" /
/// "Join now" button lives:
///
///   Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateAccountPage()));
///
/// The Account step is local-only validation. The Member, Membership, and
/// Payment rows are all created TOGETHER in a single transaction when the
/// customer confirms payment on the Review screen (see
/// _handleConfirmPayment / complete_registration_api.php) -- so no account
/// exists in the database until payment is actually confirmed.
///
/// NEW: the member must attach a screenshot/photo of their payment receipt
/// on the QR payment screen before "I'VE PAID" unlocks. The receipt file
/// is sent together with the registration call so admin can review it and
/// manually confirm the payment (see CompleteRegistrationService.register).
class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

enum _Screen { account, plan, paymentMethod, review, done }

enum _StepStatus { pending, active, done }

class _Plan {
  final String name;
  final int priceMonthly;
  final List<String> features;
  final bool popular;
  const _Plan(this.name, this.priceMonthly, this.features,
      {this.popular = false});
}

class _PaymentOption {
  final String name;
  final String subtitle;
  final IconData icon;
  final String qrAsset;
  const _PaymentOption(this.name, this.subtitle, this.icon, this.qrAsset);
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  _Screen _screen = _Screen.account;

  // ---------------- design tokens ----------------
  // Matches AppColors.cyan / AppColors.yellow so the accent colors stay
  // identical to the Sign In screen's, instead of drifting apart.
  static const Color cyan = AppColors.cyan;
  static const Color gold = AppColors.yellow;
  static const Color darkBg = Color(0xFF0B0B0C);
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color borderGrey = Color(0xFFE1E4E8);

  // ---------------- account form state ----------------
  final _lastNameCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;
  late final TapGestureRecognizer _signInRecognizer;

  // Set true while the final payment/registration step is calling
  // complete_registration_api.php.

  // The real MemberID assigned by MySQL (AUTO_INCREMENT) after registration.
  // Null until the account step successfully registers the member.
  int? _dbMemberId;

  // Maps each plan's DurationLabel (e.g. "1 Year") to its real PlanID
  // from the Plans table. Populated once we reach the plan screen.
  Map<String, int> _planIdByLabel = {};

  // ---------------- plan state ----------------
  int _selectedPlanIndex = 2; // 1 Year pre-selected

  final List<_Plan> _plans = const [
    _Plan('4 Months', 2400, [
      'Unlimited time',
      'Free Coach',
      'Free Drinking Water',
      'Clean Facility & Toilets',
    ]),
    _Plan('5 Months', 2800, [
      'Unlimited time',
      'Free Coach',
      'Free Drinking Water',
      'Clean Facility & Toilets',
    ]),
    _Plan(
        '7 Months',
        3500,
        [
          'Unlimited time',
          'Free Coach',
          'Free Drinking Water',
          'Clean Facility & Toilets',
        ],
        popular: true),
    _Plan('1 Year', 4800, [
      'Unlimited time',
      'Free Coach',
      'Free Drinking Water',
      'Clean Facility & Toilets',
    ]),
  ];

  // ---------------- payment state ----------------
  int _selectedPaymentIndex = 0;
  final List<_PaymentOption> _paymentOptions = const [
    _PaymentOption('GCash', 'Mobile wallet — instant transfer',
        Icons.smartphone_outlined, 'assets/qr/gcash_qr.jpg'),
    _PaymentOption('Maya', 'Mobile wallet — e-money',
        Icons.account_balance_wallet_outlined, 'assets/qr/maya_qr.jpg'),
  ];

  // Gates the "Review Order Summary" button so the member can't skip past
  // the QR step. Resets whenever they switch payment methods. Now also
  // requires a receipt image to be attached (see _receiptImage) before it
  // can be set to true.
  bool _hasConfirmedPayment = false;

  // ---------------- receipt state ----------------
  String _memberId = '';
  bool _submitting = false;

  // NEW: the proof-of-payment screenshot/photo the member attaches on the
  // QR payment screen. Required before "I'VE PAID" can be pressed, and
  // sent together with the registration call so admin can review it.
  //
  // Stored as raw bytes (Uint8List) instead of dart:io File -- File +
  // Image.file() are NOT supported on Flutter Web, and this app runs as
  // a web build (Chrome). Uint8List + Image.memory() works on every
  // platform (web, desktop, mobile) since it never touches the local
  // filesystem API.
  Uint8List? _receiptBytes;
  String? _receiptFileName;

  int get _computedPrice => _plans[_selectedPlanIndex].priceMonthly;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()..onTap = _showTermsDialog;
    _privacyRecognizer = TapGestureRecognizer()..onTap = _showPrivacyDialog;
    _signInRecognizer = TapGestureRecognizer()..onTap = _goToSignIn;
    // Fetch the real PlanIDs up front (read-only -- doesn't create any
    // account yet) so they're ready by the time the customer confirms
    // payment at the end of the flow.
    _loadPlanIds();
  }

  Future<void> _loadPlanIds() async {
    final ids = await PlanService.fetchPlanIdMap();
    if (!mounted) return;
    setState(() => _planIdByLabel = ids);
  }

  @override
  void dispose() {
    _lastNameCtrl.dispose();
    _firstNameCtrl.dispose();
    _emailCtrl.dispose();
    _contactCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    _signInRecognizer.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // NEW: lets the member pick a screenshot/photo of their GCash/Maya
  // payment receipt from their gallery. Called from the upload box on the
  // QR payment screen (see _qrPaymentCard).
  Future<void> _pickReceipt() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      // Read as bytes instead of wrapping in a dart:io File -- this is
      // what makes it work on Flutter Web as well as desktop/mobile.
      final bytes = await picked.readAsBytes();
      setState(() {
        _receiptBytes = bytes;
        _receiptFileName = picked.name;
      });
    }
  }

  String get _lastNameFirst {
    // Format: Last Name, First Name
    final fn = _firstNameCtrl.text.trim();
    final ln = _lastNameCtrl.text.trim();
    if (ln.isEmpty && fn.isEmpty) return 'Member';
    String result = ln.isNotEmpty ? ln : '';
    if (result.isNotEmpty && fn.isNotEmpty) result += ', ';
    if (fn.isNotEmpty) result += fn;
    return result;
  }

  void _handleAccountContinue() {
    if (_lastNameCtrl.text.trim().isEmpty ||
        _firstNameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _contactCtrl.text.trim().isEmpty ||
        _passCtrl.text.isEmpty ||
        _confirmCtrl.text.isEmpty) {
      _snack('Please fill in all required fields.');
      return;
    }
    if (_passCtrl.text != _confirmCtrl.text) {
      _snack('Passwords do not match.');
      return;
    }
    if (_passCtrl.text.length < 8) {
      _snack('Password must be at least 8 characters.');
      return;
    }
    if (!_agreedToTerms) {
      _snack('Please agree to the Terms of Service and Privacy Policy.');
      return;
    }
    // Note: no database write happens here. The account is only created
    // once payment is confirmed at the end of the flow (see
    // _handleConfirmPayment), so nothing exists in the Members table
    // until the customer has actually paid.
    setState(() => _screen = _Screen.plan);
  }

  void _goToSignIn() {
    // Takes the user to the existing Member Sign In screen (LoginPage).
    // Using push (not pushReplacement) so the back arrow on LoginPage
    // returns here to the Account step.
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  void _handleConfirmPayment() async {
    // Safety net: shouldn't normally be reachable since "I'VE PAID" is
    // disabled without a receipt, but guard here too in case the review
    // screen is ever reached some other way.
    if (_receiptBytes == null) {
      _snack('Please attach your payment receipt before continuing.');
      return;
    }

    setState(() => _submitting = true);

    final planName = _plans[_selectedPlanIndex].name;
    final planId = _planIdByLabel[planName];

    if (planId == null) {
      setState(() => _submitting = false);
      _snack(
          'Could not verify the selected plan. Please check your connection and try again.');
      return;
    }

    // This single call creates the Member, Membership, and Payment records
    // together in one database transaction -- nothing is saved unless the
    // whole thing (account + plan + payment) succeeds together. The
    // receipt image is uploaded as part of this same call so admin can
    // review it before confirming the payment. Payment Status comes back
    // as "Pending" until admin confirms.
    final result = await CompleteRegistrationService.register(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      phone: _contactCtrl.text.trim(),
      dateOfBirth: '',
      address: '',
      planId: planId,
      paymentMethod: _paymentOptions[_selectedPaymentIndex].name,
      receiptBytes: _receiptBytes, // NEW: pass the receipt bytes along
      receiptFileName: _receiptFileName ?? 'receipt.jpg',
    );

    if (!mounted) return;

    if (result['success'] != true) {
      setState(() => _submitting = false);
      _snack(result['message']?.toString() ??
          'Could not complete registration. Please try again.');
      return;
    }

    _dbMemberId = result['member_id'] is int
        ? result['member_id'] as int
        : int.tryParse('${result['member_id']}');

    DateTime? realRenewalDate;
    final renewalRaw = result['next_renewal_date'];
    if (renewalRaw != null) {
      try {
        realRenewalDate = DateTime.parse(renewalRaw.toString());
      } catch (_) {
        realRenewalDate = null;
      }
    }

    final realPlanPrice = result['amount'] != null
        ? double.tryParse(result['amount'].toString())
        : null;
    final realSessionCredits = result['session_credits'] != null
        ? int.tryParse(result['session_credits'].toString())
        : null;

    // NEW: the payment/membership status coming back from the API.
    // Defaults to "Pending" if the backend doesn't send one yet, so the
    // Done screen doesn't accidentally claim "Active" before admin has
    // actually confirmed anything.
    final paymentStatus =
        (result['status']?.toString() ?? 'Pending').trim();

    // Use the real database MemberID we just got back.
    _memberId = 'PF-${_dbMemberId.toString().padLeft(5, '0')}';

    // Carry the signup details over to Profile Settings so the new member
    // sees their own info there instead of placeholder data.
    UserSession.instance.applySignup(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _contactCtrl.text.trim(),
      membershipPlan: _plans[_selectedPlanIndex].name,
      memberId: _memberId,
      memberSince: DateTime.now(),
      membershipRenewsOn: realRenewalDate,
      planPrice: realPlanPrice ?? _computedPrice.toDouble(),
      dbMemberId: _dbMemberId,
      creditsTotal: realSessionCredits ?? 30,
      sessionsUsed: 0,
      visitsThisWeek: int.tryParse('${result['visits_this_week'] ?? 0}') ?? 0,
      qrCodeData: result['qr_code_data']?.toString() ?? '',
    );

    if (!mounted) return;
    setState(() {
      _submitting = false;
      _paymentStatus = paymentStatus;
      _screen = _Screen.done;
    });
  }

  // NEW: holds the payment status returned by the API ("Pending" or
  // "Paid"/"Active") so the Done screen can show the right pill/message.
  String _paymentStatus = 'Pending';

  void _goToDashboard() {
    // Clears the whole signup/plan/payment stack so the back button on the
    // dashboard doesn't lead back into the onboarding flow.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MemberPortalScreen()),
      (route) => false,
    );
  }

  void _startOver() {
    setState(() {
      _screen = _Screen.account;
      _lastNameCtrl.clear();
      _firstNameCtrl.clear();
      _emailCtrl.clear();
      _contactCtrl.clear();
      _passCtrl.clear();
      _confirmCtrl.clear();
      _agreedToTerms = false;
      _selectedPlanIndex = 2;
      _selectedPaymentIndex = 0;
      _dbMemberId = null;
      _hasConfirmedPayment = false;
      _receiptBytes = null;
      _receiptFileName = null;
      _paymentStatus = 'Pending';
    });
  }

  void _showTermsDialog() {
    const terms = [
      '1. Acceptance of Terms\nBy creating an account and using PrimeFit Fitness Gym services, you agree to be bound by these Terms of Service and our Privacy Policy.',
      '2. Membership & Payment\nAll membership plans are prepaid. Fees are non-refundable once the membership period has started. Membership is non-transferable unless otherwise stated in writing.',
      '3. Use of Facilities\nMembers must follow all gym rules and staff instructions. PrimeFit reserves the right to revoke membership without refund for violations, theft, or disruptive behavior.',
      '4. Health & Safety\nYou acknowledge that physical exercise involves risk. Always consult a physician before starting any fitness program. Use equipment at your own risk.',
      '5. Privacy\nWe collect personal information solely for membership management, communication, and service improvement. We do not sell your data to third parties.',
      '6. Changes to Terms\nPrimeFit may update these terms at any time. Continued use of our services after changes constitutes acceptance of the updated terms.',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Color(0xFF22B8D8), Color(0xFF1BA0B8)]),
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Terms of Service',
                          style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                      IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white70),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints()),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 280,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderGrey),
                        ),
                        child: ListView.builder(
                          itemCount: terms.length,
                          itemBuilder: (context, index) {
                            final text = terms[index];
                            final parts = text.split('\n');
                            final title = parts.first;
                            final body = parts.length > 1
                                ? parts.sublist(1).join('\n')
                                : '';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title,
                                      style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: textDark)),
                                  const SizedBox(height: 4),
                                  Text(body,
                                      style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: Colors.grey.shade700,
                                          height: 1.5)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text('I Understand',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: cyan)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPrivacyDialog() {
    const policy = [
      '1. Information We Collect\nWe collect your name, email, contact number, and payment details solely to process your membership and improve our services.',
      '2. How We Use Your Information\nYour data is used for membership management, billing, service notifications, and facility access. We do not share your data with third parties except as required by law.',
      '3. Data Security\nWe implement reasonable security measures to protect your personal information from unauthorized access, alteration, or disclosure.',
      '4. Your Rights\nYou may request access to, correction of, or deletion of your personal data at any time by contacting our front desk or support email.',
      '5. Cookies & Tracking\nOur digital services may use cookies to enhance user experience. You may disable cookies in your browser settings.',
      '6. Contact Us\nFor privacy concerns, reach us at primefitnesstaguig@gmail.com or visit our front desk in Taguig City.',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Color(0xFF22B8D8), Color(0xFF1BA0B8)]),
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Privacy Policy',
                          style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                      IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white70),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints()),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 280,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderGrey),
                        ),
                        child: ListView.builder(
                          itemCount: policy.length,
                          itemBuilder: (context, index) {
                            final text = policy[index];
                            final parts = text.split('\n');
                            final title = parts.first;
                            final body = parts.length > 1
                                ? parts.sublist(1).join('\n')
                                : '';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title,
                                      style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: textDark)),
                                  const SizedBox(height: 4),
                                  Text(body,
                                      style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: Colors.grey.shade700,
                                          height: 1.5)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text('I Understand',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: cyan)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int _stepNumberFor(_Screen s) {
    switch (s) {
      case _Screen.account:
        return 1;
      case _Screen.plan:
        return 2;
      case _Screen.paymentMethod:
      case _Screen.review:
        return 3;
      case _Screen.done:
        return 4;
    }
  }

  _StepStatus _statusFor(int step) {
    final current = _stepNumberFor(_screen);
    if (step < current) return _StepStatus.done;
    if (step == current) return _StepStatus.active;
    return _StepStatus.pending;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-bleed background photo. Falls back to the dark brand
          // background if the asset isn't found, instead of crashing.
          Image.asset(
            'assets/images/auth_bg.jpg',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) =>
                Container(color: darkBg),
          ),
          // Vignette: lighter near the center (keeping the photo's subject
          // visible behind the now-centered card) and darker toward the
          // edges, for a moodier, more premium frame.
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.15),
                radius: 1.3,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.32)
                ],
                stops: const [0.35, 1.0],
              ),
            ),
          ),
          // Bottom-heavy scrim so the lower edge of the frame reads darker
          // and moodier, matching a premium gym-app aesthetic.
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.4)
                ],
                stops: const [0.5, 1.0],
              ),
            ),
          ),
          // Even, overall darkening wash so text/card contrast stays
          // strong no matter where the card lands on the photo.
          Container(color: Colors.black.withValues(alpha: 0.1)),
          SafeArea(
            child: Center(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: _GlassCell(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(40, 40, 40, 36),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCellHeader(),
                          const SizedBox(height: 22),
                          _buildStepIndicator(),
                          const SizedBox(height: 22),
                          _buildScreenContent(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== CELL HEADER (logo + wordmark) ====================

  Widget _buildCellHeader() {
    return const Row(
      children: [
        PrimeFitBadge(size: 36),
        SizedBox(width: 10),
        PrimeFitWordmark(fontSize: 20),
      ],
    );
  }

  // ==================== COMPACT STEP INDICATOR ====================

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _stepDot(1, 'Account'),
        _stepLine(1),
        _stepDot(2, 'Plan'),
        _stepLine(2),
        _stepDot(3, 'Payment'),
        _stepLine(3),
        _stepDot(4, 'Done'),
      ],
    );
  }

  Widget _stepDot(int step, String label) {
    final status = _statusFor(step);
    final circleColor = switch (status) {
      _StepStatus.done => cyan,
      _StepStatus.active => gold,
      _StepStatus.pending => const Color(0xFFE1E4E8),
    };
    final labelColor =
        status == _StepStatus.pending ? Colors.black38 : textDark;
    return Column(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(shape: BoxShape.circle, color: circleColor),
          alignment: Alignment.center,
          child: status == _StepStatus.done
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : Text(
                  '$step',
                  style: GoogleFonts.inter(
                    color: status == _StepStatus.active
                        ? Colors.black
                        : Colors.black54,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
        ),
        const SizedBox(height: 5),
        Text(label,
            style: _AuthFonts.stepTitle(
              color: labelColor,
              weight: status == _StepStatus.active
                  ? FontWeight.w700
                  : FontWeight.w500,
            ).copyWith(fontSize: 10.5)),
      ],
    );
  }

  Widget _stepLine(int stepBefore) {
    final passed = _stepNumberFor(_screen) > stepBefore;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
            height: 2, color: passed ? cyan : const Color(0xFFE1E4E8)),
      ),
    );
  }

  // ==================== SCREEN ROUTER ====================

  Widget _buildScreenContent() {
    switch (_screen) {
      case _Screen.account:
        return _buildAccountScreen();
      case _Screen.plan:
        return _buildPlanScreen();
      case _Screen.paymentMethod:
        return _buildPaymentMethodScreen();
      case _Screen.review:
        return _buildReviewScreen();
      case _Screen.done:
        return _buildDoneScreen();
    }
  }

  // ==================== STEP 1: ACCOUNT ====================

  Widget _buildAccountScreen() {
    return Column(
      key: const ValueKey('account'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Start Your Journey', style: _AuthFonts.heading()),
        const SizedBox(height: 4),
        Text('Create your account and join the PrimeFit community.',
            style: _AuthFonts.subtitle()),
        const SizedBox(height: 18),
        // Name fields in one row: Last Name | First Name
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _field(
                  label: 'Last Name',
                  controller: _lastNameCtrl,
                  hint: 'Dela Cruz'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field(
                  label: 'First Name',
                  controller: _firstNameCtrl,
                  hint: 'Juan'),
            ),
          ],
        ),
        _field(
            label: 'Email Address',
            controller: _emailCtrl,
            hint: 'you@email.com',
            keyboardType: TextInputType.emailAddress),
        _field(
            label: 'Contact Number',
            controller: _contactCtrl,
            hint: '+63 9XX XXX XXXX',
            keyboardType: TextInputType.phone),
        _field(
          label: 'Password',
          controller: _passCtrl,
          hint: 'At least 8 characters',
          obscureText: _obscurePass,
          toggleObscure: () => setState(() => _obscurePass = !_obscurePass),
        ),
        _field(
          label: 'Confirm Password',
          controller: _confirmCtrl,
          hint: 'Re-enter password',
          obscureText: _obscureConfirm,
          toggleObscure: () =>
              setState(() => _obscureConfirm = !_obscureConfirm),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Transform.scale(
              scale: 0.9,
              child: Checkbox(
                value: _agreedToTerms,
                activeColor: cyan,
                onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(color: textDark, fontSize: 12.5),
                    children: [
                      const TextSpan(text: 'I agree to the '),
                      TextSpan(
                        text: 'Terms of Service',
                        style: _AuthFonts.link(
                                color: textDark, weight: FontWeight.w700)
                            .copyWith(decoration: TextDecoration.underline),
                        recognizer: _termsRecognizer,
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: _AuthFonts.link(
                                color: textDark, weight: FontWeight.w700)
                            .copyWith(decoration: TextDecoration.underline),
                        recognizer: _privacyRecognizer,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _primaryButton(
          'CONTINUE TO PLAN SELECTION →',
          _handleAccountContinue,
        ),
        const SizedBox(height: 14),
        Center(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.inter(color: Colors.black, fontSize: 12.5),
              children: [
                const TextSpan(text: 'Already have an account? '),
                TextSpan(
                  text: 'Sign in',
                  style: _AuthFonts.link(
                          size: 12.5, color: textDark, weight: FontWeight.w700)
                      .copyWith(decoration: TextDecoration.underline),
                  recognizer: _signInRecognizer,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== STEP 2: PLAN ====================

  Widget _buildPlanScreen() {
    return Column(
      key: const ValueKey('plan'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _backButton(() => setState(() => _screen = _Screen.account)),
        const SizedBox(height: 8),
        Text('Choose Your Plan', style: _AuthFonts.heading(size: 24)),
        const SizedBox(height: 4),
        Text('Pick the membership that fits your goals.',
            style: _AuthFonts.subtitle()),
        const SizedBox(height: 16),
        for (int i = 0; i < _plans.length; i++) _planCard(i),
        const SizedBox(height: 6),
        _primaryButton('CONTINUE TO PAYMENT →',
            () => setState(() => _screen = _Screen.paymentMethod)),
      ],
    );
  }

  Widget _planCard(int index) {
    final plan = _plans[index];
    final selected = _selectedPlanIndex == index;
    final price = plan.priceMonthly;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlanIndex = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
              color: selected ? cyan : borderGrey, width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: selected ? cyan : const Color(0xFFC8CCD2),
                    size: 20),
                const SizedBox(width: 8),
                Text(plan.name,
                    style: GoogleFonts.inter(
                        fontSize: 14.5, fontWeight: FontWeight.w700)),
                if (plan.popular) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: cyan, borderRadius: BorderRadius.circular(20)),
                    child: Text('Popular',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₱$price',
                        style: GoogleFonts.archivoBlack(
                            fontSize: 16, letterSpacing: -0.2)),
                    Text(plan.name,
                        style:
                            GoogleFonts.inter(fontSize: 10, color: textGrey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...plan.features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 5, left: 30),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 14, color: Color(0xFF22C55E)),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(f,
                            style: GoogleFonts.inter(
                                fontSize: 12, color: const Color(0xFF374151)))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== STEP 3a: PAYMENT METHOD ====================

  Widget _buildPaymentMethodScreen() {
    final planName = _plans[_selectedPlanIndex].name;
    final selectedOption = _paymentOptions[_selectedPaymentIndex];

    return Column(
      key: const ValueKey('paymentMethod'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _backButton(() => setState(() => _screen = _Screen.plan)),
        const SizedBox(height: 8),
        Text('Payment Method', style: _AuthFonts.heading(size: 24)),
        const SizedBox(height: 4),
        Text('Choose how to pay for your $planName plan.',
            style: _AuthFonts.subtitle()),
        const SizedBox(height: 18),
        for (int i = 0; i < _paymentOptions.length; i++) _paymentCard(i),
        const SizedBox(height: 6),
        _qrPaymentCard(selectedOption),
        const SizedBox(height: 16),
        _primaryButton(
          'REVIEW ORDER SUMMARY →',
          _hasConfirmedPayment
              ? () => setState(() => _screen = _Screen.review)
              : () {},
          disabled: !_hasConfirmedPayment,
        ),
        if (!_hasConfirmedPayment) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Upload your receipt and confirm your payment to continue.',
              style: _AuthFonts.body(size: 11.5, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  // Shows the real QR code for the selected e-wallet, a receipt upload box,
  // and the "I've Paid" confirmation step. The member must attach a photo
  // of their receipt before "I've Paid" is enabled -- this is what admin
  // will review to manually confirm the payment (see
  // complete_registration_api.php / pending_payments_api.php).
  Widget _qrPaymentCard(_PaymentOption option) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderGrey),
      ),
      child: Column(
        children: [
          Text('Scan to pay via ${option.name}',
              style:
                  GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 3),
          Text('₱$_computedPrice',
              style: GoogleFonts.archivoBlack(
                  fontSize: 18, color: cyan, letterSpacing: -0.2)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              option.qrAsset,
              width: 220,
              height: 300,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stack) => Container(
                width: 220,
                height: 300,
                color: const Color(0xFFF1F2F4),
                alignment: Alignment.center,
                child: const Icon(Icons.qr_code_2,
                    size: 50, color: Color(0xFFC8CCD2)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // NEW: receipt upload box. Tap to pick a screenshot/photo of the
          // payment receipt from the gallery. Shows a preview once picked.
          GestureDetector(
            onTap: _pickReceipt,
            child: Container(
              width: double.infinity,
              height: _receiptBytes == null ? 90 : 160,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _receiptBytes == null ? borderGrey : cyan,
                  width: _receiptBytes == null ? 1 : 1.5,
                ),
              ),
              child: _receiptBytes == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.upload_file_outlined,
                       color: textGrey, size: 22),
                        const SizedBox(height: 6),
                        Text('Upload proof of payment',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: textGrey)),
                      ],
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          // Image.memory works on web + desktop + mobile,
                          // unlike Image.file which Flutter Web rejects.
                          child: Image.memory(_receiptBytes!, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                                color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.edit,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (!_hasConfirmedPayment)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _receiptBytes == null
                    ? null
                    : () => setState(() => _hasConfirmedPayment = true),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(
                      color: _receiptBytes == null
                          ? const Color(0xFFE1E4E8)
                          : cyan,
                      width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text("I'VE PAID",
                    style: GoogleFonts.inter(
                        color: _receiptBytes == null ? textGrey : cyan,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 0.4)),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE7F9EF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle,
                      size: 16, color: Color(0xFF16A34A)),
                  const SizedBox(width: 8),
                  Text('Payment confirmed',
                      style: GoogleFonts.inter(
                          color: const Color(0xFF16A34A),
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _paymentCard(int index) {
    final opt = _paymentOptions[index];
    final selected = _selectedPaymentIndex == index;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedPaymentIndex = index;
        _hasConfirmedPayment = false;
        _receiptBytes = null; // reset receipt when switching e-wallet
        _receiptFileName = null;
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? cyan.withValues(alpha: 0.08) : Colors.white,
          border: Border.all(
              color: selected ? cyan : borderGrey, width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: selected ? Colors.white : const Color(0xFFF1F2F4),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child:
                  Icon(opt.icon, color: selected ? cyan : textGrey, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(opt.name,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(opt.subtitle,
                      style:
                          GoogleFonts.inter(color: textGrey, fontSize: 11.5)),
                ],
              ),
            ),
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? cyan : const Color(0xFFC8CCD2), size: 20),
          ],
        ),
      ),
    );
  }

  // ==================== STEP 3b: ORDER SUMMARY / REVIEW ====================

  Widget _buildReviewScreen() {
    final plan = _plans[_selectedPlanIndex];
    final payment = _paymentOptions[_selectedPaymentIndex];
    final name = _lastNameFirst;
    final email = _emailCtrl.text.trim().isEmpty
        ? 'you@email.com'
        : _emailCtrl.text.trim();
    final contact =
        _contactCtrl.text.trim().isEmpty ? '—' : _contactCtrl.text.trim();

    return Column(
      key: const ValueKey('review'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _backButton(() => setState(() => _screen = _Screen.paymentMethod)),
        const SizedBox(height: 8),
        Text('Order Summary', style: _AuthFonts.heading(size: 24)),
        const SizedBox(height: 4),
        Text('Confirm your details before proceeding to payment.',
            style: _AuthFonts.subtitle()),
        const SizedBox(height: 18),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderGrey),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Receipt-style header strip
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF22B8D8), Color(0xFF1BA0B8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: gold, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.fitness_center,
                          color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PrimeFit Fitness Gym',
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14)),
                          Text('Official Order Receipt',
                              style: GoogleFonts.inter(
                                  color: Colors.white70, fontSize: 10.5)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('UNPAID',
                          style: GoogleFonts.inter(
                              color: const Color(0xFFB07B00),
                              fontWeight: FontWeight.w700,
                              fontSize: 10)),
                    ),
                  ],
                ),
              ),
              // Perforated edge illusion
              SizedBox(
                height: 12,
                child: LayoutBuilder(builder: (context, constraints) {
                  final dotCount = (constraints.maxWidth / 14).floor();
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      dotCount,
                      (i) => Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: Color(0xFFE1E4E8)),
                      ),
                    ),
                  );
                }),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _receiptSectionHeader(Icons.person_outline, 'MEMBER', cyan),
                    const SizedBox(height: 6),
                    Text(name,
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(email,
                        style:
                            GoogleFonts.inter(color: textGrey, fontSize: 12)),
                    Text(contact,
                        style:
                            GoogleFonts.inter(color: textGrey, fontSize: 12)),
                    const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, color: borderGrey)),
                    _receiptSectionHeader(Icons.card_membership_outlined,
                        'MEMBERSHIP PLAN', gold),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${plan.name} Membership',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        Text('₱$_computedPrice',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w800, fontSize: 14)),
                      ],
                    ),
                    Text(plan.name,
                        style:
                            GoogleFonts.inter(color: textGrey, fontSize: 12)),
                    const SizedBox(height: 8),
                    ...plan.features.take(3).map(
                          (f) => Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline,
                                    size: 13, color: Color(0xFF22C55E)),
                                const SizedBox(width: 6),
                                Text(f,
                                    style: GoogleFonts.inter(
                                        fontSize: 12, color: textGrey)),
                              ],
                            ),
                          ),
                        ),
                    const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, color: borderGrey)),
                    _receiptSectionHeader(Icons.payments_outlined,
                        'PAYMENT METHOD', const Color(0xFF7C3AED)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(payment.icon, size: 16, color: textDark),
                        const SizedBox(width: 6),
                        Text(payment.name,
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                    // NEW: small confirmation that a receipt was attached.
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.attach_file,
                            size: 15, color: Color(0xFF16A34A)),
                        const SizedBox(width: 6),
                        Text('Receipt attached',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF16A34A),
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 13),
                      decoration: BoxDecoration(
                        color: cyan.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cyan.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Amount',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                  color: textDark)),
                          Text('₱$_computedPrice',
                              style: GoogleFonts.archivoBlack(
                                  fontSize: 18,
                                  color: cyan,
                                  letterSpacing: -0.2)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7E0),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFCE8B0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline,
                  size: 16, color: Color(0xFFB07B00)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  // UPDATED: message now reflects manual admin review
                  // instead of instant activation.
                  'Your receipt will be sent to our admin for verification. Your membership will be activated once payment is confirmed.',
                  style: GoogleFonts.inter(
                      fontSize: 11.5, color: const Color(0xFF8A6100)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _primaryButton(
          _submitting ? 'PROCESSING…' : 'CONFIRM & PROCEED TO PAYMENT →',
          _submitting ? () {} : _handleConfirmPayment,
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _sectionLabel(String text) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textGrey,
          letterSpacing: 0.6));

  Widget _receiptSectionHeader(IconData icon, String label, Color accentColor) {
    return Row(
      children: [
        Icon(icon, size: 13, color: accentColor),
        const SizedBox(width: 5),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: accentColor,
                letterSpacing: 0.6)),
      ],
    );
  }

  // ==================== STEP 4: DONE / RECEIPT ====================

  Widget _buildDoneScreen() {
    final plan = _plans[_selectedPlanIndex];
    final payment = _paymentOptions[_selectedPaymentIndex];
    final name = _lastNameFirst;
    // NEW: whether admin has already confirmed the payment.
    final isPending = _paymentStatus.toLowerCase() != 'paid' &&
        _paymentStatus.toLowerCase() != 'active';

    return Column(
      key: const ValueKey('done'),
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPending
                  ? const Color(0xFFFFF7E0)
                  : const Color(0xFFE7F9EF)),
          alignment: Alignment.center,
          child: Icon(
            isPending ? Icons.hourglass_top : Icons.check,
            color:
                isPending ? const Color(0xFFB07B00) : const Color(0xFF16A34A),
            size: 30,
          ),
        ),
        const SizedBox(height: 16),
        Text(isPending ? 'Almost There!' : 'You\'re In!',
            style: _AuthFonts.heading(size: 24)),
        const SizedBox(height: 4),
        Text(
          isPending
              ? 'Your receipt was sent to our admin — your membership will activate once payment is confirmed.'
              : 'Your PrimeFit membership is now active — let\'s get moving.',
          style: _AuthFonts.subtitle(),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderGrey),
          ),
          child: Column(
            children: [
              _receiptRow('Member', name),
              _receiptRow('Member ID', _memberId),
              _receiptRow('Plan', plan.name),
              _receiptRow('Amount Paid', '₱$_computedPrice'),
              _receiptRow('Payment via', payment.name),
              _receiptRow('Status', null,
                  statusWidget: _StatusPill(pending: isPending)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _primaryButton('GO TO DASHBOARD →', _goToDashboard),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _startOver,
          child: Text('Start Over',
              style: GoogleFonts.inter(
                  color: textGrey, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _receiptRow(String label, String? value, {Widget? statusWidget}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: textGrey, fontSize: 13)),
          statusWidget ??
              Text(value ?? '',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: textDark)),
        ],
      ),
    );
  }

  // ==================== SHARED UI HELPERS ====================

  Widget _backButton(VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.arrow_back, size: 15, color: textGrey),
          const SizedBox(width: 5),
          Text('Back',
              style: GoogleFonts.inter(color: textGrey, fontSize: 12.5)),
        ],
      ),
    );
  }

  Widget _primaryButton(String text, VoidCallback onTap,
      {bool disabled = false}) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: disabled ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: disabled ? const Color(0xFFE1E4E8) : Colors.black,
          foregroundColor: disabled ? textGrey : Colors.white,
          disabledBackgroundColor: const Color(0xFFE1E4E8),
          disabledForegroundColor: textGrey,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(text,
            style: _AuthFonts.button(
                size: 13.5, color: disabled ? textGrey : Colors.white)),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool obscureText = false,
    VoidCallback? toggleObscure,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _AuthFonts.label()),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: GoogleFonts.inter(fontSize: 13.5, color: Colors.black),
            cursorColor: gold,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(color: const Color(0xFF6B7280)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.92),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: Colors.black.withValues(alpha: 0.22), width: 1)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: Colors.black.withValues(alpha: 0.22), width: 1)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: gold, width: 1.8)),
              suffixIcon: toggleObscure != null
                  ? IconButton(
                      icon: Icon(
                          obscureText
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: textGrey,
                          size: 18),
                      onPressed: toggleObscure,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small status pill used on the receipt screen. Shows "Pending
/// Confirmation" (amber) until admin has reviewed the receipt, then
/// switches to "Paid · Active" (green) once confirmed.
class _StatusPill extends StatelessWidget {
  final bool pending;
  const _StatusPill({this.pending = true});

  @override
  Widget build(BuildContext context) {
    final color =
        pending ? const Color(0xFFB07B00) : const Color(0xFF16A34A);
    final icon = pending ? Icons.hourglass_top : Icons.check_circle;
    final label = pending ? 'Pending Confirmation' : 'Paid · Active';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.inter(
                color: color, fontWeight: FontWeight.w700, fontSize: 12.5)),
      ],
    );
  }
}
