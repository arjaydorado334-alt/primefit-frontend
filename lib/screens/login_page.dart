import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Opens the Facebook / TikTok links and the phone dialer.
// Install with:  flutter pub add url_launcher
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../widgets/prime_fit_logo.dart';
import '../widgets/site_footer.dart';
import 'member_portal_screen.dart';
// 👇 Adjust this path if create_account.dart lives somewhere else
// (e.g. '../create_account.dart' if it's directly under lib/).
import 'create_account.dart';
// Reused so the footer's links can navigate to the landing page's own
// sections (LandingPage, LandingPageSection) -- this page isn't "on" the
// landing page, so it has no scroll position of its own to jump from.
import 'landing_page.dart';
import 'user_session.dart';
// 👇 Connects this screen to your PHP login API (login_api.php).
// Adjust the path if login_service.dart lives somewhere else.
import '../services/login_service.dart';

/// Typography for the Sign In page, kept consistent with the PrimeFit
/// landing page: Inter for labels, inputs, links and buttons.
class _AuthFonts {
  // Page heading ("Sign in to your account").
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

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
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
    setState(() {
      _errorText = null;
      if (_emailController.text.trim().isEmpty ||
          _passwordController.text.trim().isEmpty) {
        _errorText = 'Please enter both email and password.';
      }
    });
    if (_errorText != null) return;

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

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MemberPortalScreen()),
      );
    } else {
      setState(() => _errorText =
          result['message']?.toString() ?? 'Login failed. Please try again.');
    }
  }

  void _handleCreateAccount() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateAccountPage()),
    );
  }

  // Footer links: this page isn't "on" the landing page, so there's no
  // existing scroll position to jump from -- navigate there and land on
  // the requested section instead (see LandingPage's initialSection).
  // Clears the whole stack (pushAndRemoveUntil) rather than pushing on top,
  // so there's never a second LandingPage instance alive at once fighting
  // over the page's single shared ScrollController/GlobalKeys.
  void _goToLandingSection([LandingPageSection? section]) {
    goToLandingSection(context, section);
  }

  // ---------------- design tokens ----------------
  static const Color _pageBg = Color(0xFF0B0B0C);
  static const Color _cardBg = Color(0xFF15161A);
  static const Color _cardBorder = Color(0xFF262832);
  static const Color _fieldFill = Color(0xFF1E2025);
  static const Color _fieldBorder = Color(0xFF2C2F36);
  static const Color _mutedIcon = Color(0xFF7D838C);

  // PrimeFit contact info -- the same accounts the landing page uses.
  static const String _facebookUrl =
      'https://www.facebook.com/profile.php?id=61579305812618';
  static const String _tiktokUrl = 'https://www.tiktok.com/@primefit.fitness.g';
  static const String _phoneNumber = '+639178478351'; // used for the tel: link
  static const String _phoneDisplay = '+63 917 847 8351'; // shown on screen

  Future<void> _openLink(String url) async {
    final ok =
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Plain solid black page, same as the landing page.
      backgroundColor: _pageBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 520;
            // `k` (0.6 - 1.0) scales only the VERTICAL gaps to the window
            // height: on a normal screen it's 1.0 (full comfortable
            // spacing, everything visible at once); on short windows the
            // gaps tighten just enough so the card still fits without
            // scrolling. Fonts, fields and buttons keep their full size.
            final k = ((constraints.maxHeight - 150) / 740).clamp(0.6, 1.0);
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Keeps the card centered and fully visible on the first
                  // screen; the footer is reachable by scrolling just
                  // below it.
                  ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: compact ? 16 : 24,
                            vertical: 16 + 8 * k),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildCard(compact, k),
                              SizedBox(height: 14 + 6 * k),
                              _buildContactRow(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SiteFooter(
                    onLogoTap: () => _goToLandingSection(),
                    onAbout: () =>
                        _goToLandingSection(LandingPageSection.about),
                    onMission: () =>
                        _goToLandingSection(LandingPageSection.mission),
                    onMembership: () =>
                        _goToLandingSection(LandingPageSection.membership),
                    onMerchandise: () =>
                        _goToLandingSection(LandingPageSection.merchandise),
                    onContact: () =>
                        _goToLandingSection(LandingPageSection.contact),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ==================== SIGN-IN CARD ====================

  Widget _buildCard(bool compact, double k) {
    const logoSize = 66.0;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compact ? 22 : 52,
        24 + 16 * k,
        compact ? 22 : 52,
        22 + 14 * k,
      ),
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
      child: Form(
        key: _formKey,
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
            SizedBox(height: 8 + 4 * k),
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
            SizedBox(height: 14 + 16 * k),

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
            SizedBox(height: 16 + 12 * k),

            // ---- fields ----
            Text('Email address', style: _AuthFonts.label()),
            const SizedBox(height: 6),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.inter(fontSize: 15.5, color: Colors.white),
              cursorColor: AppColors.cyan,
              decoration: _inputDecoration(hint: 'you@email.com'),
            ),
            SizedBox(height: 10 + 8 * k),
            Text('Password', style: _AuthFonts.label()),
            const SizedBox(height: 6),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
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
                    onChanged: (v) => setState(() => _rememberMe = v ?? false),
                    activeColor: AppColors.cyan,
                    checkColor: Colors.black,
                    side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3), width: 1.5),
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
            SizedBox(height: 14 + 8 * k),

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
            SizedBox(height: 12 + 8 * k),

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
      ),
    );
  }

  // ==================== FACEBOOK / TIKTOK / PHONE ====================

  Widget _buildContactRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _contactButton(
          tooltip: 'Facebook',
          onTap: () => _openLink(_facebookUrl),
          child: Text('f',
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
        ),
        const SizedBox(width: 10),
        _contactButton(
          tooltip: 'TikTok',
          onTap: () => _openLink(_tiktokUrl),
          child: const Icon(Icons.music_note_rounded,
              size: 18, color: Colors.white),
        ),
        const SizedBox(width: 10),
        _contactButton(
          tooltip: 'Call us',
          onTap: () => _openLink('tel:$_phoneNumber'),
          child:
              const Icon(Icons.call_outlined, size: 17, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Text(_phoneDisplay,
            style: _AuthFonts.body(
                size: 13, color: const Color(0xFF9CA3AF), height: 1.2)),
      ],
    );
  }

  Widget _contactButton({
    required Widget child,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF17181C),
            border: Border.all(color: _cardBorder),
          ),
          child: child,
        ),
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
