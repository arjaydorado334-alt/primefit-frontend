import 'dart:ui';
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

/// Shared typography for the Sign In / Create Account flow, kept
/// consistent with the PrimeFit landing page: Archivo Black for the
/// bold page heading, Inter for everything else (subtitle, labels,
/// inputs, links, buttons).
class _AuthFonts {
  // Page heading — bold, confident, not oversized.
  static TextStyle heading({double size = 30, Color color = Colors.black}) =>
      GoogleFonts.archivoBlack(
        fontSize: size,
        color: color,
        height: 1.15,
        letterSpacing: -0.3,
      );

  // Subtitle under the heading — kept black so it stays clearly
  // legible over the glass cell.
  static TextStyle subtitle({double size = 14.5, Color color = Colors.black}) =>
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
          {double size = 13.5,
          Color color = Colors.black,
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

/// Muted "← Back" link for the bottom-left corner of the auth card. Its
/// icon size (15), gap (5), Inter label (12.5), and grey
/// (`AppColors.textMutedOnLight` == 0xFF6B7280) are identical to the
/// `_backButton` helper on the Create Account steps, so the affordance is
/// the same on both entry screens and sits natively on the white card.
class _BackLink extends StatelessWidget {
  final VoidCallback onTap;
  const _BackLink({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.arrow_back,
              size: 15, color: AppColors.textMutedOnLight),
          const SizedBox(width: 5),
          Text('Back',
              style: GoogleFonts.inter(
                  color: AppColors.textMutedOnLight, fontSize: 12.5)),
        ],
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
                          const Row(
                            children: [
                              PrimeFitBadge(size: 34),
                              SizedBox(width: 10),
                              PrimeFitWordmark(fontSize: 19),
                            ],
                          ),
                          const SizedBox(height: 28),
                          _SignInForm(
                            formKey: _formKey,
                            emailController: _emailController,
                            passwordController: _passwordController,
                            obscurePassword: _obscurePassword,
                            rememberMe: _rememberMe,
                            errorText: _errorText,
                            submitting: _submitting,
                            onToggleObscure: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                            onToggleRemember: (v) =>
                                setState(() => _rememberMe = v ?? false),
                            onSignIn: _handleSignIn,
                            onBack: () => Navigator.of(context).pop(),
                            onCreateAccount: _handleCreateAccount,
                          ),
                          const SizedBox(height: 22),
                          // Back to the previous screen (the landing page, or
                          // wherever the user came from). Sits at the
                          // bottom-left inside the card; the Create Account
                          // form uses this exact control in the same spot.
                          _BackLink(onTap: () => Navigator.of(context).pop()),
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
}

class _SignInForm extends StatelessWidget {
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
          Text('Welcome Back', style: _AuthFonts.heading()),
          const SizedBox(height: 6),
          Text('Sign in to continue your fitness journey.',
              style: _AuthFonts.subtitle()),
          const SizedBox(height: 28),
          Text('Email address', style: _AuthFonts.label()),
          const SizedBox(height: 8),
          TextField(
            controller: emailController,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.black),
            cursorColor: AppColors.yellow,
            decoration: _inputDecoration('member@primefit.com'),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text('Password', style: _AuthFonts.label()),
              const Spacer(),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero, minimumSize: Size.zero),
                child: Text('Forgot password?',
                    style: _AuthFonts.link(size: 13, color: Colors.black)
                        .copyWith(decoration: TextDecoration.underline)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: passwordController,
            obscureText: obscurePassword,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.black),
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
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: submitting ? null : onSignIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text(submitting ? 'SIGNING IN…' : 'SIGN IN',
                  style: _AuthFonts.button()),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Don't have an account? ",
                    style: _AuthFonts.body(size: 13.5, color: Colors.black)),
                GestureDetector(
                  onTap: onCreateAccount,
                  behavior: HitTestBehavior.opaque,
                  child: Text('Create one',
                      style: _AuthFonts.link(color: Colors.black)
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
      hintStyle: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 14),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.92),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
