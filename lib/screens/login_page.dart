import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/prime_fit_logo.dart';
import 'member_portal_screen.dart';
// 👇 Adjust this path if create_account.dart lives somewhere else
// (e.g. '../create_account.dart' if it's directly under lib/).
import 'create_account.dart';
import 'user_session.dart';
// 👇 Connects this screen to your PHP login API (login_api.php).
// Adjust the path if login_service.dart lives somewhere else.
import '../services/login_service.dart';

/// Typography for the Sign In popup, kept consistent with the PrimeFit
/// landing page: Inter for labels, inputs, links and buttons.
class _AuthFonts {
  // Popup heading ("Sign in to your account").
  static TextStyle heading({double size = 27, Color color = Colors.white}) =>
      GoogleFonts.inter(
        fontSize: size,
        color: color,
        fontWeight: FontWeight.w800,
        height: 1.2,
        letterSpacing: -0.4,
      );

  // Body / description text.
  static TextStyle body(
          {double size = 14,
          Color color = const Color(0xFF9CA3AF),
          double height = 1.5}) =>
      GoogleFonts.inter(
          fontSize: size,
          color: color,
          height: height,
          fontWeight: FontWeight.w400);

  // Field labels.
  static TextStyle label({double size = 13}) => GoogleFonts.inter(
      fontSize: size,
      color: const Color(0xFFC4C8CE),
      fontWeight: FontWeight.w600);

  // Links.
  static TextStyle link(
          {double size = 13,
          Color color = AppColors.yellow,
          FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.inter(fontSize: size, color: color, fontWeight: weight);

  // Button label.
  static TextStyle button({double size = 15.5, Color color = Colors.black}) =>
      GoogleFonts.inter(
          fontSize: size,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.2);
}

/// Sign-in popup.
///
/// Open it from anywhere (landing page, navbar, etc.) with:
///
///     LoginPage.show(context);
///
/// It no longer navigates to a separate page -- it floats over whatever
/// page the user is currently on. On a successful login the popup closes
/// and the member portal opens.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  /// Shows the login popup over the current page.
  ///
  /// If the member taps "Sign Up" inside it, the popup closes and the
  /// Create Account popup opens in its place.
  static Future<void> show(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true, // tap outside the card to close
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (_) => const LoginPage(),
    );
    if (result == 'signup' && context.mounted) {
      await CreateAccountPage.show(context);
    }
  }

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _errorText;
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (_submitting) return;

    setState(() {
      _errorText = null;
      if (_emailController.text.trim().isEmpty ||
          _passwordController.text.trim().isEmpty) {
        _errorText = 'Please enter both email and password.';
      }
    });
    if (_errorText != null) return;

    // Grab the navigator now, before the async gap.
    final navigator = Navigator.of(context);

    setState(() => _submitting = true);

