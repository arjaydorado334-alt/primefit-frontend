import 'dart:async';
import 'dart:typed_data';
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
// 👇 Connects the "Sign in" link on the card to your LoginPage popup.
// Adjust this path if login_page.dart lives somewhere else (it should be
// in the same folder as create_account.dart based on its own imports).
import 'login_page.dart';

/// Shared typography for the onboarding flow. Redesigned to match the
/// Haws Prints admin sign-in look: clean bold Inter headings, muted
/// subtitles, labels above inputs, and a serif brand name in the header.
///
/// Defaults are light (white / off-white) because they render directly on
/// the dark card -- text *inside* a white surface (the receipt) always
/// passes its own explicit dark color at the call site and is unaffected.
class _AuthFonts {
  // Step heading — bold, clean sans.
  static TextStyle heading({double size = 26, Color color = Colors.white}) =>
      GoogleFonts.inter(
        fontSize: size,
        color: color,
        height: 1.2,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      );

  // Subtitle under the heading.
  static TextStyle subtitle(
          {double size = 14.5, Color color = const Color(0xFF9CA3AF)}) =>
      GoogleFonts.inter(
          fontSize: size,
          color: color,
          height: 1.45,
          fontWeight: FontWeight.w400);

  // Body / description text.
  static TextStyle body(
          {double size = 13,
          Color color = const Color(0xFFC4C8CE),
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

  // Primary button label — bold.
  static TextStyle button({double size = 14, Color color = Colors.black}) =>
      GoogleFonts.inter(
          fontSize: size,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5);

  // Step indicator labels.
  static TextStyle stepTitle(
          {required Color color, required FontWeight weight}) =>
      GoogleFonts.inter(fontSize: 12, color: color, fontWeight: weight);

  // Small label shown above each input.
  static TextStyle label() => GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: const Color(0xFFC4C8CE));
}

/// PrimeFit onboarding, shown as a popup over the current page.
/// Flow: Create Account -> Choose Plan -> Payment Method -> Order Summary -> Done (Receipt)
///
/// Open it from anywhere (landing page, navbar, Sign In popup, etc.) with:
///
///   CreateAccountPage.show(context);
///
/// The Account step is local-only validation. The Member, Membership, and
/// Payment rows are all created TOGETHER in a single transaction when the
/// customer confirms payment on the Review screen (see
/// _handleConfirmPayment / complete_registration_api.php) -- so no account
/// exists in the database until payment is actually confirmed.
///
/// The member must attach a screenshot/photo of their payment receipt on
/// the QR payment screen before "I'VE PAID" unlocks. The receipt file is
/// sent together with the registration call so admin can review it and
/// manually confirm the payment (see CompleteRegistrationService.register).
class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  /// Shows the create-account popup over the current page. If the member
  /// taps "Sign in" inside it, the popup closes and the Sign In popup opens.
  static Future<void> show(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      // A multi-step form: don't let a stray click outside wipe it. Use
      // the X button to close.
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (_) => const CreateAccountPage(),
    );
    if (result == 'signin' && context.mounted) {
      await LoginPage.show(context);
    }
  }

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
  // cyan / gold match AppColors so the accents stay identical to the
  // Sign In screen's, instead of drifting apart.
  static const Color cyan = AppColors.cyan;
  static const Color gold = AppColors.yellow;
  static const Color cardBg = Color(0xFF15161A); // the card (same as Sign In)
  static const Color cardBorder = Color(0xFF262832);
  static const Color fieldFill = Color(0xFF1E2025); // inputs (same as Sign In)
  static const Color fieldBorder = Color(0xFF2C2F36);
  static const Color tileFill = Color(0xFF1A1C21); // inner tiles/cards
  static const Color tileBorder = Color(0xFF2C2F36);
  static const Color tileSelected = Color(0xFF1D2A2E);
  static const Color mutedText = Color(0xFF7D838C);
  static const Color hintText = Color(0xFF6F7681);

  // ---------------- account form state ----------------
  final _lastNameCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  // Optional at registration -- Age (derived from this) and Gender are
  // shown later in Profile/Progress once set, but a member can also skip
  // these here and fill them in afterwards via Profile Settings.
  DateTime? _selectedDob;
  String? _selectedGender;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  // Message banner shown at the bottom of the popup. (A normal SnackBar
  // would appear on the page *behind* the popup, hidden by the dark
  // backdrop, so messages are shown inside the popup instead.)
  String? _notice;
  Timer? _noticeTimer;

  // The real MemberID assigned by MySQL (AUTO_INCREMENT) after registration.
  // Null until the account step successfully registers the member.
  int? _dbMemberId;

  // Maps each plan's DurationLabel (e.g. "1 Year") to its real PlanID
  // from the Plans table. Populated once we reach the plan screen.
  Map<String, int> _planIdByLabel = {};

  // ---------------- plan state ----------------
  int _selectedPlanIndex = 2; // 7 Months pre-selected

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
  // the QR step. Resets whenever they switch payment methods. Also
  // requires a receipt image to be attached before it can be set to true.
  bool _hasConfirmedPayment = false;

  // ---------------- receipt state ----------------
  String _memberId = '';
  bool _submitting = false;

  // The proof-of-payment screenshot/photo the member attaches on the QR
  // payment screen. Required before "I'VE PAID" can be pressed, and sent
  // together with the registration call so admin can review it.
  //
  // Stored as raw bytes (Uint8List) instead of dart:io File -- File +
  // Image.file() are NOT supported on Flutter Web, and this app runs as
  // a web build (Chrome). Uint8List + Image.memory() works on every
  // platform (web, desktop, mobile) since it never touches the local
  // filesystem API.
  Uint8List? _receiptBytes;
  String? _receiptFileName;

  // Holds the payment status returned by the API ("Pending" or
  // "Paid"/"Active") so the Done screen can show the right pill/message.
  String _paymentStatus = 'Pending';

  int get _computedPrice => _plans[_selectedPlanIndex].priceMonthly;

  // Wide (desktop/tablet) layout uses two-column rows inside the card;
  // narrow (phone) stacks everything in one column.
  bool get _wide => MediaQuery.of(context).size.width >= 700;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()..onTap = _showTermsDialog;
    _privacyRecognizer = TapGestureRecognizer()..onTap = _showPrivacyDialog;
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
    _noticeTimer?.cancel();
    _lastNameCtrl.dispose();
    _firstNameCtrl.dispose();
    _emailCtrl.dispose();
    _contactCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  // Shows a short message inside the popup (auto-hides after a few seconds).
  void _snack(String message) {
    _noticeTimer?.cancel();
    setState(() => _notice = message);
    _noticeTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _notice = null);
    });
  }

  void _clearNotice() {
    _noticeTimer?.cancel();
    _notice = null;
  }

  // Lets the member pick a screenshot/photo of their GCash/Maya payment
  // receipt from their gallery. Called from the upload box on the QR
  // payment screen (see _qrPaymentCard).
  Future<void> _pickReceipt() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      // Read as bytes instead of wrapping in a dart:io File -- this is
      // what makes it work on Flutter Web as well as desktop/mobile.
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
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
      _snack(
          'Please agree to the Terms of Service, Privacy Policy, and Data Privacy consent.');
      return;
    }
    // Note: no database write happens here. The account is only created
    // once payment is confirmed at the end of the flow (see
    // _handleConfirmPayment), so nothing exists in the Members table
    // until the customer has actually paid.
    setState(() {
      _clearNotice();
      _screen = _Screen.plan;
    });
  }

  // Closes this popup (the X button).
  void _close() {
    Navigator.of(context).pop();
  }

  void _goToSignIn() {
    // Closes this popup and tells CreateAccountPage.show to open the
    // Sign In popup in its place.
    Navigator.of(context).pop('signin');
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
    //
    // Wrapped in try/catch so that if the server is unreachable (or the
    // service throws instead of returning a map), the button doesn't get
    // stuck on "PROCESSING…" forever.
    dynamic result;
    try {
      result = await CompleteRegistrationService.register(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        phone: _contactCtrl.text.trim(),
        dateOfBirth: _selectedDob == null
            ? ''
            : '${_selectedDob!.year.toString().padLeft(4, '0')}-'
                '${_selectedDob!.month.toString().padLeft(2, '0')}-'
                '${_selectedDob!.day.toString().padLeft(2, '0')}',
        gender: _selectedGender ?? '',
        address: '',
        planId: planId,
        paymentMethod: _paymentOptions[_selectedPaymentIndex].name,
        receiptBytes: _receiptBytes,
        receiptFileName: _receiptFileName ?? 'receipt.jpg',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _snack(
          'Could not reach the server. Please check your connection and try again.');
      return;
    }

    if (!mounted) return;

    if (result == null || result['success'] != true) {
      setState(() => _submitting = false);
      _snack(result?['message']?.toString() ??
          'Could not complete registration. Please try again.');
      return;
    }

    if (result['status']?.toString().toLowerCase() == 'pending') {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _paymentStatus = 'Pending';
        _memberId = 'Pending approval';
        _screen = _Screen.done;
      });
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

    // The payment/membership status coming back from the API. Defaults to
    // "Pending" if the backend doesn't send one yet, so the Done screen
    // doesn't accidentally claim "Active" before admin has actually
    // confirmed anything.
    final paymentStatus = (result['status']?.toString() ?? 'Pending').trim();

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

  void _goToDashboard() {
    // Clears the whole stack (this popup + the pages behind it) so the
    // back button on the dashboard doesn't lead back into onboarding.
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
      _selectedDob = null;
      _selectedGender = null;
      _selectedPlanIndex = 2;
      _selectedPaymentIndex = 0;
      _dbMemberId = null;
      _hasConfirmedPayment = false;
      _receiptBytes = null;
      _receiptFileName = null;
      _paymentStatus = 'Pending';
      _clearNotice();
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
      builder: (ctx) =>
          const _LegalDialog(title: 'Terms of Service', sections: terms),
    );
  }

  void _showPrivacyDialog() {
    const policy = [
      '1. Information We Collect\nWe collect your name, email, contact number, date of birth, gender, and payment details (including the proof-of-payment image you upload) solely to process your membership and improve our services.',
      '2. How We Use Your Information\nYour data is used for membership management, billing, service notifications, and facility access. We do not share your data with third parties except as required by law.',
      '3. Data Privacy Act Compliance (RA 10173)\nPrimeFit Fitness Gym processes your personal information in accordance with Republic Act No. 10173, or the Data Privacy Act of 2012, its Implementing Rules and Regulations, and the issuances of the National Privacy Commission (NPC). Your data is collected for a specified and legitimate purpose, kept only as long as necessary, and processed fairly and lawfully.',
      '4. Data Security\nWe implement reasonable organizational, physical, and technical security measures to protect your personal information from unauthorized access, alteration, or disclosure.',
      '5. Your Rights as a Data Subject\nUnder RA 10173, you have the right to be informed, to access, to object, to rectify errors, to request erasure or blocking, to data portability, to claim damages, and to file a complaint with the National Privacy Commission (www.privacy.gov.ph). To exercise these rights, contact our front desk or support email.',
      '6. Cookies & Tracking\nOur digital services may use cookies to enhance user experience. You may disable cookies in your browser settings.',
      '7. Contact Us\nFor privacy concerns or to reach our data protection contact, email primefitnesstaguig@gmail.com or visit our front desk in Taguig City.',
    ];

    showDialog(
      context: context,
      builder: (ctx) =>
          const _LegalDialog(title: 'Privacy Policy', sections: policy),
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

  // The steps (Account/Plan/Payment/Review/Done) are all one popup --
  // they're swapped via local `_screen` state, not separate pushed pages
  // -- so without this, the Esc key / browser back button would close
  // the whole popup from any step, instead of going to the previous step
  // like a user would expect. Returns null for Account/Done: there's no
  // previous step to fall back to, so Esc there just closes the popup.
  _Screen? _previousStep(_Screen current) {
    switch (current) {
      case _Screen.plan:
        return _Screen.account;
      case _Screen.paymentMethod:
        return _Screen.plan;
      case _Screen.review:
        return _Screen.paymentMethod;
      case _Screen.account:
      case _Screen.done:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final previousStep = _previousStep(_screen);
    return PopScope(
      // Don't let Esc / back close the popup while the registration is
      // being submitted.
      canPop: previousStep == null && !_submitting,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _submitting || previousStep == null) return;
        setState(() => _screen = previousStep);
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.symmetric(
          horizontal: _wide ? 24 : 12,
          vertical: 24,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Stack(
            children: [
              // Scrolls on short windows so the card never overflows.
              SingleChildScrollView(child: _buildCard()),
              // Close (X) button -- stays fixed at the popup's top-right.
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  tooltip: 'Close',
                  onPressed: _submitting ? null : _close,
                  icon: const Icon(Icons.close_rounded,
                      size: 22, color: Color(0xFF9CA3AF)),
                ),
              ),
              // Validation / error messages.
              if (_notice != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: _noticeBanner(_notice!),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _noticeBanner(String message) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A1518),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF7F2A33)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline,
                size: 18, color: Color(0xFFFF6B6B)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: Colors.white, height: 1.4)),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== CARD ====================
  // One dark card (same look as the Sign In popup). Every step renders
  // inside this same card, so the layout stays consistent across steps.

  Widget _buildCard() {
    final wide = _wide;
    return Container(
      padding: EdgeInsets.fromLTRB(wide ? 44 : 22, 36, wide ? 44 : 22, 32),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 80,
            offset: const Offset(0, 30),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildStepIndicator(),
          const SizedBox(height: 26),
          _buildScreenContent(),
        ],
      ),
    );
  }

  // Centered brand header: the cyan/gold PrimeFit wordmark and a
  // tracked-caps subtitle (the round logo was removed).
  Widget _buildHeader() {
    return Column(
      children: [
        const PrimeFitWordmark(fontSize: 24),
        const SizedBox(height: 6),
        Text('MEMBER REGISTRATION',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
                color: const Color(0xFFC9CDD3))),
      ],
    );
  }

  // ==================== STEP INDICATOR ====================

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _stepItem(1, 'Account'),
        _stepLine(1),
        _stepItem(2, 'Plan'),
        _stepLine(2),
        _stepItem(3, 'Payment'),
        _stepLine(3),
        _stepItem(4, 'Done'),
      ],
    );
  }

  // Number circle + label side by side. On narrow screens only the active
  // step shows its label, so the row never overflows.
  Widget _stepItem(int step, String label) {
    final status = _statusFor(step);
    final circleColor = switch (status) {
      _StepStatus.done => cyan,
      _StepStatus.active => gold,
      _StepStatus.pending => const Color(0xFF2A2D32),
    };
    final labelColor = status == _StepStatus.pending
        ? const Color(0xFF8A9099)
        : Colors.white;
    final showLabel = _wide || status == _StepStatus.active;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(shape: BoxShape.circle, color: circleColor),
          alignment: Alignment.center,
          child: status == _StepStatus.done
              ? const Icon(Icons.check, size: 14, color: Colors.black)
              : Text(
                  '$step',
                  style: GoogleFonts.inter(
                    color: status == _StepStatus.active
                        ? Colors.black
                        : const Color(0xFF8A9099),
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                  ),
                ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 8),
          Text(label,
              style: _AuthFonts.stepTitle(
                color: labelColor,
                weight: status == _StepStatus.active
                    ? FontWeight.w700
                    : FontWeight.w500,
              )),
        ],
      ],
    );
  }

  Widget _stepLine(int stepBefore) {
    final passed = _stepNumberFor(_screen) > stepBefore;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        color: passed ? cyan : const Color(0xFF33363C),
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
        Text('Start your journey', style: _AuthFonts.heading()),
        const SizedBox(height: 6),
        Text('Create your account and join the PrimeFit community.',
            style: _AuthFonts.subtitle()),
        const SizedBox(height: 24),
        _pair(
          _field(
              label: 'Last name',
              controller: _lastNameCtrl,
              hint: 'Dela Cruz'),
          _field(
              label: 'First name', controller: _firstNameCtrl, hint: 'Juan'),
        ),
        _pair(
          _field(
              label: 'Email address',
              controller: _emailCtrl,
              hint: 'you@email.com',
              keyboardType: TextInputType.emailAddress),
          _field(
              label: 'Contact number',
              controller: _contactCtrl,
              hint: '+63 9XX XXX XXXX',
              keyboardType: TextInputType.phone),
        ),
        _pair(_dateOfBirthField(), _genderField()),
        _pair(
          _field(
            label: 'Password',
            controller: _passCtrl,
            hint: 'At least 8 characters',
            obscureText: _obscurePass,
            toggleObscure: () => setState(() => _obscurePass = !_obscurePass),
          ),
          _field(
            label: 'Confirm password',
            controller: _confirmCtrl,
            hint: 'Re-enter password',
            obscureText: _obscureConfirm,
            toggleObscure: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ),
        _consentBox(),
        const SizedBox(height: 22),
        _primaryButton(
          'CONTINUE TO PLAN SELECTION →',
          _handleAccountContinue,
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Already have an account?',
                style: _AuthFonts.subtitle(size: 13.5)),
            const SizedBox(width: 6),
            InkWell(
              onTap: _goToSignIn,
              child: Text('Sign in',
                  style: _AuthFonts.link(size: 13.5, color: cyan)),
            ),
          ],
        ),
      ],
    );
  }

  // Terms + Data Privacy Act (RA 10173) consent in one compact box
  // (replaces the old separate privacy notice + checkbox).
  Widget _consentBox() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: tileFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tileBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: _agreedToTerms,
              activeColor: cyan,
              checkColor: Colors.black,
              side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.35), width: 1.5),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                    color: const Color(0xFF9AA0A8),
                    fontSize: 12.5,
                    height: 1.55),
                children: [
                  const TextSpan(text: 'I agree to the '),
                  TextSpan(
                    text: 'Terms of Service',
                    style: _AuthFonts.link(
                            size: 12.5, color: cyan, weight: FontWeight.w700)
                        .copyWith(decoration: TextDecoration.underline),
                    recognizer: _termsRecognizer,
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: _AuthFonts.link(
                            size: 12.5, color: cyan, weight: FontWeight.w700)
                        .copyWith(decoration: TextDecoration.underline),
                    recognizer: _privacyRecognizer,
                  ),
                  // Explicit consent under RA 10173
                  const TextSpan(
                    text: ', and I consent to the collection and '
                        'processing of my personal data in accordance '
                        'with RA 10173 (Data Privacy Act of 2012). Your '
                        'data is used only for membership, billing, and '
                        'facility access.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== STEP 2: PLAN ====================

  Widget _buildPlanScreen() {
    return Column(
      key: const ValueKey('plan'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choose your plan', style: _AuthFonts.heading()),
        const SizedBox(height: 6),
        Text('Pick the membership that fits your goals.',
            style: _AuthFonts.subtitle()),
        const SizedBox(height: 22),
        _planGrid(),
        const SizedBox(height: 10),
        _primaryButton('CONTINUE TO PAYMENT →',
            () => setState(() => _screen = _Screen.paymentMethod)),
      ],
    );
  }

  // 2 x 2 grid on wide screens, a single column on phones.
  Widget _planGrid() {
    if (!_wide) {
      return Column(
        children: [
          for (int i = 0; i < _plans.length; i++)
            Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _planCard(i)),
        ],
      );
    }
    return Column(
      children: [
        for (int r = 0; r < _plans.length; r += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _planCard(r)),
                const SizedBox(width: 12),
                if (r + 1 < _plans.length)
                  Expanded(child: _planCard(r + 1))
                else
                  const Expanded(child: SizedBox()),
              ],
            ),
          ),
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
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? tileSelected : tileFill,
          border: Border.all(
              color: selected ? cyan : tileBorder, width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: selected ? cyan : const Color(0xFF5B616A),
                    size: 20),
                const SizedBox(width: 8),
                Text(plan.name,
                    style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                if (plan.popular) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: cyan, borderRadius: BorderRadius.circular(20)),
                    child: Text('Popular',
                        style: GoogleFonts.inter(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
                const Spacer(),
                Text('₱$price',
                    style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ],
            ),
            const SizedBox(height: 12),
            ...plan.features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 28),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 14, color: Color(0xFF22C55E)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(f,
                            style: GoogleFonts.inter(
                                fontSize: 12, color: const Color(0xFFA7ADB5)))),
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
        Text('Payment method', style: _AuthFonts.heading()),
        const SizedBox(height: 6),
        Text('Choose how to pay for your $planName plan.',
            style: _AuthFonts.subtitle()),
        const SizedBox(height: 22),
        _paymentOptionsRow(),
        const SizedBox(height: 14),
        _qrPaymentCard(selectedOption),
        const SizedBox(height: 20),
        _primaryButton(
          'REVIEW ORDER SUMMARY →',
          _hasConfirmedPayment
              ? () => setState(() => _screen = _Screen.review)
              : () {},
          disabled: !_hasConfirmedPayment,
        ),
        if (!_hasConfirmedPayment) ...[
          const SizedBox(height: 10),
          Center(
            child: Text(
              'Upload your receipt and confirm your payment to continue.',
              style: _AuthFonts.body(size: 11.5, color: mutedText),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  // GCash / Maya side by side on wide screens, stacked on phones.
  Widget _paymentOptionsRow() {
    if (!_wide) {
      return Column(
        children: [
          for (int i = 0; i < _paymentOptions.length; i++)
            Padding(
                padding: EdgeInsets.only(
                    bottom: i == _paymentOptions.length - 1 ? 0 : 12),
                child: _paymentCard(i)),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < _paymentOptions.length; i++) ...[
          if (i != 0) const SizedBox(width: 12),
          Expanded(child: _paymentCard(i)),
        ],
      ],
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? tileSelected : tileFill,
          border: Border.all(
              color: selected ? cyan : tileBorder, width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2D32),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child:
                  Icon(opt.icon, color: selected ? cyan : mutedText, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(opt.name,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(opt.subtitle,
                      style:
                          GoogleFonts.inter(color: mutedText, fontSize: 11.5)),
                ],
              ),
            ),
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? cyan : const Color(0xFF5B616A), size: 20),
          ],
        ),
      ),
    );
  }

  // Shows the real QR code for the selected e-wallet, a receipt upload box,
  // and the "I've Paid" confirmation step. The member must attach a photo
  // of their receipt before "I've Paid" is enabled -- this is what admin
  // will review to manually confirm the payment (see
  // complete_registration_api.php / pending_payments_api.php).
  //
  // Wide: QR on the left, pay details + upload on the right (keeps the
  // step short). Narrow: stacked.
  Widget _qrPaymentCard(_PaymentOption option) {
    final qr = ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.asset(
        option.qrAsset,
        width: 190,
        height: 260,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stack) => Container(
          width: 190,
          height: 260,
          color: const Color(0xFFF1F2F4),
          alignment: Alignment.center,
          child:
              const Icon(Icons.qr_code_2, size: 50, color: Color(0xFFC8CCD2)),
        ),
      ),
    );

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Scan to pay via ${option.name}',
            textAlign: _wide ? TextAlign.left : TextAlign.center,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white)),
        const SizedBox(height: 4),
        Text('₱$_computedPrice',
            textAlign: _wide ? TextAlign.left : TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 22, fontWeight: FontWeight.w800, color: cyan)),
        const SizedBox(height: 14),
        _receiptUploadBox(),
        const SizedBox(height: 12),
        _ivePaidControl(),
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tileFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tileBorder),
      ),
      child: _wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                qr,
                const SizedBox(width: 22),
                Expanded(child: details),
              ],
            )
          : Column(
              children: [
                qr,
                const SizedBox(height: 16),
                details,
              ],
            ),
    );
  }

  // Receipt upload box. Tap to pick a screenshot/photo of the payment
  // receipt from the gallery. Shows a preview once picked.
  Widget _receiptUploadBox() {
    return GestureDetector(
      onTap: _pickReceipt,
      child: Container(
        width: double.infinity,
        height: _receiptBytes == null ? 90 : 150,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _receiptBytes == null ? fieldBorder : cyan,
            width: _receiptBytes == null ? 1 : 1.5,
          ),
        ),
        child: _receiptBytes == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.upload_file_outlined,
                      color: mutedText, size: 22),
                  const SizedBox(height: 6),
                  Text('Upload proof of payment',
                      style: GoogleFonts.inter(fontSize: 12, color: mutedText)),
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
                      child:
                          const Icon(Icons.edit, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // "I'VE PAID" button (locked until a receipt is attached), then the
  // "Payment confirmed" pill.
  Widget _ivePaidControl() {
    if (_hasConfirmedPayment) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFF12301F),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 16, color: Color(0xFF4ADE80)),
            const SizedBox(width: 8),
            Text('Payment confirmed',
                style: GoogleFonts.inter(
                    color: const Color(0xFF4ADE80),
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ],
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _receiptBytes == null
            ? null
            : () => setState(() => _hasConfirmedPayment = true),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 13),
          side: BorderSide(
              color: _receiptBytes == null ? fieldBorder : cyan, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text("I'VE PAID",
            style: GoogleFonts.inter(
                color: _receiptBytes == null ? hintText : cyan,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 0.4)),
      ),
    );
  }

  // ==================== STEP 3b: ORDER SUMMARY / REVIEW ====================

  // Money with thousands separators, e.g. 2400 -> "₱2,400".
  String _money(int value) {
    final digits = value.toString();
    final out = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i != 0 && (digits.length - i) % 3 == 0) out.write(',');
      out.write(digits[i]);
    }
    return '₱$out';
  }

  String _todayText() {
    const months = [
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
    final d = DateTime.now();
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

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
        Text('Order summary', style: _AuthFonts.heading()),
        const SizedBox(height: 6),
        Text('Confirm your details before submitting for verification.',
            style: _AuthFonts.subtitle()),
        const SizedBox(height: 22),
        // Simple receipt-style summary (same layout as the receipt in the
        // member portal's payment history).
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: _ReceiptPaper(
              title: 'ORDER SUMMARY',
              details: [
                _RLine('Date', _todayText()),
                _RLine('Member', name),
                _RLine('Email', email),
                _RLine('Contact', contact),
              ],
              itemName: '${plan.name} Membership',
              itemAmount: _money(_computedPrice),
              totalLabel: 'TOTAL',
              summary: [
                _RLine('Payment method', payment.name),
                _RLine('Receipt', 'Attached'),
                _RLine('Status', 'UNPAID', bold: true),
              ],
              footerTitle: 'Almost done!',
              footerNote:
                  'Your receipt will be sent to our admin for verification. '
                  'Your membership will be activated once payment is confirmed.',
            ),
          ),
        ),
        const SizedBox(height: 22),
        _primaryButton(
          _submitting ? 'PROCESSING…' : 'SUBMIT FOR VERIFICATION →',
          _submitting ? () {} : _handleConfirmPayment,
          disabled: _submitting,
        ),
      ],
    );
  }

  // ==================== STEP 4: DONE / RECEIPT ====================

  Widget _buildDoneScreen() {
    final plan = _plans[_selectedPlanIndex];
    final payment = _paymentOptions[_selectedPaymentIndex];
    final name = _lastNameFirst;
    // Whether admin has already confirmed the payment.
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
        Text(isPending ? 'Almost there!' : 'You\'re in!',
            textAlign: TextAlign.center, style: _AuthFonts.heading()),
        const SizedBox(height: 6),
        Text(
          isPending
              ? 'Your receipt was sent to our admin — your membership will activate once payment is confirmed.'
              : 'Your PrimeFit membership is now active — let\'s get moving.',
          style: _AuthFonts.subtitle(),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 22),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: _ReceiptPaper(
              title: isPending ? 'SUBMISSION SUMMARY' : 'OFFICIAL RECEIPT',
              details: [
                _RLine('Date', _todayText()),
                _RLine('Member', name),
                _RLine('Member ID', _memberId),
              ],
              itemName: '${plan.name} Membership',
              itemAmount: _money(_computedPrice),
              totalLabel: isPending ? 'AMOUNT FOR REVIEW' : 'TOTAL PAID',
              summary: [
                _RLine('Payment method', payment.name),
                _RLine('Status',
                    isPending ? 'PENDING CONFIRMATION' : 'PAID · ACTIVE',
                    bold: true),
              ],
              footerTitle: 'Thank you for joining PrimeFit!',
              footerNote: isPending
                  ? 'Your membership activates once admin confirms your payment.'
                  : 'Keep this receipt as your proof of payment.',
            ),
          ),
        ),
        const SizedBox(height: 22),
        _primaryButton(isPending ? 'BACK TO HOME' : 'GO TO DASHBOARD →',
            isPending ? () => Navigator.of(context).pop() : _goToDashboard),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _startOver,
          child: Text('Start Over',
              style: GoogleFonts.inter(
                  color: AppColors.textMutedOnDark,
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  // ==================== SHARED UI HELPERS ====================

  // Gold pill button. Disabled state is a muted dark pill.
  Widget _primaryButton(String text, VoidCallback onTap,
      {bool disabled = false}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: disabled ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: Colors.black,
          disabledBackgroundColor: const Color(0xFF2A2D32),
          disabledForegroundColor: hintText,
          elevation: 0,
          shape: const StadiumBorder(),
        ),
        child: Text(text,
            style: _AuthFonts.button(
                size: 14, color: disabled ? hintText : Colors.black)),
      ),
    );
  }

  // Two fields side by side on wide screens, stacked on phones.
  Widget _pair(Widget a, Widget b) {
    if (!_wide) return Column(children: [a, b]);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: 16),
        Expanded(child: b),
      ],
    );
  }

  // Label above the input (Haws-style), with optional "(optional)" hint.
  Widget _labeled(String label, Widget input, {bool optional = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: _AuthFonts.label(),
              children: [
                if (optional)
                  TextSpan(
                    text: ' (optional)',
                    style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: hintText),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          input,
        ],
      ),
    );
  }

  // Dark filled input -- no floating label, the label lives above it.
  InputDecoration _inputDecoration({String? hint, Widget? suffixIcon}) {
    OutlineInputBorder border(Color c, [double w = 1.2]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(fontSize: 14.5, color: hintText),
      filled: true,
      fillColor: fieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      suffixIcon: suffixIcon,
      border: border(fieldBorder),
      enabledBorder: border(fieldBorder),
      focusedBorder: border(cyan, 1.6),
    );
  }

  // Date of Birth -- optional. Tapping opens a date picker (same pattern
  // as Profile Settings' DOB field) instead of free-text entry, so the
  // value is always a valid, unambiguous date.
  Widget _dateOfBirthField() {
    final text = _selectedDob == null
        ? 'MM/DD/YYYY'
        : '${_selectedDob!.month.toString().padLeft(2, '0')}/'
            '${_selectedDob!.day.toString().padLeft(2, '0')}/'
            '${_selectedDob!.year}';
    return _labeled(
      'Date of birth',
      optional: true,
      InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _selectedDob ?? DateTime(2000, 1, 1),
            firstDate: DateTime(1930),
            lastDate: DateTime.now(),
            builder: (context, child) => Theme(
              data: Theme.of(context)
                  .copyWith(colorScheme: const ColorScheme.light(primary: gold)),
              child: child!,
            ),
          );
          if (picked != null) setState(() => _selectedDob = picked);
        },
        child: InputDecorator(
          decoration: _inputDecoration(
            suffixIcon: const Icon(Icons.calendar_today_outlined,
                size: 17, color: mutedText),
          ),
          child: Text(text,
              style: GoogleFonts.inter(
                  fontSize: 14.5,
                  color: _selectedDob == null ? hintText : Colors.white)),
        ),
      ),
    );
  }

  // Gender -- optional. A dropdown rather than free text, matching the
  // "pull-down menu instead of free text" pattern used elsewhere.
  Widget _genderField() {
    const options = ['Male', 'Female', 'Other'];
    return _labeled(
      'Gender',
      optional: true,
      InputDecorator(
        isEmpty: _selectedGender == null,
        decoration: _inputDecoration(),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedGender,
            hint: Text('Select',
                style: GoogleFonts.inter(fontSize: 14.5, color: hintText)),
            isExpanded: true,
            isDense: true,
            dropdownColor: fieldFill,
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: mutedText),
            style: GoogleFonts.inter(fontSize: 14.5, color: Colors.white),
            items: options
                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                .toList(),
            onChanged: (v) => setState(() => _selectedGender = v),
          ),
        ),
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
    return _labeled(
      label,
      TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(fontSize: 14.5, color: Colors.white),
        cursorColor: cyan,
        decoration: _inputDecoration(
          hint: hint,
          suffixIcon: toggleObscure != null
              ? IconButton(
                  icon: Icon(
                      obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: mutedText,
                      size: 19),
                  onPressed: toggleObscure,
                )
              : null,
        ),
      ),
    );
  }
}

