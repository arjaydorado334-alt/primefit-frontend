import 'dart:ui' show ImageFilter;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderAbstractViewport;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_stat_card.dart';
import '../widgets/gold_rule.dart';
import '../widgets/landing_section.dart';
import '../widgets/pill_button.dart';
import '../widgets/prime_fit_logo.dart';
import '../widgets/reviews_section.dart';
import '../data/gallery_images.dart';
import 'login_page.dart';
import 'create_account.dart';

/// The landing page's colour tokens. The public site runs on a **dark**
/// theme (near-black page, dark-charcoal cards) skinned with PrimeFit's own
/// cyan / gold / plum accents — surface/text values reuse the app theme's
/// existing dark-mode tokens ([AppColors.darkBg] etc). Member names are
/// kept (e.g. `white` is the light primary *text* colour on the dark
/// ground) so existing call sites cascade.
class _Palette {
  static const bgNearBlack = AppColors.darkBg; // page ground  #0A0A0B
  static const bgDeepBlack = Color(0xFF060608); // navbar / footer (deeper)
  static const bgDarkSection = AppColors.darkBg; // section surface
  static const bgDarkGraySection = Color(0xFF121316); // alternating section
  static const bgCard = AppColors.darkCard; // card surface  #15161A

  static const yellow = AppColors.gold; // #F2B705
  // ignore: unused_field
  static const yellowBright = AppColors.goldDark; // hover / pressed

  static const cyan = AppColors.cyan; // #17C3D6
  // ignore: unused_field
  static const cyanBright = AppColors.cyan;

  static const white = Color(0xFFE9EAEE); // primary text on dark
  static const offWhite = Color(0xFFF4F5F7); // headings / strong text
  static const lightGray = AppColors.textMutedOnDark; // muted  #9CA3AF
  static const mutedGray = Color(0xFF868D99); // very muted (still AA on dark)

  static const cardBorder = AppColors.darkBorder; // #262832
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

    const double _kNavBarHeight = 100;

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

    // Geocoded to Bernardo Street, Central Signal Village, Taguig (OSM
    // Nominatim). Confirm the exact building with the gym and adjust if
    // needed -- "Get Directions" and the marker both use this.
    const LatLng _primeFitLatLng = LatLng(14.5089, 121.0569);

    // Footer copyright year -- update this each January rather than computing
    // it from DateTime.now(), so the footer doesn't silently roll over mid-way
    // through a deploy or depend on the visitor's device clock.
    const int _kFooterCopyrightYear = 2026;

    final GlobalKey _aboutKey = GlobalKey();
    final GlobalKey _missionKey = GlobalKey();
    final GlobalKey _pricingKey = GlobalKey();
    final GlobalKey _merchKey = GlobalKey();
    final GlobalKey _contactKey = GlobalKey();

    /// Drives the page scroll so "About / Mission / …" nav links can land a
    /// section just *below* the overlaid glass nav bar instead of behind it.
    final ScrollController _pageScroll = ScrollController();

    void _scrollToKey(GlobalKey key) {
      final ctx = key.currentContext;
      if (ctx == null || !_pageScroll.hasClients) return;
      final box = ctx.findRenderObject();
      if (box is! RenderBox) return;
      final reveal =
          RenderAbstractViewport.of(box).getOffsetToReveal(box, 0.0).offset;
      final target = (reveal - _kNavBarHeight - 12)
          .clamp(0.0, _pageScroll.position.maxScrollExtent);
      _pageScroll.animateTo(target,
          duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    }

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

      void _scrollToAbout(BuildContext context) => _scrollToKey(_aboutKey);
      void _scrollToMission(BuildContext context) => _scrollToKey(_missionKey);
      void _scrollToMembership(BuildContext context) => _scrollToKey(_pricingKey);
      void _scrollToMerch(BuildContext context) => _scrollToKey(_merchKey);
      void _scrollToContact(BuildContext context) => _scrollToKey(_contactKey);

      @override
      Widget build(BuildContext context) {
        // NavBar is kept OUTSIDE the scroll view (fixed at the top, always
        // visible) while everything else scrolls beneath it in the Expanded
        // SingleChildScrollView below -- this is what makes the nav "sticky."
        //
        // The public landing page always renders on the app's dark theme
        // (independent of the member portal's light/dark toggle), so text
        // that inherits its colour from the theme reads light-on-dark.
        return Theme(
          data: AppTheme.darkThemeData,
          child: Scaffold(
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
          // The nav bar is overlaid on top of the scroll view (not stacked
          // above it) so page content slides *under* its frosted glass.
          body: Stack(
            children: [
              Positioned.fill(
                child: SingleChildScrollView(
                  controller: _pageScroll,
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
                      const GoldRule(verticalMargin: 4),
                      const _ResultsSection(),
                      const _GallerySection(),
                      ReviewsSection(onSignIn: () => _goToLogin(context)),
                      const GoldRule(verticalMargin: 4),
                      _MerchSection(key: _merchKey),
                      const _LocationSection(),
                      _ContactSection(key: _contactKey),
                      _CtaBand(
                        onJoin: () => _goToCreateAccount(context),
                        onViewPlans: () => _scrollToMembership(context),
                      ),
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
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _NavBar(
                  onSignIn: () => _goToLogin(context),
                  onJoin: () => _goToCreateAccount(context),
                  onAbout: () => _scrollToAbout(context),
                  onMission: () => _scrollToMission(context),
                  onMembership: () => _scrollToMembership(context),
                  onMerchandise: () => _scrollToMerch(context),
                  onContact: () => _scrollToContact(context),
                ),
              ),
            ],
          ),
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
        // Frosted-glass nav: a backdrop blur + dark tint so page content
        // scrolling underneath shows through as a blur, with a hairline
        // light bottom edge. Sits in a Stack over the scroll view.
        return ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
          height: _kNavBarHeight,
          // Extra horizontal breathing room so the logo and the Sign In /
          // Join Now buttons aren't hugging the very edge of the screen.
          padding: EdgeInsets.only(left: horizontalPadding, right: horizontalPadding),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.58),
            border: Border(
                bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.12), width: 1)),
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
                        width: 42,
                        height: 42,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 11),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
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
                      foregroundColor: AppColors.onGold,
                      padding: EdgeInsets.symmetric(
                          horizontal: isWide ? 22 : 16, vertical: 13),
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                    child: Text('JOIN NOW', style: _Fonts.button(size: 14)),
                  ),
                  if (!isWide) ...[
                    const SizedBox(width: 6),
                    Builder(
                      builder: (context) => IconButton(
                        onPressed: () => Scaffold.of(context).openEndDrawer(),
                        icon: const Icon(Icons.menu, color: _Palette.white),
                        tooltip: 'Menu',
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ).animate().fade(duration: 400.ms),
          ),
        );
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
              title: Text(label, style: _Fonts.nav(color: _Palette.white)),
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
                        foregroundColor: AppColors.onGold,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const StadiumBorder(),
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

