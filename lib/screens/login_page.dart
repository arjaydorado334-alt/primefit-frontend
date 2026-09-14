import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

/// Shared typography for the Sign In / Create Account flow, kept
/// consistent with the PrimeFit landing page: Archivo Black for the
/// bold page heading, Inter for everything else (subtitle, labels,
/// inputs, links, buttons).
///
/// Defaults are light (white / off-white) because they render directly
/// on the dark-tinted glass card ([_GlassCell], using the shared
/// [AppGlass] recipe) -- text *inside* a white surface (the input
/// fields) always passes its own explicit dark color at the call site
/// and is unaffected.
class _AuthFonts {
  // Page heading — bold, confident, not oversized.
  static TextStyle heading({double size = 30, Color color = Colors.white}) =>
      GoogleFonts.archivoBlack(
        fontSize: size,
        color: color,
        height: 1.15,
        letterSpacing: -0.3,
      );

  // Subtitle under the heading.
  static TextStyle subtitle(
          {double size = 14.5, Color color = const Color(0xFFD6D8DC)}) =>
      GoogleFonts.inter(
          fontSize: size,
          color: color,
          height: 1.4,
          fontWeight: FontWeight.w400);

  // Form field labels.
  static TextStyle label({double size = 13, Color color = Colors.white}) =>
      GoogleFonts.inter(
          fontSize: size, fontWeight: FontWeight.w600, color: color);

  // Body / description text.
  static TextStyle body(
          {double size = 13.5,
          Color color = const Color(0xFFD6D8DC),
          double height = 1.5}) =>
      GoogleFonts.inter(
          fontSize: size,
          color: color,
          height: height,
          fontWeight: FontWeight.w400);