/// Shared dark-themed legal-document popup -- used for both the Terms of
/// Service and Privacy Policy modals so they stay visually identical.
/// One dark surface top to bottom (no separate colored header bar), white
/// title/section-heading text, muted-light body text, and a solid gold
/// "I Understand" button.
class _LegalDialog extends StatelessWidget {
  final String title;
  final List<String> sections;
  const _LegalDialog({required this.title, required this.sections});

  @override
  Widget build(BuildContext context) {
    // Responsive: the width caps to a fraction of the viewport on narrow
    // screens instead of a fixed maxWidth, and the scrollable section's
    // height is a clamped fraction of the viewport height.
    final viewport = MediaQuery.of(context).size;
    final dialogMaxWidth = viewport.width < 680 ? viewport.width * 0.92 : 620.0;
    final sectionHeight = (viewport.height * 0.5).clamp(280.0, 460.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dialogMaxWidth),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 22, 26, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title,
                        style: GoogleFonts.inter(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white70),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints()),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: sectionHeight,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.darkBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: ListView.builder(
                        itemCount: sections.length,
                        itemBuilder: (context, index) {
                          final text = sections[index];
                          final parts = text.split('\n');
                          final sectionTitle = parts.first;
                          final body = parts.length > 1
                              ? parts.sublist(1).join('\n')
                              : '';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(sectionTitle,
                                    style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                                const SizedBox(height: 5),
                                Text(body,
                                    style: GoogleFonts.inter(
                                        fontSize: 13.5,
                                        color: AppColors.textMutedOnDark,
                                        height: 1.55)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: AppColors.onGold,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('I Understand',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Simple receipt layout (used by the Order Summary and Done steps)
// ---------------------------------------------------------------------------

/// One "label ........ value" line on the receipt.
class _RLine {
  final String label;
  final String value;
  final bool bold;
  const _RLine(this.label, this.value, {this.bold = false});
}

/// Draws a horizontal dashed line (CustomPaint, so it never depends on a
/// LayoutBuilder).
class _DashPainter extends CustomPainter {
  const _DashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF9CA3AF)
      ..strokeWidth = 1.4;
    const dashWidth = 4.0;
    const gap = 3.0;
    double x = 0;
    while (x < size.width) {
      final end = (x + dashWidth) > size.width ? size.width : x + dashWidth;
      canvas.drawLine(Offset(x, 0.7), Offset(end, 0.7), paint);
      x += dashWidth + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Plain thermal-receipt style paper: centered store name, dashed
/// separators, label/value lines, a bold total and a short thank-you note.
/// It is always white with dark text (like a printed receipt), and matches
/// the receipt in the member portal's payment history.
class _ReceiptPaper extends StatelessWidget {
  final String title;
  final List<_RLine> details;
  final String itemName;
  final String itemAmount;
  final String totalLabel;
  final List<_RLine> summary;
  final String footerTitle;
  final String footerNote;

  const _ReceiptPaper({
    required this.title,
    required this.details,
    required this.itemName,
    required this.itemAmount,
    required this.totalLabel,
    required this.summary,
    required this.footerTitle,
    required this.footerNote,
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

  // CustomPaint-based dashed separator.
  Widget _dashes() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: SizedBox(
          height: 1.4,
          width: double.infinity,
          child: CustomPaint(painter: _DashPainter()),
        ),
      );

  Widget _line(_RLine l) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.label, style: _t(12, color: _soft)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              l.value,
              textAlign: TextAlign.right,
              style:
                  _t(12.5, weight: l.bold ? FontWeight.w700 : FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
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
          Text(title,
              textAlign: TextAlign.center,
              style: _t(12, weight: FontWeight.w700, spacing: 2)),
          _dashes(),

          // ---- who / when ----
          for (final l in details) _line(l),
          _dashes(),

          // ---- what it is for ----
          Row(
            children: [
              Text('DESCRIPTION',
                  style: _t(10.5,
                      weight: FontWeight.w700, color: _soft, spacing: 0.8)),
              const Spacer(),
              Text('AMOUNT',
                  style: _t(10.5,
                      weight: FontWeight.w700, color: _soft, spacing: 0.8)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child:
                      Text(itemName, style: _t(13, weight: FontWeight.w600))),
              const SizedBox(width: 12),
              Text(itemAmount, style: _t(13, weight: FontWeight.w600)),
            ],
          ),
          _dashes(),

          // ---- total ----
          Row(
            children: [
              Text(totalLabel, style: _t(14, weight: FontWeight.w800)),
              const Spacer(),
              Text(itemAmount, style: _t(18, weight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 10),
          for (final l in summary) _line(l),
          _dashes(),

          // ---- footer ----
          const SizedBox(height: 2),
          Text(footerTitle,
              textAlign: TextAlign.center,
              style: _t(12, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(footerNote,
              textAlign: TextAlign.center,
              style: _t(10.5, color: _soft, height: 1.45)),
        ],
      ),
    );
  }
}