      // The hero is the ONE place a dark ground is allowed — a photo needs a
      // scrim for text legibility. Explicit near-black (not `_Palette`, which
      // is now light).
      static const _scrimDark = Color(0xFF0A0A0B);

      @override
      Widget build(BuildContext context) {
        final bp = _breakpointOf(context);
        final displaySize = switch (bp) {
          _Breakpoint.mobile => 44.0,
          _Breakpoint.tablet => 64.0,
          _Breakpoint.desktop => 88.0,
        };
        final subheadSize = switch (bp) {
          _Breakpoint.mobile => 20.0,
          _Breakpoint.tablet => 24.0,
          _Breakpoint.desktop => 30.0,
        };
        final bodySize = bp == _Breakpoint.mobile ? 15.0 : 17.0;
        // Top padding clears the overlaid glass nav bar so the hero content
        // is never hidden behind it.
        final heroPadding = switch (bp) {
          _Breakpoint.mobile =>
            const EdgeInsets.fromLTRB(20, _kNavBarHeight + 24, 20, 40),
          _Breakpoint.tablet =>
            const EdgeInsets.fromLTRB(40, _kNavBarHeight + 28, 32, 56),
          _Breakpoint.desktop =>
            const EdgeInsets.fromLTRB(80, _kNavBarHeight + 28, 56, 72),
        };
        const headlineShadow = [
          Shadow(color: Colors.black, blurRadius: 14, offset: Offset(0, 2)),
        ];

        // Headline + subhead + subtext — plain over the scrim (the glass
        // treatment now lives on the nav bar, not the hero content). A
        // strong text shadow keeps them legible over the photo.
        final headlineBlock = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FIT FOR',
                style: AppText.pageTitle(size: displaySize, color: Colors.white)
                    .copyWith(height: 1.02, shadows: headlineShadow)),
            Text('ALL.',
                style: AppText.pageTitle(
                        size: displaySize, color: _Palette.yellow)
                    .copyWith(height: 1.02, shadows: headlineShadow)),
            const SizedBox(height: 10),
            Text('Where your fitness journey begins.',
                style: AppText.pageTitle(size: subheadSize, color: _Palette.cyan)
                    .copyWith(shadows: headlineShadow)),
            const SizedBox(height: 18),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Text(
                'PrimeFit Fitness Gym is your complete training destination — '
                'equipped, supportive, and built for every level of athlete.',
                style: AppText.bodyText(
                    size: bodySize,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.6),
              ),
            ),
          ],
        );

        final textColumn = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pill eyebrow badge — dark glass
            GlassPanel(
              radius: 999,
              blur: 10,
              tint: 0.4,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('TAGUIG CITY, PHILIPPINES',
                  style: AppText.eyebrow(color: Colors.white)),
            ).animate().fade(delay: 200.ms).slideX(begin: -0.4),
            const SizedBox(height: 22),
            headlineBlock.animate().fade(delay: 320.ms).slideX(begin: -0.35),
            const SizedBox(height: 28),
            Wrap(
              spacing: 14,
              runSpacing: 12,
              children: [
                PillButton('GET STARTED',
                    onPressed: onGetStarted, icon: Icons.arrow_forward),
                PillButton('VIEW PLANS',
                    onPressed: onViewPlans, variant: PillVariant.ghost),
              ],
            ).animate().fade(delay: 600.ms).slideY(begin: 0.3),
            const SizedBox(height: 24),
            const _HeroTrustRow(scrimDark: _scrimDark)
                .animate()
                .fade(delay: 680.ms),
            if (bp != _Breakpoint.desktop) ...[
              const SizedBox(height: 28),
              const _HeroGlassCards(vertical: false)
                  .animate()
                  .fade(delay: 760.ms)
                  .slideY(begin: 0.3),
            ],
          ],
        );

        final screenHeight = MediaQuery.of(context).size.height;

        return Container(
          width: double.infinity,
          // Fixed height keeps the Stack bounded inside the outer scroll view
          // (an unbounded Stack with fill children crashes). Sized to ~the
          // full viewport so the hero dominates the first screen; the floor
          // stops multi-line content clipping on short viewports.
          height: switch (bp) {
            _Breakpoint.desktop =>
              screenHeight.clamp(760.0, double.infinity),
            _Breakpoint.tablet =>
              (screenHeight - _kNavBarHeight).clamp(760.0, double.infinity),
            _Breakpoint.mobile =>
              (screenHeight - _kNavBarHeight).clamp(720.0, double.infinity),
          },
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(color: _scrimDark),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/hero_bg.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const ColoredBox(color: _scrimDark),
              ),
              // Left-to-right dark scrim for text legibility.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      _scrimDark,
                      _scrimDark.withValues(alpha: 0.9),
                      _scrimDark.withValues(alpha: 0.5),
                      _scrimDark.withValues(alpha: 0.12),
                    ],
                    stops: const [0.0, 0.4, 0.72, 1.0],
                  ),
                ),
              ),
              Padding(
                padding: heroPadding,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: textColumn,
                    ),
                  ),
                ),
              ),
              // Floating glass stat cards, overlaid bottom-right on desktop.
              if (bp == _Breakpoint.desktop)
                Positioned(
                  right: 56,
                  bottom: 44,
                  child: const _HeroGlassCards(vertical: true)
                      .animate()
                      .fade(delay: 780.ms)
                      .slideY(begin: 0.3),
                ),
            ],
          ),
        );
      }
    }

    /// Avatar stack + star rating + caption shown under the hero CTAs.
    class _HeroTrustRow extends StatelessWidget {
      final Color scrimDark;
      const _HeroTrustRow({required this.scrimDark});

      @override
      Widget build(BuildContext context) {
        const avatarColors = [_Palette.cyan, _Palette.yellow, _Palette.cyan];
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 78,
              height: 34,
              child: Stack(
                children: [
                  for (int i = 0; i < 3; i++)
                    Positioned(
                      left: i * 22.0,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: avatarColors[i],
                          border: Border.all(color: scrimDark, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.person,
                            size: 17, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                      5,
                      (_) => const Icon(Icons.star_rounded,
                          size: 16, color: AppColors.gold)),
                ),
                const SizedBox(height: 2),
                Text('Loved by our members',
                    style: AppText.bodySmall(
                        color: Colors.white.withValues(alpha: 0.78))),
              ],
            ),
          ],
        );
      }
    }

    /// The three frosted-glass stat cards overlaid on the hero photo.
    class _HeroGlassCards extends StatelessWidget {
      final bool vertical;
      const _HeroGlassCards({required this.vertical});

      @override
      Widget build(BuildContext context) {
        const cards = [
          GlassStatCard(value: '50+', caption: 'Active members'),
          GlassStatCard(
              value: '1+', caption: 'Years operating', valueColor: AppColors.gold),
          GlassStatCard(value: '20+', caption: 'Equipment types'),
        ];
        if (vertical) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                SizedBox(width: 180, child: cards[i]),
              ],
            ],
          );
        }
        return const Wrap(spacing: 12, runSpacing: 12, children: cards);
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
          ['50+', 'Active members'],
          ['1+', 'Years operating'],
          ['20+', 'Equipment types'],
          ['7AM–10PM', 'Daily hours'],
        ];
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
          decoration: BoxDecoration(
            color: _Palette.bgDeepBlack,
            // Slim gold hairlines top + bottom — a gold-accented stat strip
            // that echoes the CTA band without a solid-gold fill.
            border: Border.symmetric(
              horizontal: BorderSide(
                  color: AppColors.gold.withValues(alpha: 0.45), width: 1),
            ),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceEvenly,
            spacing: 24,
            runSpacing: 20,
            children: stats
                .map((s) => SizedBox(
                      width: 168,
                      child: Column(
                        children: [
                          Text(s[0],
                              style: AppText.statNumber(
                                  size: 26, color: _Palette.yellow)),
                          const SizedBox(height: 2),
                          Text(s[1],
                              style: AppText.statCaption(
                                  color: _Palette.lightGray)),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ).animate().fade(duration: 500.ms).slideY(begin: 0.2);
      }
    }

    /// ---------------------------------------------------------------------
    /// FEATURES / WHY CHOOSE US
    /// ---------------------------------------------------------------------
    class _FeaturesStrip extends StatelessWidget {
      const _FeaturesStrip();

      static const _features = [
        (
          Icons.fitness_center_outlined,
          'Modern equipment',
          'Full range of machines, free weights, and cardio equipment.',
          AppColors.cyanTint,
          Color(0xFF0E7490),
        ),
        (
          Icons.badge_outlined,
          'Expert staff',
          'Certified and experienced trainers to guide members.',
          AppColors.goldTint,
          Color(0xFFB4770E),
        ),
        (
          Icons.track_changes_outlined,
          'Personalized plans',
          'Workout programs and plans tailored to member goals.',
          AppColors.goldTint,
          Color(0xFFB4770E),
        ),
        (
          Icons.groups_outlined,
          'Supportive community',
          'A positive, inclusive environment that keeps members motivated.',
          AppColors.cyanTint,
          Color(0xFF0E7490),
        ),
      ];

      @override
      Widget build(BuildContext context) {
        final w = MediaQuery.of(context).size.width;
        final cols = w < 640 ? 1 : (w < 1024 ? 2 : 4);
        return LandingSection(
          eyebrow: 'Why choose us',
          title: 'Everything you need to train',
          subtitle:
              'A complete gym built around real results — the equipment, the '
              'people, and the plans to get you there.',
          eyebrowColor: _Palette.cyan,
          background: _Palette.bgNearBlack,
          child: GridView.count(
            crossAxisCount: cols,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: cols == 1 ? 2.6 : (cols == 2 ? 1.5 : 0.92),
            children: [
              for (final f in _features)
                _FeatureCard(
                    icon: f.$1,
                    title: f.$2,
                    body: f.$3,
                    badgeBg: f.$4,
                    badgeIcon: f.$5),
            ],
          ),
        ).animate().fade(duration: 500.ms).slideY(begin: 0.15);
      }
    }

    /// A dark "Why choose us" card whose border warms to gold on hover, so
    /// the gold accent shows up here too — not just on the CTA band.
    class _FeatureCard extends StatefulWidget {
      final IconData icon;
      final String title;
      final String body;
      final Color badgeBg;
      final Color badgeIcon;
      const _FeatureCard({
        required this.icon,
        required this.title,
        required this.body,
        required this.badgeBg,
        required this.badgeIcon,
      });

      @override
      State<_FeatureCard> createState() => _FeatureCardState();
    }

    class _FeatureCardState extends State<_FeatureCard> {
      bool _hovered = false;

      @override
      Widget build(BuildContext context) {
        return MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedScale(
            scale: _hovered ? 1.02 : 1.0,
            duration: const Duration(milliseconds: 160),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: _Palette.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: _hovered ? AppColors.gold : _Palette.cardBorder,
                    width: _hovered ? 1.4 : 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                        color: widget.badgeBg, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Icon(widget.icon, color: widget.badgeIcon, size: 22),
                  ),
                  const SizedBox(height: 16),
                  Text(widget.title,
                      style: AppText.sectionTitle(
                          size: 15.5, color: _Palette.white)),
                  const SizedBox(height: 8),
                  Text(widget.body,
                      style: AppText.bodyText(
                          size: 13, height: 1.5, color: _Palette.lightGray)),
                ],
              ),
            ),
          ),
        );
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
                  boxShadow: AppColors.softCardShadow,
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
            Text('ABOUT US', style: _Fonts.sectionLabel(color: _Palette.cyan)),
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
              Text('WHO WE ARE',
                  style: _Fonts.sectionLabel(color: _Palette.cyan)),
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
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: _Palette.cardBorder),
                                boxShadow: AppColors.softCardShadow,
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
              boxShadow: AppColors.softCardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      shape: BoxShape.circle),
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

        const commonFeatures = [
          'Unlimited time',
          'Free Coach',
          'Free Drinking Water',
          'Clean Facility & Toilets',
        ];
        final plans = [
          _PlanCard(
            name: '4 Months',
            price: '₱2,400',
            badge: null,
            features: commonFeatures,
            onGetStarted: widget.onGetStarted,
          ),
          _PlanCard(
            name: '5 Months',
            price: '₱2,800',
            badge: null,
            features: commonFeatures,
            onGetStarted: widget.onGetStarted,
          ),
          _PlanCard(
            name: '7 Months',
            price: '₱3,500',
            badge: 'MOST POPULAR',
            recommended: true,
            features: commonFeatures,
            onGetStarted: widget.onGetStarted,
          ),
          _PlanCard(
            name: '1 Year',
            price: '₱4,800',
            badge: 'BEST VALUE',
            features: commonFeatures,
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
              Text('PLANS & PRICING',
                  style: _Fonts.sectionLabel(color: _Palette.cyan)),
              const SizedBox(height: 10),
              Text('Membership subscriptions',
                  style: AppText.pageTitle(size: 34), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                  'Choose the plan that fits your goals. All plans include full gym access — upgrade any time.',
                  style: AppText.bodyText(
                      size: 14, color: _Palette.lightGray, height: 1.6),
                  textAlign: TextAlign.center),
              const SizedBox(height: 44),
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
      final List<String> features;
      final VoidCallback onGetStarted;

      /// The one visually-highlighted plan: gold border + a floating
      /// "Recommended" pill + a solid gold CTA.
      final bool recommended;

      const _PlanCard({
        required this.name,
        required this.price,
        required this.badge,
        required this.features,
        required this.onGetStarted,
        this.recommended = false,
      });

      @override
      State<_PlanCard> createState() => _PlanCardState();
    }

    class _PlanCardState extends State<_PlanCard> {
      bool _hovered = false;

      @override
      Widget build(BuildContext context) {
        final rec = widget.recommended;
        final borderColor = rec
            ? AppColors.gold
            : (_hovered ? AppColors.gold : _Palette.cardBorder);

        return MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            // Tapping the card opens the plan-details popup; the CTA button
            // below consumes its own tap.
            onTap: () => showDialog(
              context: context,
              builder: (_) => _PlanDetailsDialog(
                name: widget.name,
                price: widget.price,
                badge: widget.badge,
                features: widget.features,
              ),
            ),
            child: AnimatedScale(
              scale: _hovered ? 1.02 : 1.0,
              duration: const Duration(milliseconds: 180),
              child: Container(
                margin: EdgeInsets.only(top: rec ? 14 : 0),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                      decoration: BoxDecoration(
                        color: _Palette.bgCard,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: borderColor, width: rec ? 1.6 : 1.2),
                        boxShadow: AppColors.softCardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(widget.name,
                                    style: AppText.sectionTitle(
                                        size: 15.5, color: _Palette.white)),
                              ),
                              if (widget.badge != null && !rec)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 9, vertical: 3),
                                  decoration: BoxDecoration(
                                      color: AppColors.cyanTint,
                                      borderRadius: BorderRadius.circular(999)),
                                  child: Text(widget.badge!,
                                      style: AppText.badgeLabel(
                                          size: 9.5,
                                          color: const Color(0xFF0E7490))),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(widget.price,
                                  style: AppText.pageTitle(size: 30)),
                              const SizedBox(width: 6),
                              Text('/ ${widget.name.toLowerCase()}',
                                  style: AppText.bodySmall(
                                      color: _Palette.lightGray)),
                            ],
                          ),
                          const SizedBox(height: 18),
                          ...widget.features.map((f) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 5),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.check_circle,
                                        color: AppColors.gold, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text(f,
                                            style: AppText.bodyText(
                                                size: 13,
                                                color: _Palette.lightGray))),
                                  ],
                                ),
                              )),
                          const SizedBox(height: 20),
                          PillButton(
                            'Get Started',
                            expand: true,
                            variant: rec
                                ? PillVariant.primary
                                : PillVariant.outline,
                            onPressed: widget.onGetStarted,
                          ),
                        ],
                      ),
                    ),
                    if (rec)
                      Positioned(
                        top: -14,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: const BoxDecoration(
                              color: AppColors.gold,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(999)),
                            ),
                            child: Text('RECOMMENDED',
                                style: AppText.badgeLabel(
                                    size: 10,
                                    color: AppColors.onGold,
                                    weight: FontWeight.w800)),
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
      final List<String> features;

      static const _accent = AppColors.gold;

      const _PlanDetailsDialog({
        required this.name,
        required this.price,
        required this.badge,
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
                boxShadow: AppColors.softCardShadow,
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
                                    color: _accent,
                                    borderRadius: BorderRadius.circular(999)),
                                child: Text(badge!,
                                    style: AppText.badgeLabel(
                                        size: 10,
                                        color: AppColors.onGold,
                                        weight: FontWeight.w800)),
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
                    Text(name, style: AppText.sectionTitle(size: 18, color: _Palette.white)),
                    const SizedBox(height: 6),
                    Text(price, style: AppText.pageTitle(size: 32)),
                    const SizedBox(height: 18),
                    ...features.map((f) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle,
                                  color: AppColors.gold, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(f,
                                      style: AppText.bodyText(
                                          size: 13.5,
                                          color: _Palette.lightGray))),
                            ],
                          ),
                        )),
                    const SizedBox(height: 24),
                    Text('PAYMENT METHOD',
                        style: _Fonts.sectionLabel(color: _Palette.cyan)),
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
            color: _Palette.bgDarkGraySection,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _Palette.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppColors.cyanTint,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(option.icon,
                    color: const Color(0xFF0E7490), size: 20),
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
        final bp = _breakpointOf(context);
        // Tablet keeps the two-column structure (tighter spacing); only
        // mobile stacks the image above the info panel.
        final isRow = bp != _Breakpoint.mobile;
        final isDesktop = bp == _Breakpoint.desktop;

        void openInMaps() => _launchUri(Uri.parse(
              'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(_primeFitAddress)}',
            ));
        void openDirections() => _launchUri(Uri.parse(
              'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(_primeFitAddress)}',
            ));

        // ---- LEFT: dominant image + gradient + athletic statement -------
        // A fixed height (never IntrinsicHeight/stretch-to-match-content —
        // that was blowing the whole card's height up to the image's
        // unpredictable intrinsic size and pushing the map down) so the
        // right column is free to size itself to its own compact content.
        final imageColumn = ClipRRect(
          borderRadius: isRow
              ? const BorderRadius.horizontal(left: Radius.circular(24))
              : const BorderRadius.vertical(top: Radius.circular(24)),
          child: SizedBox(
            height: isRow ? (isDesktop ? 580.0 : 520.0) : 220.0,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/about_gym.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: _Palette.bgDeepBlack),
                ),
                // Subtle dark gradient so the statement stays legible.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xCC000000)],
                      stops: [0.4, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  left: 22,
                  right: 22,
                  bottom: 22,
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.archivoBlack(
                          fontSize: isDesktop ? 24 : 20,
                          height: 1.2,
                          letterSpacing: -0.3),
                      children: const [
                        TextSpan(
                            text: 'TRAIN HARD.\n', style: TextStyle(color: Colors.white)),
                        TextSpan(
                            text: 'LIVE STRONG.',
                            style: TextStyle(color: _Palette.yellow)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        // ---- RIGHT: heading + 2x2 contact grid + divider + map + CTA ----
        final infoTiles = [
          _infoTile(Icons.location_on_outlined, 'LOCATION', _primeFitAddress,
              _Palette.cyan,
              onTap: openInMaps),
          _infoTile(Icons.call_outlined, 'PHONE', '+63 917 847 8351',
              _Palette.yellow,
              onTap: () => _launchUri(Uri.parse('tel:+639178478351'))),
          _infoTile(Icons.schedule_outlined, 'OPERATING HOURS',
              'Mon–Sun: 7:00 AM – 10:00 PM', _Palette.cyan),
          _infoTile(Icons.share_outlined, 'SOCIAL MEDIA', null, _Palette.yellow,
              valueChild: Row(
                children: [
                  _SocialIconLink(
                    icon: Icons.facebook_outlined,
                    onTap: () => _launchUri(Uri.parse(
                        'https://www.facebook.com/profile.php?id=61579305812618')),
                  ),
                  const SizedBox(width: 8),
                  _SocialIconLink(
                    icon: Icons.music_note_outlined,
                    onTap: () => _launchUri(
                        Uri.parse('https://www.tiktok.com/@primefit.fitness.g')),
                  ),
                ],
              )),
        ];

        final infoColumn = Padding(
          padding: EdgeInsets.all(isDesktop ? 24 : 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Visit PrimeFit Gym',
                  style: AppText.pageTitle(size: isDesktop ? 26 : 22)),
              const SizedBox(height: 6),
              Text(
                'Find our gym, view its exact location, and get directions '
                'in seconds.',
                style: AppText.bodyText(
                    size: 13, color: _Palette.lightGray, height: 1.4),
              ),
              const SizedBox(height: 14),
              // Compact 2-column grid: Location + Phone, then Operating
              // Hours + Social — the aspect ratio hugs each tile's actual
              // content instead of leaving dead space inside it.
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 10,
                childAspectRatio: isDesktop ? 3.4 : 2.8,
                children: infoTiles,
              ),
              const SizedBox(height: 8),
              const Divider(color: _Palette.cardBorder, height: 1),
              const SizedBox(height: 12),
              // The existing interactive OSM map (flutter_map, no API key)
              // -- unchanged functionality, just a tighter, rounded frame,
              // directly under the contact info with only a small gap.
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: isDesktop ? 250 : 220,
                  width: double.infinity,
                  child: Stack(
                    children: [
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
                                height: 68,
                                alignment: Alignment.topCenter,
                                child: IgnorePointer(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.location_on,
                                          color: _Palette.yellow, size: 34),
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 9, vertical: 3),
                                        decoration: BoxDecoration(
                                            color: Colors.black
                                                .withValues(alpha: 0.75),
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        child: const Text('Taguig',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
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
                      // Thin border on top of the map so it reads as
                      // "framed", matching the rest of the card.
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _Palette.cardBorder),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Use the map above to view our exact location and nearby streets.',
                style: AppText.bodySmall(color: _Palette.mutedGray),
              ),
              const SizedBox(height: 6),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: openDirections,
                  borderRadius: BorderRadius.circular(6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Open in Google Maps',
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _Palette.cyan)),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward,
                          size: 16, color: _Palette.cyan),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

        final card = Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: _Palette.bgCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _Palette.cardBorder),
            boxShadow: AppColors.softCardShadow,
          ),
          clipBehavior: Clip.antiAlias,
          // No IntrinsicHeight/stretch here on purpose: that combo forced
          // the row's height to the image's unpredictable intrinsic size,
          // ballooning the card and pushing the map down. The image column
          // now carries its own fixed height, and the info column sizes to
          // its own (compact) content via CrossAxisAlignment.start.
          child: isRow
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: imageColumn),
                    Expanded(flex: 6, child: infoColumn),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [imageColumn, infoColumn],
                ),
        );

        return Container(
          width: double.infinity,
          color: _Palette.bgDarkSection,
          padding: _sectionPadding(context),
          child: Column(
            children: [
              Text('FIND US', style: _Fonts.sectionLabel(color: _Palette.cyan)),
              const SizedBox(height: 10),
              Text('PrimeFit location',
                  style: AppText.pageTitle(size: 34),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text("Come visit us at our Taguig City gym — we're open every day.",
                  style: AppText.bodyText(
                      size: 14, color: _Palette.lightGray, height: 1.6),
                  textAlign: TextAlign.center),
              const SizedBox(height: 44),
              card,
            ],
          ),
        ).animate().fade(duration: 500.ms).slideY(begin: 0.2);
      }

      Widget _infoTile(
          IconData icon, String label, String? value, Color accent,
          {VoidCallback? onTap, Widget? valueChild}) {
        final content = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(9)),
              alignment: Alignment.center,
              child: Icon(icon, color: accent, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: _Fonts.sectionLabel(color: _Palette.mutedGray)
                          .copyWith(fontSize: 10.5)),
                  const SizedBox(height: 3),
                  if (valueChild != null)
                    valueChild
                  else
                    Text(
                      value ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: onTap != null ? _Palette.cyan : _Palette.offWhite,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
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

    /// A small round tap target for a social-media link inside the
    /// location card's "SOCIAL MEDIA" tile.
    class _SocialIconLink extends StatelessWidget {
      final IconData icon;
      final VoidCallback onTap;
      const _SocialIconLink({required this.icon, required this.onTap});

      @override
      Widget build(BuildContext context) {
        return Material(
          color: _Palette.cardBorder,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: Icon(icon, size: 15, color: _Palette.white),
            ),
          ),
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
                  style: _Fonts.sectionLabel(color: _Palette.cyan)),
              const SizedBox(height: 10),
              Text('Merch & apparel',
                  style: AppText.pageTitle(size: 34),
                  textAlign: TextAlign.center),
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
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _Palette.cardBorder),
              boxShadow: AppColors.softCardShadow,
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
                    color: const Color(0xFF23262C),
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
                    style: AppText.pageTitle(size: 22, color: _Palette.yellow)),
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
                boxShadow: AppColors.softCardShadow,
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
                        color: const Color(0xFF23262C),
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
    /// RESULTS / MEMBER TRANSFORMATIONS   (new section)
    /// ---------------------------------------------------------------------
    /// Placeholder content — swap the quotes/names and add real member
    /// photos (see `_photo`) once available.
    class _ResultsSection extends StatelessWidget {
      const _ResultsSection();

      static const _results = [
        (
          'Jamie R.',
          'Down 12 kg and finally training pain-free. The coaches actually check in on you.',
          ['-12 kg', '6 months', '★ 4.9'],
          AppColors.cyan,
        ),
        (
          'Marco D.',
          'Went from never lifting to a 100 kg deadlift. Best decision I made this year.',
          ['+18 kg lift', '4 months', '★ 5.0'],
          AppColors.gold,
        ),
        (
          'Alyssa T.',
          'The community keeps me coming back. I look forward to my sessions now.',
          ['-8 kg', '3 months', '★ 4.8'],
          AppColors.cyan,
        ),
      ];

      @override
      Widget build(BuildContext context) {
        final w = MediaQuery.of(context).size.width;
        final cols = w < 720 ? 1 : 3;
        return LandingSection(
          eyebrow: 'Real results',
          title: 'Members who put in the work',
          subtitle:
              'A few of the people training with us right now. Your story could '
              'be next.',
          eyebrowColor: _Palette.cyan,
          background: _Palette.bgDarkSection,
          child: GridView.count(
            crossAxisCount: cols,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: cols == 1 ? 1.7 : 0.82,
            children: [
              for (final r in _results)
                _HoverScale(
                  endScale: 1.02,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _Palette.bgCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _Palette.cardBorder),
                      boxShadow: AppColors.softCardShadow,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Member photo placeholder — a tinted band with an
                        // avatar. Replace with a real portrait Image.asset.
                        Container(
                          height: 150,
                          width: double.infinity,
                          color: (r.$4).withValues(alpha: 0.12),
                          alignment: Alignment.center,
                          child: CircleAvatar(
                            radius: 34,
                            backgroundColor: r.$4,
                            child: Text(r.$1.characters.first,
                                style: AppText.statNumber(
                                    size: 22, color: Colors.white)),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  for (final b in r.$3)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 9, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _Palette.bgDarkGraySection,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        border: Border.all(
                                            color: _Palette.cardBorder),
                                      ),
                                      child: Text(b,
                                          style: AppText.badgeLabel(
                                              size: 11,
                                              color: _Palette.white)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text('"${r.$2}"',
                                  style: AppText.bodyText(
                                      size: 13.5,
                                      height: 1.5,
                                      color: _Palette.lightGray)),
                              const SizedBox(height: 10),
                              Text(r.$1,
                                  style: AppText.sectionTitle(
                                      size: 14, color: _Palette.white)),
                            ],
                          ),
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

    /// ---------------------------------------------------------------------
    /// GALLERY — "Step inside the gym"   (new section)
    /// ---------------------------------------------------------------------
    /// Images come from `assets/images/gallery/` via [GalleryImages] — see
    /// that file to add photos. Layout/sizing/hover unchanged; only the
    /// image source moved out of this widget.
    class _GallerySection extends StatelessWidget {
      const _GallerySection();

      @override
      Widget build(BuildContext context) {
        final w = MediaQuery.of(context).size.width;
        final cols = w < 640 ? 2 : (w < 1024 ? 3 : 3);
        return LandingSection(
          eyebrow: 'Step inside the gym',
          title: 'Where it all happens',
          eyebrowColor: AppColors.cyan,
          background: _Palette.bgNearBlack,
          child: FutureBuilder<List<String>>(
            future: GalleryImages.load(),
            initialData: GalleryImages.fallback,
            builder: (context, snapshot) {
              final shots = snapshot.data ?? GalleryImages.fallback;
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.35,
                children: [
                  for (int i = 0; i < shots.length; i++)
                    _HoverScale(
                      endScale: 1.03,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: _Palette.cardBorder),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(
                            shots[i],
                            fit: BoxFit.cover,
                            alignment: i.isEven
                                ? Alignment.center
                                : Alignment.topCenter,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.cyanTint,
                              alignment: Alignment.center,
                              child: const Icon(Icons.photo_outlined,
                                  color: Color(0xFF0E7490), size: 32),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      }
    }

    /// ---------------------------------------------------------------------
    /// FINAL CTA BAND   (new)
    /// ---------------------------------------------------------------------
    class _CtaBand extends StatelessWidget {
      final VoidCallback onJoin;
      final VoidCallback onViewPlans;
      const _CtaBand({required this.onJoin, required this.onViewPlans});

      @override
      Widget build(BuildContext context) {
        final w = MediaQuery.of(context).size.width;
        return Container(
          width: double.infinity,
          color: AppColors.gold,
          padding: EdgeInsets.symmetric(
              horizontal: w < 600 ? 20 : 48, vertical: w < 600 ? 48 : 72),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                children: [
                  Text('Ready to start training?',
                      textAlign: TextAlign.center,
                      style: AppText.pageTitle(
                          size: w < 600 ? 26 : 36, color: AppColors.dark)),
                  const SizedBox(height: 12),
                  Text(
                    'Join PrimeFit today — no joining fee, cancel anytime.',
                    textAlign: TextAlign.center,
                    style: AppText.bodyText(
                        size: 15,
                        color: AppColors.dark.withValues(alpha: 0.8)),
                  ),
                  const SizedBox(height: 26),
                  Wrap(
                    spacing: 14,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      PillButton('JOIN NOW',
                          onPressed: onJoin, variant: PillVariant.dark),
                      PillButton('VIEW PLANS',
                          onPressed: onViewPlans,
                          variant: PillVariant.darkOutline),
                    ],
                  ),
                ],
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
          color: _Palette.bgNearBlack,
          padding: _sectionPadding(context),
          child: Column(
            children: [
              Text('GET IN TOUCH',
                  style: _Fonts.sectionLabel(color: _Palette.cyan)),
              const SizedBox(height: 12),
              Text('Contact PrimeFit', style: AppText.pageTitle(size: 34)),
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
            boxShadow: AppColors.softCardShadow,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: item.accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
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
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
            decoration: BoxDecoration(
              // Gold-tinted charcoal + a thicker gold left accent bar, so
              // this pull-strip carries the gold treatment.
              color: Color.alphaBlend(
                  AppColors.gold.withValues(alpha: 0.06), _Palette.bgCard),
              borderRadius: BorderRadius.circular(18),
              border: const Border(
                left: BorderSide(color: AppColors.gold, width: 3),
                top: BorderSide(color: Color(0x33F2B705)),
                right: BorderSide(color: Color(0x33F2B705)),
                bottom: BorderSide(color: Color(0x33F2B705)),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.schedule,
                          color: _Palette.yellow, size: 18),
                    ),
                    const SizedBox(width: 10),
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
            // Subtle cyan→gold accent divider between the page and the footer.
            Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [AppColors.cyan, AppColors.gold]),
              ),
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
            Text('QUICK LINKS', style: _Fonts.sectionLabel(color: _Palette.cyan)),
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
            Text('VISIT US', style: _Fonts.sectionLabel(color: _Palette.cyan)),
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
            Text('FOLLOW ALONG', style: _Fonts.sectionLabel(color: _Palette.cyan)),
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