  // Links (Forgot password?, Create one, Sign in).
  static TextStyle link(
          {double size = 13.5,
          Color color = AppColors.cyan,
          FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.inter(fontSize: size, color: color, fontWeight: weight);

  // Primary button label — bold, uppercase.
  static TextStyle button({double size = 15, Color color = Colors.white}) =>
      GoogleFonts.inter(
          fontSize: size,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.6);
}

/// Translucent frosted-glass panel that floats the form over the
/// background photo. Uses the shared [AppGlass] recipe -- the same tint/
/// blur/border as the Create Account page's left panel -- so both auth
/// surfaces read as one consistent glass treatment.
class _GlassCell extends StatelessWidget {
  final Widget child;
  const _GlassCell({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: AppGlass.blur, sigmaY: AppGlass.blur),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: AppGlass.tint),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: Colors.white.withValues(alpha: AppGlass.borderOpacity)),
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

  @override
  Widget build(BuildContext context) {
    // A single size tier below which the card gets tighter padding/text so
    // it never feels cramped or overflows on a narrow phone viewport. The
    // enlarged card's maxWidth is only a ceiling either way, so this mainly
    // tunes internal spacing rather than preventing overflow by itself.
    final compact = MediaQuery.of(context).size.width < 420;
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
                Container(color: AppColors.darkBg),
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
            // LayoutBuilder gives the exact height available here (already
            // safe-area-adjusted), so the SizedBox below reproduces the
            // card's previous "fills the whole screen, centered" position
            // pixel-for-pixel -- the footer only becomes visible by
            // scrolling past that first full screen.
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        height: constraints.maxHeight,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 40),
                            child: ConstrainedBox(
                              // Larger card than before (was 560) -- this is
                              // only a ceiling, so a narrow phone viewport
                              // (screen width minus the 24px outer padding)
                              // still caps it well below this and never
                              // overflows/clips.
                              constraints: BoxConstraints(
                                  maxWidth: compact ? 480 : 680),
                              child: _GlassCell(
                                child: SingleChildScrollView(
                                  padding: compact
                                      ? const EdgeInsets.fromLTRB(
                                          28, 32, 28, 28)
                                      : const EdgeInsets.fromLTRB(
                                          56, 48, 56, 44),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          PrimeFitLogoMark(
                                              size: compact ? 40 : 48),
                                          const SizedBox(width: 12),
                                          PrimeFitWordmark(
                                              fontSize: compact ? 21 : 25),
                                        ],
                                      ),
                                      SizedBox(height: compact ? 30 : 40),
                                      _SignInForm(
                                        compact: compact,
                                        formKey: _formKey,
                                        emailController: _emailController,
                                        passwordController:
                                            _passwordController,
                                        obscurePassword: _obscurePassword,
                                        rememberMe: _rememberMe,
                                        errorText: _errorText,
                                        submitting: _submitting,
                                        onToggleObscure: () => setState(() =>
                                            _obscurePassword =
                                                !_obscurePassword),
                                        onToggleRemember: (v) => setState(
                                            () => _rememberMe = v ?? false),
                                        onSignIn: _handleSignIn,
                                        onBack: () =>
                                            Navigator.of(context).pop(),
                                        onCreateAccount: _handleCreateAccount,
                                      ),
                                    ],
                                  ),
                                ),
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
                        onMembership: () => _goToLandingSection(
                            LandingPageSection.membership),
                        onMerchandise: () => _goToLandingSection(
                            LandingPageSection.merchandise),
                        onContact: () =>
                            _goToLandingSection(LandingPageSection.contact),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SignInForm extends StatelessWidget {
  final bool compact;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool rememberMe;
  final String? errorText;
  final bool submitting;
  final VoidCallback onToggleObscure;
  final ValueChanged<bool?> onToggleRemember;
  final VoidCallback onSignIn;
  final VoidCallback onBack;
  final VoidCallback onCreateAccount;

  const _SignInForm({
    required this.compact,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.rememberMe,
    required this.errorText,
    required this.submitting,
    required this.onToggleObscure,
    required this.onToggleRemember,
    required this.onSignIn,
    required this.onBack,
    required this.onCreateAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome Back',
              style: _AuthFonts.heading(size: compact ? 28 : 34)),
          const SizedBox(height: 8),
          Text('Sign in to continue your fitness journey.',
              style: _AuthFonts.subtitle(size: compact ? 15 : 16)),
          SizedBox(height: compact ? 28 : 36),
          Text('Email address', style: _AuthFonts.label(size: 14)),
          const SizedBox(height: 10),
          TextField(
            controller: emailController,
            style: GoogleFonts.inter(fontSize: 15, color: Colors.black),
            cursorColor: AppColors.yellow,
            decoration: _inputDecoration('member@primefit.com'),
          ),
          SizedBox(height: compact ? 20 : 26),
          Row(
            children: [
              Text('Password', style: _AuthFonts.label(size: 14)),
              const Spacer(),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero, minimumSize: Size.zero),
                child: Text('Forgot password?',
                    style: _AuthFonts.link(size: 13.5, color: Colors.white)
                        .copyWith(decoration: TextDecoration.underline)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: passwordController,
            obscureText: obscurePassword,
            style: GoogleFonts.inter(fontSize: 15, color: Colors.black),
            cursorColor: AppColors.yellow,
            decoration: _inputDecoration('').copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                    obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20),
                onPressed: onToggleObscure,
              ),
            ),
          ),
          if (errorText != null) ...[
            const SizedBox(height: 10),
            Text(errorText!,
                style:
                    GoogleFonts.inter(color: Colors.redAccent, fontSize: 13)),
          ],
          SizedBox(height: compact ? 24 : 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: submitting ? null : onSignIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: compact ? 16 : 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text(submitting ? 'SIGNING IN…' : 'SIGN IN',
                  style: _AuthFonts.button(size: compact ? 15 : 16)),
            ),
          ),
          SizedBox(height: compact ? 22 : 28),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Don't have an account? ",
                    style: _AuthFonts.body(size: 14)),
                GestureDetector(
                  onTap: onCreateAccount,
                  behavior: HitTestBehavior.opaque,
                  child: Text('Create one',
                      style: _AuthFonts.link(size: 14, color: Colors.white)
                          .copyWith(decoration: TextDecoration.underline)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 15),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.92),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            BorderSide(color: Colors.black.withValues(alpha: 0.22), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            BorderSide(color: Colors.black.withValues(alpha: 0.22), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.yellow, width: 1.8),
      ),
    );
  }
}