    final result = await LoginService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() => _submitting = false);

    if (result['success'] == true) {
      final member = result['member'] as Map<String, dynamic>;

      // Parse MemberSince ("YYYY-MM-DD" from MySQL) into a DateTime.
      DateTime memberSince;
      try {
        memberSince = DateTime.parse(member['member_since'].toString());
      } catch (_) {
        memberSince = DateTime.now();
      }

      // Parse the real NextRenewalDate from the Memberships table, if
      // the member has an active membership.
      DateTime? renewsOn;
      final renewalRaw = member['next_renewal_date'];
      if (renewalRaw != null) {
        try {
          renewsOn = DateTime.parse(renewalRaw.toString());
        } catch (_) {
          renewsOn = null;
        }
      }

      // Parse the plan price (e.g. "3500.00" from MySQL DECIMAL column).
      double? planPrice;
      if (member['plan_price'] != null) {
        planPrice = double.tryParse(member['plan_price'].toString());
      }

      final sessionCredits = int.tryParse('${member['session_credits']}') ?? 30;
      final sessionsUsedVal = int.tryParse('${member['sessions_used']}') ?? 0;

      // Save the logged-in member's info into the shared session so the
      // rest of the app (dashboard, profile, etc.) can read it -- same
      // mechanism CreateAccountPage uses right after signup.
      UserSession.instance.applySignup(
        firstName: member['first_name'] ?? '',
        lastName: member['last_name'] ?? '',
        email: member['email'] ?? '',
        phone: member['phone'] ?? '',
        membershipPlan: member['membership_plan'] ?? 'No active plan',
        membershipStatus: member['membership_status'] ?? 'Active',
        memberId: 'PF-${member['member_id'].toString().padLeft(5, '0')}',
        memberSince: memberSince,
        membershipRenewsOn: renewsOn,
        planPrice: planPrice,
        dbMemberId: member['member_id'] is int
            ? member['member_id'] as int
            : int.tryParse('${member['member_id']}'),
        creditsTotal: sessionCredits,
        sessionsUsed: sessionsUsedVal,
        qrCodeData: member['qr_code_data']?.toString() ??
            member['QRCodeData']?.toString() ??
            '',
        profilePictureUrl: member['profile_picture']?.toString() ??
            member['ProfilePictureURL']?.toString() ??
            '',
      );

      // Close the popup first, then open the member portal.
      navigator.pop();
      navigator.push(
        MaterialPageRoute(builder: (_) => const MemberPortalScreen()),
      );
    } else {
      setState(() => _errorText =
          result['message']?.toString() ?? 'Login failed. Please try again.');
    }
  }

  void _handleCreateAccount() {
    // Close this popup; LoginPage.show then opens the Create Account popup.
    Navigator.of(context).pop('signup');
  }

  void _close() {
    if (_submitting) return;
    Navigator.of(context).pop();
  }

  // ---------------- design tokens ----------------
  static const Color _cardBg = Color(0xFF15161A);
  static const Color _cardBorder = Color(0xFF262832);
  static const Color _fieldFill = Color(0xFF1E2025);
  static const Color _fieldBorder = Color(0xFF2C2F36);
  static const Color _mutedIcon = Color(0xFF7D838C);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width < 520;

    return PopScope(
      // Don't let Esc / back close the popup while a login is in flight.
      canPop: !_submitting,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 24,
          vertical: 24,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          // Scrolls on short windows so the card never overflows.
          child: Stack(
            children: [
              // Scrolls on short windows so the card never overflows.
              SingleChildScrollView(child: _buildCard(compact)),
              // Close (X) button -- fixed at the popup's top-right.
              Positioned(
                top: 6,
                right: 6,
                child: IconButton(
                  tooltip: 'Close',
                  onPressed: _close,
                  icon: const Icon(Icons.close_rounded,
                      size: 22, color: Color(0xFF9CA3AF)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== SIGN-IN CARD ====================

  Widget _buildCard(bool compact) {
    const logoSize = 66.0;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(compact ? 22 : 52, 36, compact ? 22 : 52, 30),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _cardBorder),
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
              // ---- brand header ----
              Center(
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/primefit_logo.jpg',
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) =>
                        PrimeFitLogoMark(size: logoSize),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Center(child: PrimeFitWordmark(fontSize: 24)),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'MEMBER PORTAL',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                    color: const Color(0xFFC9CDD3),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ---- heading ----
              Text('Sign in to your account',
                  textAlign: TextAlign.center,
                  style: _AuthFonts.heading(size: compact ? 24 : 28)),
              const SizedBox(height: 10),
              Text(
                'Welcome back! Enter your details to continue.',
                textAlign: TextAlign.center,
                style: _AuthFonts.body(size: compact ? 13.5 : 14.5),
              ),
              const SizedBox(height: 26),

              // ---- fields ----
              Text('Email address', style: _AuthFonts.label()),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                style: GoogleFonts.inter(fontSize: 15.5, color: Colors.white),
                cursorColor: AppColors.cyan,
                decoration: _inputDecoration(hint: 'you@email.com'),
              ),
              const SizedBox(height: 18),
              Text('Password', style: _AuthFonts.label()),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _handleSignIn(), // Enter key signs in
                style: GoogleFonts.inter(fontSize: 15.5, color: Colors.white),
                cursorColor: AppColors.cyan,
                decoration:
                    _inputDecoration(hint: 'Enter your password').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 19,
                        color: _mutedIcon),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ---- keep me logged in / forgot password ----
              Row(
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: _rememberMe,
                      onChanged: (v) =>
                          setState(() => _rememberMe = v ?? false),
                      activeColor: AppColors.cyan,
                      checkColor: Colors.black,
                      side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Flexible(
                    child: Text('Keep me logged in',
                        style: _AuthFonts.body(
                            size: 13, color: const Color(0xFFA7ADB5))),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero, minimumSize: Size.zero),
                    child: Text('Forgot password?', style: _AuthFonts.link()),
                  ),
                ],
              ),

              if (_errorText != null) ...[
                const SizedBox(height: 10),
                Text(_errorText!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        color: Colors.redAccent, fontSize: 13)),
              ],
              const SizedBox(height: 22),

              // ---- sign in ----
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _handleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.yellow,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor:
                        AppColors.yellow.withValues(alpha: 0.5),
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(_submitting ? 'Signing in…' : 'Sign In',
                      style: _AuthFonts.button()),
                ),
              ),
              const SizedBox(height: 20),

              // ---- sign up ----
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ",
                      style: _AuthFonts.body(
                          size: 13.5, color: const Color(0xFFA7ADB5))),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: _handleCreateAccount,
                      behavior: HitTestBehavior.opaque,
                      child: Text('Sign Up',
                          style: _AuthFonts.link(
                              size: 13.5,
                              color: AppColors.cyan,
                              weight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
    );
  }

  // Dark filled input with the label above it (see _AuthFonts.label).
  InputDecoration _inputDecoration({required String hint}) {
    OutlineInputBorder border(Color c, [double w = 1.2]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle:
          GoogleFonts.inter(fontSize: 15.5, color: const Color(0xFF6F7681)),
      filled: true,
      fillColor: _fieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: border(_fieldBorder),
      enabledBorder: border(_fieldBorder),
      focusedBorder: border(AppColors.cyan, 1.6),
    );
  }
}