import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
// ignore: unused_import
import '../theme/app_theme.dart';
import '../widgets/prime_fit_logo.dart';
import 'login_page.dart';
import 'create_account.dart';

class _Palette {
  static const bgNearBlack = Color(0xFF050505);
  static const bgDeepBlack = Color(0xFF080808);
  static const bgDarkSection = Color(0xFF111111);
  static const bgDarkGraySection = Color(0xFF17171B);
  static const bgCard = Color(0xFF18181B);

  static const yellow = Color(0xFFFFC400);
  // ignore: unused_field
  static const yellowBright = Color(0xFFFFD000);

  static const cyan = Color(0xFF00B8D9);
  // ignore: unused_field
  static const cyanBright = Color(0xFF00C6E8);

  static const white = Color(0xFFFFFFFF);
  static const offWhite = Color(0xFFF5F5F5);
  static const lightGray = Color(0xFFA7A7A7);
  static const mutedGray = Color(0xFF737373);

  static const cardBorder = Color(0xFF262629);

  static const yellowCyanGradient = LinearGradient(
    colors: [cyan, yellow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Centralized typography — Archivo Black for big display headings,
/// Inter for everything else (labels, body, nav, buttons).
class _Fonts {
  // Big display headings (hero titles, section headings, big numbers/prices)
  static TextStyle display({
    required double size,
    Color color = _Palette.white,
    double height = 1.05,
  }) =>
      GoogleFonts.archivoBlack(
        fontSize: size,
        color: color,
        height: height,
        letterSpacing: -0.5,
      );

  // Section labels — "ABOUT US", "FIND US", etc.
  static TextStyle sectionLabel({Color color = _Palette.cyan}) =>
      GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 3.5,
      );

  // Body copy
  static TextStyle body({
    double size = 15,
    Color color = _Palette.lightGray,
    double height = 1.6,
    FontWeight weight = FontWeight.w400,
  }) =>
      GoogleFonts.inter(
          fontSize: size, color: color, height: height, fontWeight: weight);

  // Nav links
  static TextStyle nav({required Color color}) => GoogleFonts.inter(
      fontSize: 15, fontWeight: FontWeight.w500, color: color);

  // Buttons — bold/extrabold, uppercase
  static TextStyle button({double size = 14.5, Color color = Colors.black}) =>
      GoogleFonts.inter(
          fontSize: size,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5);

  // Card / smaller headings (feature titles, plan names, item names)
  static TextStyle heading({
    required double size,
    Color color = _Palette.white,
    FontWeight weight = FontWeight.w800,
  }) =>
      GoogleFonts.inter(
          fontSize: size, fontWeight: weight, color: color, letterSpacing: 0.4);
}

    const double _kNavBarHeight = 84;

    /// Responsive breakpoints used throughout the landing page:
    /// mobile < 600, tablet 600-1024, desktop >= 1024.
    const double _kMobileMaxWidth = 600;
    const double _kTabletMaxWidth = 1024;

    enum _Breakpoint { mobile, tablet, desktop }

    _Breakpoint _breakpointOf(BuildContext context) {
      final w = MediaQuery.of(context).size.width;
      if (w < _kMobileMaxWidth) return _Breakpoint.mobile;
      if (w < _kTabletMaxWidth) return _Breakpoint.tablet;
      return _Breakpoint.desktop;
    }

    /// Shared padding for the big content sections (About, Mission, Pricing,
    /// Location, Merch, Contact) so they scale together per breakpoint.
    EdgeInsets _sectionPadding(BuildContext context) {
      switch (_breakpointOf(context)) {
        case _Breakpoint.mobile:
          return const EdgeInsets.symmetric(horizontal: 16, vertical: 56);
        case _Breakpoint.tablet:
          return const EdgeInsets.symmetric(horizontal: 24, vertical: 72);
        case _Breakpoint.desktop:
          return const EdgeInsets.symmetric(horizontal: 24, vertical: 90);
      }
    }

    const String _primeFitAddress =
        '31 Bernardo St, near Army Road, Central Signal, Taguig, Metro Manila, Philippines 1633';

    // Approximate coordinates for Central Signal, Taguig (not precisely
    // geocoded for 31 Bernardo St specifically) -- replace with the exact
    // lat/lng if/when you have it geocoded.
    const LatLng _primeFitLatLng = LatLng(14.5175, 121.0472);

    // Footer copyright year -- update this each January rather than computing
    // it from DateTime.now(), so the footer doesn't silently roll over mid-way
    // through a deploy or depend on the visitor's device clock.
    const int _kFooterCopyrightYear = 2026;

    final GlobalKey _aboutKey = GlobalKey();
    final GlobalKey _missionKey = GlobalKey();
    final GlobalKey _pricingKey = GlobalKey();
    final GlobalKey _merchKey = GlobalKey();
    final GlobalKey _contactKey = GlobalKey();

    Future<void> _launchUri(Uri uri) async {
      try {
        await launchUrl(uri);
      } catch (_) {}
    }

    class LandingPage extends StatelessWidget {
      const LandingPage({super.key});

      void _goToLogin(BuildContext context) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }

      void _goToCreateAccount(BuildContext context) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateAccountPage()),
        );
      }

      void _scrollToAbout(BuildContext context) {
        final ctx = _aboutKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(ctx,
              duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
        }
      }

      void _scrollToMission(BuildContext context) {
        final ctx = _missionKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(ctx,
              duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
        }
      }

      void _scrollToMembership(BuildContext context) {
        final ctx = _pricingKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(ctx,
              duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
        }
      }

      void _scrollToMerch(BuildContext context) {
        final ctx = _merchKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(ctx,
              duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
        }
      }

      void _scrollToContact(BuildContext context) {
        final ctx = _contactKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(ctx,
              duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
        }
      }

      @override
      Widget build(BuildContext context) {
        // NavBar is kept OUTSIDE the scroll view (fixed at the top, always
        // visible) while everything else scrolls beneath it in the Expanded
        // SingleChildScrollView below -- this is what makes the nav "sticky."
        return Scaffold(
          backgroundColor: _Palette.bgNearBlack,
          endDrawer: _MobileNavDrawer(
            onSignIn: () => _goToLogin(context),
            onJoin: () => _goToCreateAccount(context),
            onAbout: () => _scrollToAbout(context),
            onMission: () => _scrollToMission(context),
            onMembership: () => _scrollToMembership(context),
            onMerchandise: () => _scrollToMerch(context),
            onContact: () => _scrollToContact(context),
          ),
          body: Column(
            children: [
              _NavBar(
                onSignIn: () => _goToLogin(context),
                onJoin: () => _goToCreateAccount(context),
                onAbout: () => _scrollToAbout(context),
                onMission: () => _scrollToMission(context),
                onMembership: () => _scrollToMembership(context),
                onMerchandise: () => _scrollToMerch(context),
                onContact: () => _scrollToContact(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _HeroSection(
                          onGetStarted: () => _goToLogin(context),
                          onViewPlans: () => _scrollToMembership(context)),
                      const _StatsBar(),
                      const _FeaturesStrip(),
                      _AboutSection(key: _aboutKey),
                      _MissionSection(key: _missionKey),
                      _PricingSection(
                          key: _pricingKey,
                          onGetStarted: () => _goToCreateAccount(context)),
                      const _LocationSection(),
                      _MerchSection(key: _merchKey),
                      _ContactSection(key: _contactKey),
                      _Footer(
                        onAbout: () => _scrollToAbout(context),
                        onMission: () => _scrollToMission(context),
                        onMembership: () => _scrollToMembership(context),
                        onMerchandise: () => _scrollToMerch(context),
                        onContact: () => _scrollToContact(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }

    class _HoverScale extends StatefulWidget {
      final Widget child;
      final double endScale;
      const _HoverScale({required this.child, this.endScale = 1.03});

      @override
      State<_HoverScale> createState() => _HoverScaleState();
    }

    class _HoverScaleState extends State<_HoverScale> {
      bool _hovered = false;

      @override
      Widget build(BuildContext context) {
        return MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedScale(
            scale: _hovered ? widget.endScale : 1.0,
            duration: const Duration(milliseconds: 200),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                boxShadow: _hovered
                    ? [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 4))
                      ]
                    : const [
                        BoxShadow(
                            color: Colors.transparent,
                            blurRadius: 0,
                            offset: Offset.zero)
                      ],
              ),
              child: widget.child,
            ),
          ),
        );
      }
    }

    /// ---------------------------------------------------------------------
    /// NAV BAR (fixed/sticky — nav links kept close to the action buttons)
    /// ---------------------------------------------------------------------
    class _NavBar extends StatelessWidget {
      final VoidCallback onSignIn;
      final VoidCallback onJoin;
      final VoidCallback onAbout;
      final VoidCallback onMission;
      final VoidCallback onMembership;
      final VoidCallback onMerchandise;
      final VoidCallback onContact;
      const _NavBar({
        required this.onSignIn,
        required this.onJoin,
        required this.onAbout,
        required this.onMission,
        required this.onMembership,
        required this.onMerchandise,
        required this.onContact,
      });

      @override
      Widget build(BuildContext context) {
        final bp = _breakpointOf(context);
        final isWide = bp == _Breakpoint.desktop;
        final horizontalPadding = switch (bp) {
          _Breakpoint.mobile => 16.0,
          _Breakpoint.tablet => 32.0,
          _Breakpoint.desktop => 72.0,
        };
        return Container(
          height: _kNavBarHeight,
          // Extra horizontal breathing room so the logo and the Sign In /
          // Join Now buttons aren't hugging the very edge of the screen.
          padding: EdgeInsets.only(left: horizontalPadding, right: horizontalPadding),
          decoration: const BoxDecoration(
            color: _Palette.bgDeepBlack,
            border:
                Border(bottom: BorderSide(color: _Palette.cardBorder, width: 1)),
          ),
          child: Row(
            children: [
              // Logo + wordmark (left)
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ClipOval(
                      child: Image.asset(
                        'assets/images/primefit_logo.jpg',
                        width: 38,
                        height: 38,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 9),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                        children: [
                          TextSpan(
                              text: 'Prime',
                              style: TextStyle(color: _Palette.cyan)),
                          TextSpan(
                              text: 'Fit',
                              style: TextStyle(color: _Palette.yellow)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Nav links — aligned toward the right (near Sign In / Join Now)
              // instead of dead-center, so they don't sit far away from the
              // action buttons.
              if (isWide)
                Expanded(
                  flex: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _NavLink('About', onTap: onAbout),
                      _NavLink('Mission', onTap: onMission),
                      _NavLink('Membership', onTap: onMembership),
                      _NavLink('Merchandise', onTap: onMerchandise),
                      _NavLink('Contact', onTap: onContact),
                      const SizedBox(width: 28),
                    ],
                  ),
                ),
              // Sign In + Join Now (right) on desktop; hamburger menu (which
              // holds the nav links + Sign In) + Join Now on phone/tablet.
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isWide) ...[
                    TextButton(
                      onPressed: onSignIn,
                      style: TextButton.styleFrom(
                          foregroundColor: _Palette.lightGray),
                      child: Text('SIGN IN',
                          style: _Fonts.button(color: _Palette.lightGray)),
                    ),
                    const SizedBox(width: 10),
                  ],
                  ElevatedButton(
                    onPressed: onJoin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _Palette.yellow,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(
                          horizontal: isWide ? 20 : 14, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: Text('JOIN NOW', style: _Fonts.button(size: 14)),
                  ),
                  if (!isWide) ...[
                    const SizedBox(width: 6),
                    Builder(
                      builder: (context) => IconButton(
                        onPressed: () => Scaffold.of(context).openEndDrawer(),
                        icon: const Icon(Icons.menu, color: Colors.white),
                        tooltip: 'Menu',
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ).animate().fade(duration: 400.ms);
      }
    }

    /// Nav-links + Sign In, shown as a right-side drawer on phone/tablet
    /// (opened via the navbar's hamburger icon) since the navbar itself is
    /// too narrow to show them inline below desktop width.
    class _MobileNavDrawer extends StatelessWidget {
      final VoidCallback onSignIn;
      final VoidCallback onJoin;
      final VoidCallback onAbout;
      final VoidCallback onMission;
      final VoidCallback onMembership;
      final VoidCallback onMerchandise;
      final VoidCallback onContact;
      const _MobileNavDrawer({
        required this.onSignIn,
        required this.onJoin,
        required this.onAbout,
        required this.onMission,
        required this.onMembership,
        required this.onMerchandise,
        required this.onContact,
      });

      @override
      Widget build(BuildContext context) {
        void closeThen(VoidCallback action) {
          Navigator.of(context).pop();
          action();
        }

        Widget link(String label, VoidCallback onTap) => ListTile(
              title: Text(label, style: _Fonts.nav(color: Colors.white)),
              onTap: () => closeThen(onTap),
            );

        return Drawer(
          backgroundColor: _Palette.bgDeepBlack,
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      ClipOval(
                        child: Image.asset(
                          'assets/images/primefit_logo.jpg',
                          width: 34,
                          height: 34,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 9),
                      RichText(
                        text: const TextSpan(
                          style:
                              TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          children: [
                            TextSpan(
                                text: 'Prime',
                                style: TextStyle(color: _Palette.cyan)),
                            TextSpan(
                                text: 'Fit',
                                style: TextStyle(color: _Palette.yellow)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: _Palette.cardBorder),
                link('About', onAbout),
                link('Mission', onMission),
                link('Membership', onMembership),
                link('Merchandise', onMerchandise),
                link('Contact', onContact),
                const Divider(color: _Palette.cardBorder),
                link('Sign In', onSignIn),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => closeThen(onJoin),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _Palette.yellow,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: Text('JOIN NOW', style: _Fonts.button(size: 14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    class _NavLink extends StatefulWidget {
      final String label;
      final VoidCallback? onTap;
      const _NavLink(this.label, {this.onTap});

      @override
      State<_NavLink> createState() => _NavLinkState();
    }

    class _NavLinkState extends State<_NavLink> {
      bool _hovered = false;

      @override
      Widget build(BuildContext context) {
        return MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 150),
                  style: _Fonts.nav(
                      color: _hovered ? _Palette.white : _Palette.lightGray),
                  child: Text(widget.label),
                ),
              ),
            ),
          ),
        );
      }
    }

    /// ---------------------------------------------------------------------
    /// HERO (left-anchored text column, gradient headline, bigger intro copy)
    /// ---------------------------------------------------------------------
    class _HeroSection extends StatelessWidget {
      final VoidCallback onGetStarted;
      final VoidCallback onViewPlans;
      const _HeroSection({required this.onGetStarted, required this.onViewPlans});

      @override
      Widget build(BuildContext context) {
        final bp = _breakpointOf(context);
        // Big display text and padding scale down per breakpoint so "FIT FOR" /
        // "ALL." don't force awkward wrapping or overflow on narrow screens.
        final displaySize = switch (bp) {
          _Breakpoint.mobile => 44.0,
          _Breakpoint.tablet => 64.0,
          _Breakpoint.desktop => 90.0,
        };
        final subheadSize = switch (bp) {
          _Breakpoint.mobile => 24.0,
          _Breakpoint.tablet => 30.0,
          _Breakpoint.desktop => 38.0,
        };
        final bodySize = switch (bp) {
          _Breakpoint.mobile => 15.0,
          _Breakpoint.tablet => 17.0,
          _Breakpoint.desktop => 20.0,
        };
        final buttonPadding = switch (bp) {
          _Breakpoint.mobile => const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          _Breakpoint.tablet ||
          _Breakpoint.desktop =>
            const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        };
        final heroPadding = switch (bp) {
          _Breakpoint.mobile =>
            const EdgeInsets.only(left: 20, right: 20, top: 32, bottom: 32),
          _Breakpoint.tablet =>
            const EdgeInsets.only(left: 40, right: 24, top: 40, bottom: 40),
          _Breakpoint.desktop =>
            const EdgeInsets.only(left: 72, right: 24, top: 40, bottom: 40),
        };

        final textColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: _Palette.cyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _Palette.cyan.withValues(alpha: 0.4)),
              ),
              child: Text('TAGUIG CITY, PHILIPPINES',
                  style: _Fonts.sectionLabel().copyWith(fontSize: 14)),
            ).animate().fade(delay: 200.ms).slideX(begin: -0.5),
            const SizedBox(height: 22),
            // "FIT FOR" / "ALL." now render with the cyan→yellow gradient
            // instead of flat white.
            ShaderMask(
              shaderCallback: (bounds) =>
                  _Palette.yellowCyanGradient.createShader(bounds),
              blendMode: BlendMode.srcIn,
              child: Text('FIT FOR', style: _Fonts.display(size: displaySize)),
            ).animate().fade(delay: 300.ms).slideX(begin: -0.5),
            ShaderMask(
              shaderCallback: (bounds) =>
                  _Palette.yellowCyanGradient.createShader(bounds),
              blendMode: BlendMode.srcIn,
              child: Text('ALL.', style: _Fonts.display(size: displaySize)),
            ).animate().fade(delay: 350.ms).slideX(begin: -0.5),
            const SizedBox(height: 6),
            Text('WHERE YOUR FITNESS',
                    style: _Fonts.display(
                        size: subheadSize, color: _Palette.cyan, height: 1.15))
                .animate()
                .fade(delay: 420.ms)
                .slideX(begin: -0.4),
            Text('JOURNEY BEGINS.',
                    style: _Fonts.display(
                        size: subheadSize, color: _Palette.yellow, height: 1.15))
                .animate()
                .fade(delay: 480.ms)
                .slideX(begin: -0.4),
            const SizedBox(height: 22),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Text(
                'PrimeFit Fitness Gym is your complete training destination — '
                'equipped, supportive, and built for every level of athlete.',
                style: _Fonts.body(size: bodySize, height: 1.6),
              ),
            ).animate().fade(delay: 540.ms).slideX(begin: -0.3),
            const SizedBox(height: 28),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _HoverScale(
                  endScale: 1.03,
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: onGetStarted,
                      borderRadius: BorderRadius.circular(10),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: _Palette.yellow,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                                color: _Palette.yellow.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8)),
                          ],
                        ),
                        child: Container(
                          padding: buttonPadding,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('GET STARTED', style: _Fonts.button(size: 16)),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward,
                                  size: 20, color: Colors.black),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _HoverScale(
                  endScale: 1.03,
                  child: OutlinedButton(
                    onPressed: onViewPlans,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF3A3A3D)),
                      padding: buttonPadding,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('VIEW PLANS',
                        style: _Fonts.button(size: 16, color: Colors.white)),
                  ),
                ),
              ],
            ).animate().fade(delay: 600.ms).slideY(begin: 0.4),
          ],
        );

        final screenHeight = MediaQuery.of(context).size.height;

        return Container(
          width: double.infinity,
          // Fixed height (not just a min) — a Stack with StackFit.expand
          // needs a bounded height from its parent, and this Container sits
          // inside a scroll view where height would otherwise be unbounded.
          // That mismatch was what caused the blank screen / "render box
          // has never been laid out" crash. The extra "+140" that used to be
          // here made the section taller than the actual viewport, which is
          // why the text looked pushed toward the bottom on first load. A
          // floor is applied on mobile/tablet so short landscape/small
          // viewports still have room for the (smaller, but still multi-line)
          // hero text without clipping.
          height: (screenHeight - _kNavBarHeight)
              .clamp(bp == _Breakpoint.desktop ? 0 : 560, double.infinity),
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(color: _Palette.bgNearBlack),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background gym photo. If this ever fails to load (e.g. the
              // asset isn't declared in pubspec.yaml yet), fall back to a
              // plain dark background instead of crashing the page.
              Image.asset(
                'assets/images/hero_bg.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: _Palette.bgDarkSection),
              ),
              // Dark scrim: solid/near-black on the left (where the text
              // sits) fading toward mostly-transparent on the right, so the
              // photo shows through more on that side.
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      _Palette.bgNearBlack,
                      Color(0xE6050505),
                      Color(0x99050505),
                      Color(0x33050505),
                    ],
                    stops: [0.0, 0.35, 0.65, 1.0],
                  ),
                ),
              ),
              // Subtle top/bottom darken too, so the text stays readable
              // near the edges of the photo.
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x66050505),
                      Colors.transparent,
                      Color(0x66050505)
                    ],
                    stops: [0.0, 0.4, 1.0],
                  ),
                ),
              ),
              Padding(
                padding: heroPadding,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: textColumn,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }

    /// ---------------------------------------------------------------------
    /// STATS BAR
    /// ---------------------------------------------------------------------
    class _StatsBar extends StatelessWidget {
      const _StatsBar();

      @override
      Widget build(BuildContext context) {
        const stats = [
          ['50+', 'ACTIVE MEMBERS'],
          ['1+', 'YEARS OPERATING'],
          ['20+', 'EQUIPMENT TYPES'],
          ['7AM–10PM', 'DAILY HOURS'],
        ];
        return Container(
          width: double.infinity,
          color: _Palette.bgDeepBlack,
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Wrap(
            alignment: WrapAlignment.spaceEvenly,
            spacing: 24,
            runSpacing: 20,
            children: stats
                .map((s) => SizedBox(
                      width: 170,
                      child: Column(
                        children: [
                          Text(s[0], style: _Fonts.display(size: 28)),
                          const SizedBox(height: 4),
                          Text(s[1],
                              style: _Fonts.sectionLabel(color: _Palette.mutedGray)
                                  .copyWith(fontSize: 11.5)),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ).animate().fade(duration: 500.ms).slideY(begin: 0.2);
      }
    }

    /// ---------------------------------------------------------------------
    /// FEATURES / WHY PRIMEFIT
    /// ---------------------------------------------------------------------
    class _FeaturesStrip extends StatelessWidget {
      const _FeaturesStrip();

      @override
      Widget build(BuildContext context) {
        const features = [
          [
            Icons.fitness_center_outlined,
            'MODERN EQUIPMENT',
            'Full range of machines, free weights, and cardio equipment.',
            _Palette.cyan
          ],
          [
            Icons.badge_outlined,
            'EXPERT STAFF',
            'Certified and experienced trainers to guide members.',
            _Palette.yellow
          ],
          [
            Icons.track_changes_outlined,
            'PERSONALIZED PLANS',
            'Workout programs and plans tailored to member goals.',
            _Palette.cyan
          ],
          [
            Icons.groups_outlined,
            'SUPPORTIVE COMMUNITY',
            'A positive and inclusive environment that keeps members motivated.',
            _Palette.yellow
          ],
        ];

        return Container(
          width: double.infinity,
          color: _Palette.bgNearBlack,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
          child: Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: features.map((f) {
              final icon = f[0] as IconData;
              final title = f[1] as String;
              final desc = f[2] as String;
              final accent = f[3] as Color;
              return _HoverScale(
                endScale: 1.02,
                child: Container(
                  width: 250,
                  // Fixed height (not just width) so all four cards line up
                  // evenly — before this, "SUPPORTIVE COMMUNITY" wrapped to
                  // 3 lines while the others only needed 1-2, making the
                  // cards different heights.
                  height: 210,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: _Palette.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _Palette.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: accent.withValues(alpha: 0.5)),
                        ),
                        alignment: Alignment.center,
                        child: Icon(icon, color: accent, size: 22),
                      ),
                      const SizedBox(height: 16),
                      Text(title, style: _Fonts.heading(size: 14.5)),
                      const SizedBox(height: 8),
                      Text(desc,
                          style: _Fonts.body(
                              size: 13, height: 1.45, color: _Palette.mutedGray)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ).animate().fade(duration: 500.ms).slideY(begin: 0.2);
      }
    }

    /// ---------------------------------------------------------------------
    /// ABOUT US
    /// ---------------------------------------------------------------------
    class _AboutSection extends StatelessWidget {
      const _AboutSection({super.key});

      @override
      Widget build(BuildContext context) {
        final isWide = _breakpointOf(context) == _Breakpoint.desktop;

        final visual = Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 340,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _Palette.cardBorder),
                ),
                child: Image.asset(
                  'assets/images/about_gym.jpg',
                  fit: BoxFit.cover,
                  // Falls back to the old placeholder look if the asset is
                  // missing/misnamed, instead of crashing the page.
                  errorBuilder: (context, error, stackTrace) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_Palette.bgDarkGraySection, _Palette.bgDeepBlack],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.fitness_center,
                        size: 90, color: _Palette.cyan.withValues(alpha: 0.35)),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -18,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: _Palette.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _Palette.cardBorder),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('1+ YEARS',
                        style: _Fonts.display(size: 20, color: _Palette.yellow)),
                    Text('SERVING TAGUIG CITY',
                        style: _Fonts.sectionLabel(color: _Palette.mutedGray)
                            .copyWith(fontSize: 11)),
                  ],
                ),
              ),
            ),
          ],
        );

        final right = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ABOUT US', style: _Fonts.sectionLabel()),
            const SizedBox(height: 14),
            RichText(
              text: TextSpan(
                style: _Fonts.display(size: 32, height: 1.2),
                children: [
                  const TextSpan(text: 'MORE THAN\nA GYM — A '),
                  TextSpan(
                      text: 'COMMUNITY.',
                      style: _Fonts.display(
                          size: 32, height: 1.2, color: _Palette.yellow)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '"Healthy Mind, Healthy Body"',
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  color: _Palette.lightGray),
            ),
            const SizedBox(height: 18),
            Text(
              'PrimeFit Fitness Gym is a gym and physical fitness center dedicated to '
              'helping individuals achieve a healthier mind and body. We provide a '
              'welcoming environment where members can work toward their fitness '
              'goals, improve their physical well-being, and develop a healthier '
              'lifestyle.',
              style: _Fonts.body(size: 15.5),
            ),
            const SizedBox(height: 18),
            ..._checks([
              'Open to all fitness levels — no judgment',
              'Clean, well-maintained equipment',
              'Dedicated training floor with free weights & cardio',
              'Friendly, experienced staff on-site daily',
            ]),
          ],
        );

        final rowContent = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: visual),
            const SizedBox(width: 50),
            Expanded(child: right),
          ],
        );

        final columnContent = Column(
          children: [visual, const SizedBox(height: 40), right],
        );

        return Container(
          width: double.infinity,
          color: _Palette.bgDarkSection,
          padding: _sectionPadding(context),
          child: isWide
              ? rowContent
              : columnContent.animate().fade(duration: 500.ms).slideY(begin: 0.2),
        );
      }

      List<Widget> _checks(List<String> items) {
        return items
            .map((t) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle,
                          color: _Palette.yellow, size: 19),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(t,
                              style:
                                  _Fonts.body(size: 15, color: _Palette.offWhite))),
                    ],
                  ),
                ))
            .toList();
      }
    }

    /// ---------------------------------------------------------------------
    /// MISSION & VISION
    /// ---------------------------------------------------------------------
    class _MissionSection extends StatelessWidget {
      const _MissionSection({super.key});

      @override
      Widget build(BuildContext context) {
        final isWide = _breakpointOf(context) == _Breakpoint.desktop;

        const missionCard = _MissionCard(
          accent: _Palette.cyan,
          icon: Icons.adjust,
          title: 'OUR MISSION',
          body: 'To provide an accessible, inclusive, and results-driven fitness '
              'environment where every member — regardless of age, experience, or '
              'fitness level — feels empowered to pursue their health goals.',
          sub: 'We are committed to offering top-quality equipment, knowledgeable '
              'staff, and an affordable membership structure that makes fitness '
              'achievable for all.',
        );

        const visionCard = _MissionCard(
          accent: _Palette.yellow,
          icon: Icons.star,
          title: 'OUR VISION',
          body: 'To become the leading fitness community in Taguig City — a place '
              'known not just for physical transformation, but for the sense of '
              'belonging and motivation it creates in every person who walks '
              'through our doors.',
          sub: 'We envision a future where everyone in our community has the '
              'tools, support, and knowledge to live a strong, healthy, and '
              'active life.',
        );

        const values = [
          ['INCLUSIVITY', 'Every body is welcome'],
          ['DEDICATION', 'We show up every day'],
          ['INTEGRITY', 'Honest, transparent service'],
          ['PROGRESS', 'Always improving'],
        ];

        return Container(
          width: double.infinity,
          color: _Palette.bgDarkGraySection,
          padding: _sectionPadding(context),
          child: Column(
            children: [
              Text('WHO WE ARE', style: _Fonts.sectionLabel()),
              const SizedBox(height: 14),
              Text('MISSION & VISION', style: _Fonts.display(size: 34)),
              const SizedBox(height: 44),
              isWide
                  ? const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: missionCard),
                        SizedBox(width: 24),
                        Expanded(child: visionCard),
                      ],
                    )
                  : const Column(
                      children: [missionCard, SizedBox(height: 24), visionCard]),
              const SizedBox(height: 30),
              Wrap(
                spacing: 18,
                runSpacing: 18,
                alignment: WrapAlignment.center,
                children: values
                    .map((v) => _HoverScale(
                          endScale: 1.03,
                          child: SizedBox(
                            // Fixed width (not just a minimum) so all four
                            // chips match, instead of each one hugging its
                            // own label length.
                            width: 190,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 20, horizontal: 18),
                              decoration: BoxDecoration(
                                color: _Palette.bgCard,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _Palette.cardBorder),
                              ),
                              child: Column(
                                children: [
                                  Text(v[0], style: _Fonts.heading(size: 15)),
                                  const SizedBox(height: 6),
                                  Text(v[1],
                                      style: _Fonts.body(
                                          size: 12.5, color: _Palette.mutedGray)),
                                ],
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ).animate().fade(duration: 500.ms).slideY(begin: 0.2);
      }
    }

    class _MissionCard extends StatelessWidget {
      final Color accent;
      final IconData icon;
      final String title;
      final String body;
      final String sub;

      const _MissionCard({
        required this.accent,
        required this.icon,
        required this.title,
        required this.body,
        required this.sub,
      });

      @override
      Widget build(BuildContext context) {
        return _HoverScale(
          endScale: 1.015,
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: _Palette.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.center,
                  child: Icon(icon, color: accent, size: 23),
                ),
                const SizedBox(height: 20),
                Text(title, style: _Fonts.display(size: 22)),
                const SizedBox(height: 14),
                Text(body,
                    style: _Fonts.body(
                        size: 15, height: 1.55, color: _Palette.offWhite)),
                const SizedBox(height: 10),
                Text(sub,
                    style: _Fonts.body(
                        size: 13.5, height: 1.55, color: _Palette.mutedGray)),
              ],
            ),
          ),
        );
      }
    }

    /// ---------------------------------------------------------------------
    /// MEMBERSHIP / PRICING
    /// ---------------------------------------------------------------------
    class _PricingSection extends StatefulWidget {
      final VoidCallback onGetStarted;
      const _PricingSection({required this.onGetStarted, super.key});

      @override
      State<_PricingSection> createState() => _PricingSectionState();
    }

    class _PricingSectionState extends State<_PricingSection> {
      late final TapGestureRecognizer _signInRecognizer;

      @override
      void initState() {
        super.initState();
        _signInRecognizer = TapGestureRecognizer()..onTap = widget.onGetStarted;
      }

      @override
      void dispose() {
        _signInRecognizer.dispose();
        super.dispose();
      }

      @override
      Widget build(BuildContext context) {
        final bp = _breakpointOf(context);
        final sectionPadding = _sectionPadding(context);

        final plans = [
          _PlanCard(
            name: '4 Months',
            price: '₱2,400',
            badge: null,
            accent: _Palette.mutedGray,
            features: const [
              'Unlimited time',
              'Free Coach',
              'Free Drinking Water',
              'Clean Facility & Toilets'
            ],
            onGetStarted: widget.onGetStarted,
          ),
          _PlanCard(
            name: '5 Months',
            price: '₱2,800',
            badge: null,
            accent: _Palette.mutedGray,
            features: const [
              'Unlimited time',
              'Free Coach',
              'Free Drinking Water',
              'Clean Facility & Toilets'
            ],
            onGetStarted: widget.onGetStarted,
          ),
          _PlanCard(
            name: '7 Months',
            price: '₱3,500',
            badge: 'MOST POPULAR',
            accent: _Palette.cyan,
            features: const [
              'Unlimited time',
              'Free Coach',
              'Free Drinking Water',
              'Clean Facility & Toilets'
            ],
            onGetStarted: widget.onGetStarted,
          ),
          _PlanCard(
            name: '1 Year',
            price: '₱4,800',
            badge: 'BEST VALUE',
            accent: _Palette.yellow,
            features: const [
              'Unlimited time',
              'Free Coach',
              'Free Drinking Water',
              'Clean Facility & Toilets'
            ],
            onGetStarted: widget.onGetStarted,
          ),
        ];

        // Desktop keeps the existing 4-across Row untouched. Mobile/tablet use
        // a Wrap with an explicit per-card width (1 column on mobile, 2 on
        // tablet) computed from the section's own content width, so cards
        // stack/reflow instead of shrinking to fit their own content.
        final Widget plansLayout;
        if (bp == _Breakpoint.desktop) {
          plansLayout = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: plans
                .map((p) => Expanded(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: p)))
                .toList(),
          );
        } else {
          final screenWidth = MediaQuery.of(context).size.width;
          final contentWidth =
              screenWidth - sectionPadding.horizontal;
          const spacing = 16.0;
          final columns = bp == _Breakpoint.tablet ? 2 : 1;
          final cardWidth = (contentWidth - spacing * (columns - 1)) / columns;
          plansLayout = Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children:
                plans.map((p) => SizedBox(width: cardWidth, child: p)).toList(),
          );
        }

        return Container(
          width: double.infinity,
          color: _Palette.bgNearBlack,
          padding: sectionPadding,
          child: Column(
            children: [
              Text('PLANS & PRICING', style: _Fonts.sectionLabel()),
              const SizedBox(height: 10),
              Text('MEMBERSHIP SUBSCRIPTIONS',
                  style: _Fonts.display(size: 30), textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text(
                  'Choose the plan that fits your goals. All plans include full gym access — upgrade any time.',
                  style: _Fonts.body(size: 13.5, color: _Palette.mutedGray),
                  textAlign: TextAlign.center),
              const SizedBox(height: 36),
              plansLayout,
              const SizedBox(height: 22),
              RichText(
                text: TextSpan(
                  style: _Fonts.body(size: 13.5, color: _Palette.mutedGray),
                  children: [
                    const TextSpan(text: 'Already a member? '),
                    TextSpan(
                      text: 'Sign in to your account',
                      style: GoogleFonts.inter(
                          color: _Palette.cyan,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5),
                      recognizer: _signInRecognizer,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fade(duration: 500.ms).slideY(begin: 0.2);
      }
    }

    class _PlanCard extends StatefulWidget {
      final String name;
      final String price;
      final String? badge;
      final Color accent;
      final List<String> features;
      final VoidCallback onGetStarted;

      const _PlanCard({
        required this.name,
        required this.price,
        required this.badge,
        required this.accent,
        required this.features,
        required this.onGetStarted,
      });

      @override
      State<_PlanCard> createState() => _PlanCardState();
    }

    class _PlanCardState extends State<_PlanCard> {
      bool _hovered = false;

      @override
      Widget build(BuildContext context) {
        // ignore: unused_local_variable
        final isSpotlighted = widget.badge != null || _hovered;
        // Every card carries a cyan highlight by default; hovering swaps it
        // to a yellow highlight instead of each plan's own accent color.
        final borderColor = _hovered ? _Palette.yellow : _Palette.cyan;
        final glowColor = _hovered ? _Palette.yellow : _Palette.cyan;

        return MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            // Opens the plan-details popup. The "GET STARTED" button below
            // has its own onPressed and consumes its own tap, so tapping it
            // does not also trigger this.
            onTap: () => showDialog(
              context: context,
              builder: (_) => _PlanDetailsDialog(
                name: widget.name,
                price: widget.price,
                badge: widget.badge,
                accent: widget.accent,
                features: widget.features,
              ),
            ),
            child: AnimatedScale(
            scale: _hovered ? 1.02 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: _Palette.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: _hovered ? 1.8 : 1.4),
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withValues(alpha: _hovered ? 0.22 : 0.14),
                    blurRadius: _hovered ? 22 : 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.name.toUpperCase(),
                            style: _Fonts.heading(size: 16)),
                        const SizedBox(height: 10),
                        Text(widget.price, style: _Fonts.display(size: 28)),
                        const SizedBox(height: 16),
                        ...widget.features.map((f) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.check_circle,
                                      color: widget.accent, size: 15),
                                  const SizedBox(width: 7),
                                  Expanded(
                                      child:
                                          Text(f, style: _Fonts.body(size: 12.5))),
                                ],
                              ),
                            )),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: widget.onGetStarted,
                            style: ElevatedButton.styleFrom(
                              // Cyan by default on every plan; turns yellow
                              // only while the card is being hovered.
                              backgroundColor:
                                  _hovered ? _Palette.yellow : _Palette.cyan,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text('GET STARTED', style: _Fonts.button()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.badge != null)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                              color: widget.accent,
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(widget.badge!,
                              style: _Fonts.sectionLabel(color: Colors.black)
                                  .copyWith(fontSize: 10, letterSpacing: 1)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            ),
          ),
        );
      }
    }

    class _PaymentOptionInfo {
      final String name;
      final String subtitle;
      final IconData icon;
      const _PaymentOptionInfo(this.name, this.subtitle, this.icon);
    }

    const List<_PaymentOptionInfo> _kPlanPaymentOptions = [
      _PaymentOptionInfo('GCash', 'Mobile wallet — instant transfer',
          Icons.smartphone_outlined),
      _PaymentOptionInfo('Maya', 'Mobile wallet — e-money',
          Icons.account_balance_wallet_outlined),
    ];

    /// Shown when a member taps a plan card in the Membership Subscriptions
    /// section -- displays that plan's full details plus the available
    /// payment methods (GCash/Maya). UI only; no payment processing here --
    /// actual purchase still happens through "GET STARTED" -> create account.
    class _PlanDetailsDialog extends StatelessWidget {
      final String name;
      final String price;
      final String? badge;
      final Color accent;
      final List<String> features;

      const _PlanDetailsDialog({
        required this.name,
        required this.price,
        required this.badge,
        required this.accent,
        required this.features,
      });

      @override
      Widget build(BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              decoration: BoxDecoration(
                color: _Palette.bgCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _Palette.cardBorder),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        badge != null
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                    color: accent,
                                    borderRadius: BorderRadius.circular(20)),
                                child: Text(badge!,
                                    style: _Fonts.sectionLabel(color: Colors.black)
                                        .copyWith(fontSize: 10, letterSpacing: 1)),
                              )
                            : const SizedBox.shrink(),
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.close,
                                color: _Palette.lightGray, size: 22),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(name.toUpperCase(), style: _Fonts.heading(size: 18)),
                    const SizedBox(height: 6),
                    Text(price, style: _Fonts.display(size: 32)),
                    const SizedBox(height: 18),
                    ...features.map((f) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.check_circle, color: accent, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                  child:
                                      Text(f, style: _Fonts.body(size: 13.5))),
                            ],
                          ),
                        )),
                    const SizedBox(height: 24),
                    Text('PAYMENT METHOD', style: _Fonts.sectionLabel()),
                    const SizedBox(height: 4),
                    Text('Choose how you\'ll pay once you sign up.',
                        style: _Fonts.body(size: 12, color: _Palette.mutedGray)),
                    const SizedBox(height: 12),
                    for (final option in _kPlanPaymentOptions)
                      _paymentOptionTile(option),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      Widget _paymentOptionTile(_PaymentOptionInfo option) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _Palette.bgDarkSection,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _Palette.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _Palette.cyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(option.icon, color: _Palette.cyan, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(option.name, style: _Fonts.heading(size: 14)),
                    const SizedBox(height: 2),
                    Text(option.subtitle, style: _Fonts.body(size: 11.5)),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    }

    /// ---------------------------------------------------------------------
    /// LOCATION (map card + info rows are tappable — opens Google Maps,
    /// the dialer, or the mail app)
    /// ---------------------------------------------------------------------
    class _LocationSection extends StatelessWidget {
      const _LocationSection();

      @override
      Widget build(BuildContext context) {
        final isWide = _breakpointOf(context) == _Breakpoint.desktop;

        void openInMaps() => _launchUri(Uri.parse(
              'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(_primeFitAddress)}',
            ));

        final mapPlaceholder = _HoverScale(
          endScale: 1.01,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: 320,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFFE9EDF1),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _Palette.cardBorder),
              ),
              child: Stack(
                children: [
                  // Real map tiles via OpenStreetMap (flutter_map) -- no API
                  // key needed. Pan/zoom is interactive; tapping the map
                  // itself doesn't navigate away (that's what the chip/badge
                  // below are for), so dragging to pan doesn't conflict with
                  // "open in Google Maps".
                  FlutterMap(
                    options: const MapOptions(
                      initialCenter: _primeFitLatLng,
                      initialZoom: 16,
                      interactionOptions: InteractionOptions(
                        flags: InteractiveFlag.pinchZoom |
                            InteractiveFlag.drag |
                            InteractiveFlag.doubleTapZoom |
                            InteractiveFlag.scrollWheelZoom,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.primefit.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _primeFitLatLng,
                            width: 120,
                            height: 76,
                            alignment: Alignment.topCenter,
                            child: IgnorePointer(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_on,
                                      color: _Palette.yellow, size: 40),
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.75),
                                        borderRadius: BorderRadius.circular(8)),
                                    child: const Text('Taguig',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 14,
                    left: 14,
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: openInMaps,
                        child: const _MapChip(text: 'TAP TO OPEN IN GOOGLE MAPS'),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: openInMaps,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8)),
                          child: Text('Opens in a new tab',
                              style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  color: _Palette.mutedGray,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        final infoCard = Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: _Palette.bgCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _Palette.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _locationRow(Icons.location_on_outlined, 'ADDRESS', _primeFitAddress,
                  _Palette.cyan,
                  onTap: openInMaps),
              const Divider(color: _Palette.cardBorder, height: 30),
              _locationRow(
                Icons.call_outlined,
                'PHONE',
                '+63 917 847 8351',
                _Palette.yellow,
                onTap: () => _launchUri(Uri.parse('tel:+639178478351')),
              ),
              const Divider(color: _Palette.cardBorder, height: 30),
              _locationRow(
                Icons.mail_outline,
                'EMAIL',
                'primefitnesstaguig@gmail.com',
                _Palette.cyan,
                onTap: () =>
                    _launchUri(Uri.parse('mailto:primefitnesstaguig@gmail.com')),
              ),
              const Divider(color: _Palette.cardBorder, height: 30),
              _locationRow(Icons.schedule_outlined, 'HOURS',
                  'Mon–Sun: 7:00 AM – 10:00 PM', _Palette.yellow),
            ],
          ),
        );

        return Container(
          width: double.infinity,
          color: _Palette.bgDarkSection,
          padding: _sectionPadding(context),
          child: Column(
            children: [
              Text('FIND US', style: _Fonts.sectionLabel()),
              const SizedBox(height: 10),
              Text('PRIMEFIT LOCATION',
                  style: _Fonts.display(size: 30), textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text("Come visit us at our Taguig City gym — we're open every day.",
                  style: _Fonts.body(size: 13.5, color: _Palette.mutedGray),
                  textAlign: TextAlign.center),
              const SizedBox(height: 40),
              isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: mapPlaceholder),
                        const SizedBox(width: 28),
                        Expanded(child: infoCard),
                      ],
                    )
                  : Column(children: [
                      mapPlaceholder,
                      const SizedBox(height: 24),
                      infoCard
                    ]),
            ],
          ),
        ).animate().fade(duration: 500.ms).slideY(begin: 0.2);
      }

      Widget _locationRow(IconData icon, String label, String value, Color accent,
          {VoidCallback? onTap}) {
        final content = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: Icon(icon, color: accent, size: 19),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: _Fonts.sectionLabel(color: _Palette.mutedGray)
                          .copyWith(fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      color: onTap != null ? _Palette.cyan : _Palette.offWhite,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      decoration: onTap != null
                          ? TextDecoration.underline
                          : TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        if (onTap == null) return content;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: content,
          ),
        );
      }
    }

    class _MapChip extends StatelessWidget {
      final String text;
      const _MapChip({required this.text});

      @override
      Widget build(BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8)),
          child: Text(text,
              style:
                  _Fonts.sectionLabel(color: Colors.white).copyWith(fontSize: 10)),
        );
      }
    }

    /// ---------------------------------------------------------------------
    /// MERCHANDISE / PRIMEFIT STORE (in-store only — no cart/checkout)
    /// ---------------------------------------------------------------------
    class _MerchItem {
      final IconData icon;
      final String category;
      final Color badgeColor;
      final String name;
      final String code;
      final String price;
      final String stock;
      final String imagePath;
      const _MerchItem({
        required this.icon,
        required this.category,
        required this.badgeColor,
        required this.name,
        required this.code,
        required this.price,
        required this.stock,
        required this.imagePath,
      });
    }

    class _MerchSection extends StatelessWidget {
      const _MerchSection({super.key});

      @override
      Widget build(BuildContext context) {
        const items = [
          _MerchItem(
            icon: Icons.checkroom_outlined,
            category: 'APPAREL',
            badgeColor: _Palette.cyan,
            name: 'PrimeFit Sando Muscle Tee (All Sizes)',
            code: '#MC-003-SMT',
            price: '₱260',
            stock: 'Stock: 37',
            imagePath: 'assets/images/merch/sando_muscle_tee.jpg',
          ),
          _MerchItem(
            icon: Icons.checkroom_outlined,
            category: 'APPAREL',
            badgeColor: _Palette.yellow,
            name: 'PrimeFit Sando Sleeveless (All Sizes)',
            code: '#MC-002-SSL',
            price: '₱260',
            stock: 'Stock: 38',
            imagePath: 'assets/images/merch/sando_sleeveless.jpg',
          ),
          _MerchItem(
            icon: Icons.checkroom_outlined,
            category: 'APPAREL',
            badgeColor: _Palette.cyan,
            name: 'PrimeFit T-Shirt (All Sizes)',
            code: '#MC-001-TSH',
            price: '₱290',
            stock: 'Stock: 39',
            imagePath: 'assets/images/merch/tshirt.jpg',
          ),
        ];

        return Container(
          width: double.infinity,
          color: _Palette.bgNearBlack,
          padding: _sectionPadding(context),
          child: Column(
            children: [
              Text('PRIMEFIT STORE',
                  style: _Fonts.sectionLabel(color: _Palette.yellow)),
              const SizedBox(height: 10),
              Text('MERCH & APPAREL',
                  style: _Fonts.display(size: 30), textAlign: TextAlign.center),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Text(
                  "Rep the gym with PrimeFit's official apparel. Available exclusively at our Taguig City location.",
                  style: _Fonts.body(size: 13.5, color: _Palette.mutedGray),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: _Palette.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _Palette.cardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.storefront_outlined,
                        color: _Palette.yellow, size: 15),
                    const SizedBox(width: 8),
                    Text('IN-STORE PURCHASE ONLY · VISIT US TO BUY',
                        style: _Fonts.sectionLabel(color: _Palette.offWhite)
                            .copyWith(fontSize: 11.5)),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: items.map((item) => _MerchCard(item: item)).toList(),
              ),
            ],
          ),
        ).animate().fade(duration: 500.ms).slideY(begin: 0.2);
      }
    }

    class _MerchCard extends StatelessWidget {
      final _MerchItem item;
      const _MerchCard({required this.item});

      @override
      Widget build(BuildContext context) {
        return _HoverScale(
          endScale: 1.02,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => showDialog(
                context: context,
                builder: (_) => _MerchDetailsDialog(item: item),
              ),
              child: Container(
            width: 290,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _Palette.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _Palette.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Light card behind the product photo (like the reference —
                // apparel photos usually have a white/transparent
                // background, so a dark card would make them hard to see).
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    color: const Color(0xFFF3F3F4),
                    padding: const EdgeInsets.all(12),
                    child: Image.asset(
                      item.imagePath,
                      fit: BoxFit.contain,
                      // Falls back to the category icon if the photo isn't
                      // found yet, instead of crashing the page.
                      errorBuilder: (context, error, stackTrace) => Icon(
                        item.icon,
                        color: item.badgeColor.withValues(alpha: 0.5),
                        size: 56,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: item.badgeColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(item.category,
                      style: _Fonts.sectionLabel(color: item.badgeColor)
                          .copyWith(fontSize: 10.5)),
                ),
                const SizedBox(height: 12),
                Text(item.name,
                    style: _Fonts.heading(size: 16, weight: FontWeight.w700)
                        .copyWith(height: 1.3)),
                const SizedBox(height: 4),
                Text(item.code,
                    style: _Fonts.body(size: 12, color: _Palette.mutedGray)),
                const SizedBox(height: 14),
                Text(item.price,
                    style: _Fonts.display(size: 24, color: _Palette.yellow)),
              ],
            ),
          ),
            ),
          ),
        );
      }
    }

    /// Shown when a member taps a merch card -- displays that item's full
    /// details (photo, category, name, code, price) plus the in-store-only
    /// purchase note. UI-only, no cart/checkout wired up here.
    class _MerchDetailsDialog extends StatelessWidget {
      final _MerchItem item;
      const _MerchDetailsDialog({required this.item});

      @override
      Widget build(BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Container(
              decoration: BoxDecoration(
                color: _Palette.bgCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _Palette.cardBorder),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.close,
                              color: _Palette.lightGray, size: 22),
                        ),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 220,
                        width: double.infinity,
                        color: const Color(0xFFF3F3F4),
                        padding: const EdgeInsets.all(16),
                        child: Image.asset(
                          item.imagePath,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            item.icon,
                            color: item.badgeColor.withValues(alpha: 0.5),
                            size: 64,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: item.badgeColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(item.category,
                          style: _Fonts.sectionLabel(color: item.badgeColor)
                              .copyWith(fontSize: 10.5)),
                    ),
                    const SizedBox(height: 12),
                    Text(item.name,
                        style: _Fonts.heading(size: 18, weight: FontWeight.w700)
                            .copyWith(height: 1.3)),
                    const SizedBox(height: 4),
                    Text(item.code,
                        style: _Fonts.body(size: 12.5, color: _Palette.mutedGray)),
                    const SizedBox(height: 14),
                    Text(item.price,
                        style: _Fonts.display(size: 28, color: _Palette.yellow)),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _Palette.bgDarkSection,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _Palette.cardBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.storefront_outlined,
                              color: _Palette.yellow, size: 15),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'IN-STORE PURCHASE ONLY · VISIT US TO BUY',
                              style: _Fonts.sectionLabel(color: _Palette.offWhite)
                                  .copyWith(fontSize: 11.5),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }

    /// ---------------------------------------------------------------------
    /// CONTACT / GET IN TOUCH
    /// ---------------------------------------------------------------------
    class _ContactItem {
      final IconData icon;
      final String label;
      final String value;
      final Color accent;
      final bool looksLikeLink;
      final VoidCallback? onTap;
      const _ContactItem(
        this.icon,
        this.label,
        this.value, {
        required this.accent,
        this.looksLikeLink = false,
        this.onTap,
      });
    }

    class _ContactSection extends StatelessWidget {
      const _ContactSection({super.key});

      @override
      Widget build(BuildContext context) {
        final items = <_ContactItem>[
          _ContactItem(
            Icons.location_on_outlined,
            'LOCATION',
            _primeFitAddress,
            accent: _Palette.yellow,
            onTap: () => _launchUri(Uri.parse(
              'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(_primeFitAddress)}',
            )),
          ),
          _ContactItem(
            Icons.call_outlined,
            'PHONE',
            '0917 847 8351',
            accent: _Palette.cyan,
            looksLikeLink: true,
            onTap: () => _launchUri(Uri.parse('tel:09178478351')),
          ),
          _ContactItem(
            Icons.mail_outline,
            'EMAIL',
            'primefitnesstaguig@gmail.com',
            accent: _Palette.cyan,
            looksLikeLink: true,
            onTap: () =>
                _launchUri(Uri.parse('mailto:primefitnesstaguig@gmail.com')),
          ),
          _ContactItem(
            Icons.music_note_outlined,
            'TIKTOK',
            '@primefit.fitness.g',
            accent: _Palette.yellow,
            onTap: () =>
                _launchUri(Uri.parse('https://www.tiktok.com/@primefit.fitness.g')),
          ),
          _ContactItem(
            Icons.facebook_outlined,
            'FACEBOOK / MESSENGER',
            'PrimeFit Fitness Gym',
            accent: _Palette.yellow,
            onTap: () => _launchUri(
              Uri.parse('https://www.facebook.com/profile.php?id=61579305812618'),
            ),
          ),
        ];

        return Container(
          width: double.infinity,
          color: _Palette.bgDarkGraySection,
          padding: _sectionPadding(context),
          child: Column(
            children: [
              Text('GET IN TOUCH',
                  style: _Fonts.sectionLabel(color: _Palette.yellow)),
              const SizedBox(height: 12),
              Text('CONTACT PRIMEFIT', style: _Fonts.display(size: 34)),
              const SizedBox(height: 44),
              Wrap(
                spacing: 24,
                runSpacing: 24,
                alignment: WrapAlignment.center,
                children: items.map((it) => _ContactCard(item: it)).toList(),
              ),
              const SizedBox(height: 34),
              const _BusinessHoursCard(),
            ],
          ),
        ).animate().fade(duration: 500.ms).slideY(begin: 0.2);
      }
    }

    class _ContactCard extends StatelessWidget {
      final _ContactItem item;
      const _ContactCard({required this.item});

      @override
      Widget build(BuildContext context) {
        // Only text sizing/line-height still depends on value length; the
        // card itself is now a fixed size for every item so the 5 cards
        // (including the longer address) line up evenly.
        final isLongValue = item.value.length > 30;
        final card = Container(
          width: 260,
          height: 232,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          decoration: BoxDecoration(
            color: _Palette.bgCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _Palette.cardBorder),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: item.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: item.accent.withValues(alpha: 0.4)),
                ),
                alignment: Alignment.center,
                child: Icon(item.icon, color: item.accent, size: 26),
              ),
              const SizedBox(height: 16),
              Text(item.label,
                  style: _Fonts.sectionLabel(color: _Palette.mutedGray)
                      .copyWith(fontSize: 12)),
              const SizedBox(height: 6),
              Text(
                item.value,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: isLongValue ? 13.5 : 17,
                  height: isLongValue ? 1.5 : 1.3,
                  color: item.looksLikeLink ? _Palette.cyan : _Palette.offWhite,
                  decoration: item.looksLikeLink
                      ? TextDecoration.underline
                      : TextDecoration.none,
                ),
              ),
            ],
          ),
        );

        return _HoverScale(
          endScale: 1.03,
          child: item.onTap != null
              ? Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    onTap: item.onTap,
                    borderRadius: BorderRadius.circular(18),
                    child: card,
                  ),
                )
              : card,
        );
      }
    }

    class _BusinessHoursCard extends StatelessWidget {
      const _BusinessHoursCard();

      @override
      Widget build(BuildContext context) {
        return _HoverScale(
          endScale: 1.01,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 28),
            decoration: BoxDecoration(
              color: _Palette.bgCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _Palette.yellow.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.schedule, color: _Palette.yellow, size: 22),
                    const SizedBox(width: 8),
                    Text('Business Hours', style: _Fonts.heading(size: 16)),
                  ],
                ),
                const SizedBox(height: 14),
                Text('Monday – Saturday: 7:00 AM – 10:00 PM',
                    style: _Fonts.body(size: 14.5)),
                const SizedBox(height: 4),
                Text('Sunday: 8:00 AM – 8:00 PM', style: _Fonts.body(size: 14.5)),
              ],
            ),
          ),
        );
      }
    }

    /// ---------------------------------------------------------------------
    /// FOOTER
    /// ---------------------------------------------------------------------
    ///
    /// Layout pattern: a decorative scalloped edge transitions out of the
    /// preceding (dark) section into the footer's own (darker) background,
    /// then four columns -- Brand, Quick Links, Visit Us, Follow Along --
    /// stack on narrow widths and sit side-by-side on wide ones, followed
    /// by a thin copyright bar. PrimeFit's landing page is dark throughout
    /// (there's no light section to transition from), so the scallop here
    /// bridges two of the app's existing dark tones instead of light-to-dark.
    class _Footer extends StatelessWidget {
      final VoidCallback onAbout;
      final VoidCallback onMission;
      final VoidCallback onMembership;
      final VoidCallback onMerchandise;
      final VoidCallback onContact;

      const _Footer({
        required this.onAbout,
        required this.onMission,
        required this.onMembership,
        required this.onMerchandise,
        required this.onContact,
      });

      @override
      Widget build(BuildContext context) {
        final isWide = _breakpointOf(context) == _Breakpoint.desktop;

        return Column(
          children: [
            // The section directly above the footer (_ContactSection) uses
            // bgDarkGraySection, so the scallop's backdrop matches that
            // exactly and the footer's bumps read as a clean transition.
            Container(
              color: _Palette.bgDarkGraySection,
              child: const _ScallopEdge(color: _Palette.bgDeepBlack, radius: 18),
            ),
            Container(
              width: double.infinity,
              color: _Palette.bgDeepBlack,
              padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 72 : 24, vertical: isWide ? 56 : 40),
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(flex: 3, child: _FooterBrandColumn()),
                        Expanded(
                          flex: 2,
                          child: _FooterQuickLinksColumn(
                            onAbout: onAbout,
                            onMission: onMission,
                            onMembership: onMembership,
                            onMerchandise: onMerchandise,
                            onContact: onContact,
                          ),
                        ),
                        const Expanded(flex: 3, child: _FooterVisitUsColumn()),
                        const Expanded(flex: 2, child: _FooterFollowColumn()),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FooterBrandColumn(),
                        const SizedBox(height: 32),
                        _FooterQuickLinksColumn(
                          onAbout: onAbout,
                          onMission: onMission,
                          onMembership: onMembership,
                          onMerchandise: onMerchandise,
                          onContact: onContact,
                        ),
                        const SizedBox(height: 32),
                        const _FooterVisitUsColumn(),
                        const SizedBox(height: 32),
                        const _FooterFollowColumn(),
                      ],
                    ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: const BoxDecoration(
                color: _Palette.bgDeepBlack,
                border:
                    Border(top: BorderSide(color: _Palette.cardBorder, width: 1)),
              ),
              child: Center(
                child: Text(
                  '© $_kFooterCopyrightYear PrimeFit. All rights reserved.',
                  style: _Fonts.body(size: 12, color: _Palette.mutedGray),
                ),
              ),
            ),
          ],
        );
      }
    }

    /// Repeating semicircle "scallop" band -- the widget's height equals the
    /// bump radius, with the bumps' apex at y=0 (touching whatever sits
    /// above) and the flat baseline at y=radius (matching [color] below).
    class _ScallopEdge extends StatelessWidget {
      final Color color;
      final double radius;
      const _ScallopEdge({required this.color, this.radius = 16});

      @override
      Widget build(BuildContext context) {
        return SizedBox(
          width: double.infinity,
          height: radius,
          child: CustomPaint(
            size: Size.infinite,
            painter: _ScallopPainter(color: color, radius: radius),
          ),
        );
      }
    }

    class _ScallopPainter extends CustomPainter {
      final Color color;
      final double radius;
      const _ScallopPainter({required this.color, required this.radius});

      @override
      void paint(Canvas canvas, Size size) {
        final paint = Paint()..color = color;
        final diameter = radius * 2;
        final count = (size.width / diameter).ceil();

        final path = Path()..moveTo(0, radius);
        for (int i = 0; i < count; i++) {
          final endX = (i + 1) * diameter;
          // clockwise:true sweeps west -> north -> east, i.e. the bump
          // bulges *up* (toward y=0) rather than dipping down.
          path.arcToPoint(Offset(endX, radius),
              radius: Radius.circular(radius), clockwise: true);
        }
        path.lineTo(size.width, size.height);
        path.lineTo(0, size.height);
        path.close();

        canvas.drawPath(path, paint);
      }

      @override
      bool shouldRepaint(covariant _ScallopPainter oldDelegate) =>
          oldDelegate.color != color || oldDelegate.radius != radius;
    }

    class _FooterBrandColumn extends StatelessWidget {
      const _FooterBrandColumn();

      @override
      Widget build(BuildContext context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/images/primefit_logo.jpg',
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 9),
                const PrimeFitWordmark(fontSize: 17),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: 260,
              child: Text('Your fitness journey starts here.',
                  style: _Fonts.body(size: 13.5)),
            ),
          ],
        );
      }
    }

    class _FooterQuickLinksColumn extends StatelessWidget {
      final VoidCallback onAbout;
      final VoidCallback onMission;
      final VoidCallback onMembership;
      final VoidCallback onMerchandise;
      final VoidCallback onContact;

      const _FooterQuickLinksColumn({
        required this.onAbout,
        required this.onMission,
        required this.onMembership,
        required this.onMerchandise,
        required this.onContact,
      });

      @override
      Widget build(BuildContext context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('QUICK LINKS', style: _Fonts.sectionLabel()),
            const SizedBox(height: 18),
            _FooterLink('About', onAbout),
            _FooterLink('Mission', onMission),
            _FooterLink('Membership', onMembership),
            _FooterLink('Merchandise', onMerchandise),
            _FooterLink('Contact', onContact),
          ],
        );
      }
    }

    class _FooterLink extends StatelessWidget {
      final String label;
      final VoidCallback onTap;
      const _FooterLink(this.label, this.onTap);

      @override
      Widget build(BuildContext context) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: onTap,
            child: Text(label,
                style: _Fonts.body(size: 14, color: _Palette.lightGray)),
          ),
        );
      }
    }

    class _FooterVisitUsColumn extends StatelessWidget {
      const _FooterVisitUsColumn();

      @override
      Widget build(BuildContext context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('VISIT US', style: _Fonts.sectionLabel()),
            const SizedBox(height: 18),
            SizedBox(
              width: 280,
              child: Text(_primeFitAddress, style: _Fonts.body(size: 14)),
            ),
            const SizedBox(height: 14),
            Text('Monday – Saturday: 7:00 AM – 10:00 PM',
                style: _Fonts.body(size: 14)),
            const SizedBox(height: 4),
            Text('Sunday: 8:00 AM – 8:00 PM', style: _Fonts.body(size: 14)),
          ],
        );
      }
    }

    class _FooterFollowColumn extends StatelessWidget {
      const _FooterFollowColumn();

      @override
      Widget build(BuildContext context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FOLLOW ALONG', style: _Fonts.sectionLabel()),
            const SizedBox(height: 18),
            _FooterSocialLink(
              icon: Icons.facebook_outlined,
              label: 'Facebook',
              onTap: () => _launchUri(Uri.parse(
                  'https://www.facebook.com/profile.php?id=61579305812618')),
            ),
            _FooterSocialLink(
              icon: Icons.music_note_outlined,
              label: 'TikTok',
              onTap: () => _launchUri(
                  Uri.parse('https://www.tiktok.com/@primefit.fitness.g')),
            ),
          ],
        );
      }
    }

    class _FooterSocialLink extends StatelessWidget {
      final IconData icon;
      final String label;
      final VoidCallback onTap;
      const _FooterSocialLink(
          {required this.icon, required this.label, required this.onTap});

      @override
      Widget build(BuildContext context) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: onTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: _Palette.cyan),
                const SizedBox(width: 8),
                Text(label,
                    style: _Fonts.body(size: 14, color: _Palette.lightGray)),
              ],
            ),
          ),
        );
      }
    }
