import 'dart:ui' show ImageFilter;
import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderAbstractViewport;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' hide Path;
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/pill_button.dart';
import '../widgets/prime_fit_logo.dart';
import '../widgets/reviews_section.dart';
import '../widgets/support_widget.dart';
import '../data/gallery_images.dart';
import 'login_page.dart';
import 'create_account.dart';

/// The landing page's colour tokens. The public site runs on a **dark**
/// theme (near-black page, dark-charcoal cards) skinned with PrimeFit's own
/// cyan / gold accents -- surface/text values reuse the app theme's
/// existing dark-mode tokens ([AppColors.darkBg] etc).
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

  /// Text colour used on top of gold / gradient fills.
  static const ink = Color(0xFF0A0A0B);
}

/// Centralized typography -- Archivo Black for big display headings,
/// Barlow for everything else (labels, body, nav, buttons).
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
        letterSpacing: -0.3,
      );

  // Section labels -- "ABOUT US", "FIND US", etc.
  static TextStyle sectionLabel({Color color = _Palette.cyan}) =>
      GoogleFonts.barlow(
        fontSize: 12.5,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: 3,
      );

  // Body copy
  static TextStyle body({
    double size = 15,
    Color color = _Palette.lightGray,
    double height = 1.6,
    FontWeight weight = FontWeight.w400,
  }) =>
      GoogleFonts.barlow(
          fontSize: size, color: color, height: height, fontWeight: weight);

  // Nav links
  static TextStyle nav({required Color color}) => GoogleFonts.barlow(
      fontSize: 15, fontWeight: FontWeight.w600, color: color);

  // Buttons -- bold/extrabold, uppercase
  static TextStyle button({double size = 14, Color color = Colors.black}) =>
      GoogleFonts.barlow(
          fontSize: size,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.8);

  // Card / smaller headings (feature titles, plan names, item names)
  static TextStyle heading({
    required double size,
    Color color = _Palette.white,
    FontWeight weight = FontWeight.w800,
  }) =>
      GoogleFonts.barlow(
          fontSize: size, fontWeight: weight, color: color, letterSpacing: 0.3);
}

const double _kNavBarHeight = 76;

/// Max width of the page content (sections, nav, hero).
const double _kContentMaxWidth = 1200;

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

/// Shared padding for the big content sections so they scale together per
/// breakpoint.
EdgeInsets _sectionPadding(BuildContext context) {
  switch (_breakpointOf(context)) {
    case _Breakpoint.mobile:
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 56);
    case _Breakpoint.tablet:
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 72);
    case _Breakpoint.desktop:
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 88);
  }
}

const String _primeFitAddress =
    '31 Bernardo St, near Army Road, Central Signal, Taguig, Metro Manila, Philippines 1633';

// Exact pin from the gym's own Google Maps listing ("PrimeFitness Gym",
// maps.app.goo.gl/YXrmeeEUzvrTppFE7) -- "Get Directions" and the marker
// both use this.
const LatLng _primeFitLatLng = LatLng(14.5088248, 121.0566839);

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
/// section just *below* the overlaid nav bar instead of behind it.
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

void _scrollToTop() {
  if (!_pageScroll.hasClients) return;
  _pageScroll.animateTo(0,
      duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
}

Future<void> _launchUri(Uri uri) async {
  try {
    await launchUrl(uri);
  } catch (_) {}
}

/// Sections other pages (Sign In, Create Account) can jump to.
enum LandingPageSection { about, mission, membership, merchandise, contact }

/// Opens the landing page, optionally scrolled to [section]. Used by the
/// footer links on the Sign In and Create Account pages.
void goToLandingSection(BuildContext context, [LandingPageSection? section]) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => LandingPage(initialSection: section)),
    (route) => false,
  );
}

/// Invisible helper: once the landing page has built, scrolls to [section].
class _ScrollOnLoad extends StatefulWidget {
  final LandingPageSection? section;
  const _ScrollOnLoad(this.section);

  @override
  State<_ScrollOnLoad> createState() => _ScrollOnLoadState();
}

class _ScrollOnLoadState extends State<_ScrollOnLoad> {
  @override
  void initState() {
    super.initState();
    final s = widget.section;
    if (s == null) return;
    // Wait for the route transition, layout and the sections' fade/slide-in
    // animations to finish before measuring and scrolling.
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      _scrollToKey(switch (s) {
        LandingPageSection.about => _aboutKey,
        LandingPageSection.mission => _missionKey,
        LandingPageSection.membership => _pricingKey,
        LandingPageSection.merchandise => _merchKey,
        LandingPageSection.contact => _contactKey,
      });
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class LandingPage extends StatelessWidget {
  /// When set, the page scrolls to this section right after it opens.
  final LandingPageSection? initialSection;
  const LandingPage({super.key, this.initialSection});

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

  void _scrollToHome(BuildContext context) => _scrollToTop();
  void _scrollToAbout(BuildContext context) => _scrollToKey(_aboutKey);
  void _scrollToMission(BuildContext context) => _scrollToKey(_missionKey);
  void _scrollToMembership(BuildContext context) => _scrollToKey(_pricingKey);
  void _scrollToMerch(BuildContext context) => _scrollToKey(_merchKey);
  void _scrollToContact(BuildContext context) => _scrollToKey(_contactKey);

  @override
  Widget build(BuildContext context) {
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
          onHome: () => _scrollToHome(context),
          onAbout: () => _scrollToAbout(context),
          onMission: () => _scrollToMission(context),
          onMembership: () => _scrollToMembership(context),
          onMerchandise: () => _scrollToMerch(context),
          onContact: () => _scrollToContact(context),
        ),
        // The nav bar is overlaid on top of the scroll view (not stacked
        // above it) so page content slides *under* it.
        body: Stack(
          children: [
            // Scrolls to [initialSection] after the page opens (no-op when
            // the page is opened normally).
            Positioned(left: 0, top: 0, child: _ScrollOnLoad(initialSection)),
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
                    const _ResultsSection(),
                    const _GallerySection(),
                    ReviewsSection(onSignIn: () => _goToLogin(context)),
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
                onHome: () => _scrollToHome(context),
                onAbout: () => _scrollToAbout(context),
                onMission: () => _scrollToMission(context),
                onMembership: () => _scrollToMembership(context),
                onMerchandise: () => _scrollToMerch(context),
                onContact: () => _scrollToContact(context),
              ),
            ),
            // Floating support button + panel (Chat + FAQ).
            const Positioned(
              right: 24,
              bottom: 24,
              child: SupportWidget(),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// SHARED LAYOUT HELPERS
/// ---------------------------------------------------------------------

/// Full-width section background with the content centred and capped at
/// [_kContentMaxWidth].
class _SectionShell extends StatelessWidget {
  final Color background;
  final Widget child;
  final EdgeInsets? padding;
  const _SectionShell({
    required this.background,
    required this.child,
  }) : padding = null;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: background,
      padding: padding ?? _sectionPadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _kContentMaxWidth),
          child: child,
        ),
      ),
    );
  }
}

/// Centered cyan eyebrow + big uppercase display title (+ optional
/// subtitle) shared by every section.
class _SectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;
  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final bp = _breakpointOf(context);
    final titleSize = switch (bp) {
      _Breakpoint.mobile => 26.0,
      _Breakpoint.tablet => 32.0,
      _Breakpoint.desktop => 38.0,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 44),
      child: Column(
        children: [
          Text(eyebrow.toUpperCase(),
              textAlign: TextAlign.center,
              style: _Fonts.sectionLabel(color: _Palette.cyan)),
          const SizedBox(height: 12),
          Text(title.toUpperCase(),
              textAlign: TextAlign.center,
              style: _Fonts.display(size: titleSize, height: 1.15)),
          if (subtitle != null) ...[
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: _Fonts.body(size: 14.5, color: _Palette.lightGray)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Equal-height card grid: lays [children] out [columns] per row. Cells in
/// the last row that have no card stay empty so widths line up.
class _CardGrid extends StatelessWidget {
  final int columns;
  final double gap;
  final List<Widget> children;
  const _CardGrid({
    required this.columns,
    required this.children,
    this.gap = 20,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (int i = 0; i < children.length; i += columns) {
      final end = i + columns > children.length ? children.length : i + columns;
      final chunk = children.sublist(i, end);
      if (rows.isNotEmpty) rows.add(SizedBox(height: gap));
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int j = 0; j < columns; j++) ...[
              if (j > 0) SizedBox(width: gap),
              Expanded(
                  child: j < chunk.length ? chunk[j] : const SizedBox.shrink()),
            ],
          ],
        ),
      ));
    }
    return Column(children: rows);
  }
}

/// Gold-outlined rounded-square icon badge used on feature / mission /
/// contact cards.
class _OutlineIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const _OutlineIcon(
      {required this.icon, this.color = _Palette.yellow, this.size = 46});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.3),
        color: color.withValues(alpha: 0.06),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: size * 0.46),
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
/// NAV BAR (fixed/sticky)
/// ---------------------------------------------------------------------
class _NavLogo extends StatelessWidget {
  final double size;
  final double fontSize;
  const _NavLogo({this.size = 42, this.fontSize = 21});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _Palette.yellow, width: 1.5),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/primefit_logo.jpg',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 10),
        RichText(
          text: TextSpan(
            style:
                GoogleFonts.barlow(fontSize: fontSize, fontWeight: FontWeight.w800),
            children: const [
              TextSpan(text: 'Prime', style: TextStyle(color: _Palette.cyan)),
              TextSpan(text: 'Fit', style: TextStyle(color: _Palette.yellow)),
            ],
          ),
        ),
      ],
    );
  }
}

class _NavBar extends StatelessWidget {
  final VoidCallback onSignIn;
  final VoidCallback onJoin;
  final VoidCallback onHome;
  final VoidCallback onAbout;
  final VoidCallback onMission;
  final VoidCallback onMembership;
  final VoidCallback onMerchandise;
  final VoidCallback onContact;
  const _NavBar({
    required this.onSignIn,
    required this.onJoin,
    required this.onHome,
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
    final horizontalPadding = bp == _Breakpoint.mobile ? 16.0 : 24.0;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          height: _kNavBarHeight,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          decoration: BoxDecoration(
            color: _Palette.bgDeepBlack.withValues(alpha: 0.86),
            border: Border(
                bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08), width: 1)),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _kContentMaxWidth),
              child: Row(
                children: [
                  // Logo + wordmark (left)
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _NavLogo(
                          size: bp == _Breakpoint.mobile ? 36 : 42,
                          fontSize: bp == _Breakpoint.mobile ? 18 : 21),
                    ),
                  ),
                  // Nav links (centre) -- "Home" is gold while the page is
                  // scrolled near the top.
                  if (isWide)
                    AnimatedBuilder(
                      animation: _pageScroll,
                      builder: (context, _) {
                        final atTop =
                            !_pageScroll.hasClients || _pageScroll.offset < 320;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _NavLink('Home', onTap: onHome, active: atTop),
                            _NavLink('About', onTap: onAbout),
                            _NavLink('Mission', onTap: onMission),
                            _NavLink('Membership', onTap: onMembership),
                            _NavLink('Merchandise', onTap: onMerchandise),
                            _NavLink('Contact', onTap: onContact),
                          ],
                        );
                      },
                    ),
                  // Sign In + Join Now (right) on desktop; hamburger menu
                  // (which holds the nav links + Sign In) + Join Now on
                  // phone/tablet.
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isWide) ...[
                            TextButton(
                              onPressed: onSignIn,
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.white),
                              child: Text('SIGN IN',
                                  style: _Fonts.button(color: Colors.white)),
                            ),
                            const SizedBox(width: 12),
                          ],
                          ElevatedButton(
                            onPressed: onJoin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _Palette.yellow,
                              foregroundColor: AppColors.onGold,
                              padding: EdgeInsets.symmetric(
                                  horizontal: isWide ? 24 : 16, vertical: 14),
                              shape: const StadiumBorder(),
                              elevation: 0,
                            ),
                            child: Text('JOIN NOW',
                                style: _Fonts.button(size: 13.5)),
                          ),
                          if (!isWide) ...[
                            const SizedBox(width: 6),
                            Builder(
                              builder: (context) => IconButton(
                                onPressed: () =>
                                    Scaffold.of(context).openEndDrawer(),
                                icon: const Icon(Icons.menu,
                                    color: _Palette.white),
                                tooltip: 'Menu',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
  final VoidCallback onHome;
  final VoidCallback onAbout;
  final VoidCallback onMission;
  final VoidCallback onMembership;
  final VoidCallback onMerchandise;
  final VoidCallback onContact;
  const _MobileNavDrawer({
    required this.onSignIn,
    required this.onJoin,
    required this.onHome,
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _NavLogo(size: 34, fontSize: 17),
              ),
            ),
            const Divider(color: _Palette.cardBorder),
            link('Home', onHome),
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
  final bool active;
  const _NavLink(this.label, {this.onTap, this.active = false});

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.active
        ? _Palette.yellow
        : (_hovered
            ? _Palette.offWhite
            : _Palette.white.withValues(alpha: 0.78));
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 150),
              style: _Fonts.nav(color: color),
              child: Text(widget.label),
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// HERO -- text on the left, framed gym photo with rating badge on the right
/// ---------------------------------------------------------------------
class _HeroSection extends StatelessWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onViewPlans;
  const _HeroSection({required this.onGetStarted, required this.onViewPlans});

  @override
  Widget build(BuildContext context) {
    final bp = _breakpointOf(context);
    final isDesktop = bp == _Breakpoint.desktop;
    final displaySize = switch (bp) {
      _Breakpoint.mobile => 46.0,
      _Breakpoint.tablet => 66.0,
      _Breakpoint.desktop => 84.0,
    };
    final subheadSize = switch (bp) {
      _Breakpoint.mobile => 19.0,
      _Breakpoint.tablet => 22.0,
      _Breakpoint.desktop => 24.0,
    };
    final bodySize = bp == _Breakpoint.mobile ? 15.0 : 16.5;

    // "ALL." -- gold -> cyan gradient fill. ShaderMask + srcIn recolors the
    // glyphs using the white text as the alpha mask (no text shadow on
    // purpose -- a shadow would be recolored into a blurry glow).
    final gradientAll = ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [_Palette.yellow, _Palette.cyan],
      ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: Text('ALL.',
          style: _Fonts.display(
              size: displaySize, color: Colors.white, height: 1.0)),
    );

    final textColumn = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tag row: gold "THE BEST" chip + location label
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _Palette.yellow,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text('THE BEST',
                  style: GoogleFonts.barlow(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppColors.onGold)),
            ),
            Text('FITNESS GYM · TAGUIG CITY',
                style: GoogleFonts.barlow(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: Colors.white)),
          ],
        ).animate().fade(delay: 200.ms).slideX(begin: -0.3),
        const SizedBox(height: 22),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FIT FOR',
                style: _Fonts.display(
                    size: displaySize, color: Colors.white, height: 1.0)),
            gradientAll,
          ],
        ).animate().fade(delay: 320.ms).slideX(begin: -0.3),
        const SizedBox(height: 20),
        Text('Where your fitness journey begins.',
            style: GoogleFonts.barlow(
                fontSize: subheadSize,
                fontWeight: FontWeight.w700,
                color: _Palette.cyan)),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            'PrimeFit Fitness Gym is your complete training destination — '
            'equipped, supportive, and built for every level of athlete.',
            style: _Fonts.body(
                size: bodySize, color: _Palette.lightGray, height: 1.65),
          ),
        ),
        const SizedBox(height: 30),
        Wrap(
          spacing: 14,
          runSpacing: 12,
          children: [
            PillButton('GET STARTED', onPressed: onGetStarted),
            PillButton('VIEW PLANS',
                onPressed: onViewPlans, variant: PillVariant.ghost),
          ],
        ).animate().fade(delay: 560.ms).slideY(begin: 0.3),
      ],
    );

    final photo = _HeroPhotoFrame(compact: !isDesktop)
        .animate()
        .fade(delay: 420.ms, duration: 600.ms)
        .slideX(begin: 0.1);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _Palette.bgNearBlack,
        // Soft gold glow in the top-right behind the photo frame.
        gradient: RadialGradient(
          center: const Alignment(0.75, -0.55),
          radius: 0.85,
          colors: [
            _Palette.yellow.withValues(alpha: 0.11),
            _Palette.bgNearBlack,
          ],
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        bp == _Breakpoint.mobile ? 20 : 24,
        _kNavBarHeight + (isDesktop ? 56 : 36),
        bp == _Breakpoint.mobile ? 20 : 24,
        isDesktop ? 88 : 56,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _kContentMaxWidth),
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 6, child: textColumn),
                    const SizedBox(width: 56),
                    Expanded(flex: 5, child: photo),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    textColumn,
                    const SizedBox(height: 44),
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: photo,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Rounded, gold-outlined photo frame (big curve on the bottom-left) with a
/// floating "4.9 · Loved by our members" badge.
class _HeroPhotoFrame extends StatelessWidget {
  final bool compact;
  const _HeroPhotoFrame({required this.compact});

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.only(
      topLeft: Radius.circular(32),
      topRight: Radius.circular(32),
      bottomRight: Radius.circular(32),
      bottomLeft: Radius.circular(120),
    );

    return AspectRatio(
      aspectRatio: 1.02,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: _Palette.bgCard,
                borderRadius: radius,
                boxShadow: [
                  BoxShadow(
                      color: _Palette.yellow.withValues(alpha: 0.12),
                      blurRadius: 60),
                ],
              ),
              // Painted on top of the photo so the gold outline isn't
              // covered by the image.
              foregroundDecoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: _Palette.yellow, width: 1.6),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/hero_bg.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_Palette.bgDarkGraySection, _Palette.bgCard],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.fitness_center,
                      size: 80, color: _Palette.cyan.withValues(alpha: 0.3)),
                ),
              ),
            ),
          ),
          Positioned(
            left: compact ? -8 : -26,
            bottom: 28,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: _Palette.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _Palette.cardBorder),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 6)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('4.9',
                      style: _Fonts.display(size: 30, color: _Palette.yellow)),
                  const SizedBox(width: 10),
                  Text('Loved by\nour members',
                      style: _Fonts.body(
                          size: 12.5, color: _Palette.lightGray, height: 1.3)),
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
/// STATS BAR -- solid gold strip
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
      color: _Palette.yellow,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _kContentMaxWidth),
          child: Wrap(
            alignment: WrapAlignment.spaceEvenly,
            spacing: 24,
            runSpacing: 22,
            children: stats
                .map((s) => SizedBox(
                      width: 190,
                      child: Column(
                        children: [
                          Text(s[0],
                              style: _Fonts.display(
                                  size: 28, color: _Palette.ink, height: 1.1)),
                          const SizedBox(height: 4),
                          Text(s[1],
                              style: GoogleFonts.barlow(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _Palette.ink)),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
      ),
    ).animate().fade(duration: 500.ms);
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
    ),
    (
      Icons.person_outline,
      'Expert staff',
      'Certified and experienced trainers to guide members.',
    ),
    (
      Icons.track_changes_outlined,
      'Personalized plans',
      'Workout programs and plans tailored to member goals.',
    ),
    (
      Icons.groups_outlined,
      'Supportive community',
      'A positive, inclusive environment that keeps members motivated.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cols = w < 640 ? 1 : (w < 1024 ? 2 : 4);
    return _SectionShell(
      background: _Palette.bgNearBlack,
      child: Column(
        children: [
          const _SectionHeader(
            eyebrow: 'Why choose us',
            title: 'Everything you need to train',
            subtitle:
                'A complete gym built around real results — the equipment, '
                'the people, and the plans to get you there.',
          ),
          _CardGrid(
            columns: cols,
            children: [
              for (final f in _features)
                _FeatureCard(icon: f.$1, title: f.$2, body: f.$3),
            ],
          ),
        ],
      ),
    ).animate().fade(duration: 500.ms).slideY(begin: 0.12);
  }
}

/// A dark "Why choose us" card whose border warms to gold on hover.
class _FeatureCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String body;
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.body,
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: _Palette.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: _hovered
                  ? _Palette.yellow.withValues(alpha: 0.8)
                  : _Palette.cardBorder,
              width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _OutlineIcon(icon: widget.icon),
            const SizedBox(height: 20),
            Text(widget.title.toUpperCase(),
                style: _Fonts.display(size: 15.5, height: 1.2)),
            const SizedBox(height: 10),
            Text(widget.body,
                style: _Fonts.body(
                    size: 13.5, height: 1.55, color: _Palette.lightGray)),
          ],
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
        // Gold outline frame, offset up-left behind the photo.
        Positioned(
          left: -12,
          top: -12,
          right: 12,
          bottom: 12,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: _Palette.yellow, width: 1.6),
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 360,
            width: double.infinity,
            color: _Palette.bgCard,
            child: Image.asset(
              'assets/images/about_gym.jpg',
              fit: BoxFit.cover,
              // Falls back to a placeholder look if the asset is
              // missing/misnamed, instead of crashing the page.
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_Palette.bgCard, _Palette.bgDeepBlack],
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
          bottom: 16,
          right: isWide ? -10 : 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: _Palette.yellow,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('1+ YEARS',
                    style: _Fonts.display(size: 20, color: _Palette.ink)),
                const SizedBox(height: 2),
                Text('SERVING TAGUIG CITY',
                    style: GoogleFonts.barlow(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: _Palette.ink)),
              ],
            ),
          ),
        ),
      ],
    );

    final titleSize = isWide ? 36.0 : 28.0;
    final right = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ABOUT US', style: _Fonts.sectionLabel(color: _Palette.cyan)),
        const SizedBox(height: 14),
        RichText(
          text: TextSpan(
            style: _Fonts.display(size: titleSize, height: 1.15),
            children: [
              const TextSpan(text: 'MORE THAN A GYM\n— A '),
              TextSpan(
                  text: 'COMMUNITY.',
                  style: _Fonts.display(
                      size: titleSize, height: 1.15, color: _Palette.yellow)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '"Healthy Mind, Healthy Body"',
          style: GoogleFonts.barlow(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              color: _Palette.cyan),
        ),
        const SizedBox(height: 16),
        Text(
          'PrimeFit Fitness Gym is a gym and physical fitness center dedicated to '
          'helping individuals achieve a healthier mind and body, in a '
          'welcoming environment where members work toward their goals.',
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 5, child: visual),
        const SizedBox(width: 64),
        Expanded(flex: 6, child: right),
      ],
    );

    final columnContent = Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, top: 12),
          child: visual,
        ),
        const SizedBox(height: 40),
        right,
      ],
    );

    return _SectionShell(
      background: _Palette.bgDarkGraySection,
      child: isWide ? rowContent : columnContent,
    ).animate().fade(duration: 500.ms).slideY(begin: 0.12);
  }

  List<Widget> _checks(List<String> items) {
    return items
        .map((t) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                        color: _Palette.yellow, shape: BoxShape.circle),
                  ),
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
    final bp = _breakpointOf(context);
    final isWide = bp == _Breakpoint.desktop;

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
      ['INCLUSIVITY', 'Every body is welcome', _Palette.yellow],
      ['DEDICATION', 'We show up every day', _Palette.cyan],
      ['INTEGRITY', 'Honest, transparent service', _Palette.yellow],
      ['PROGRESS', 'Always improving', _Palette.cyan],
    ];

    return _SectionShell(
      background: _Palette.bgNearBlack,
      child: Column(
        children: [
          const _SectionHeader(eyebrow: 'Who we are', title: 'Mission & vision'),
          isWide
              // FIX: this Row uses CrossAxisAlignment.stretch, which needs a
              // bounded height. Inside the page's SingleChildScrollView the
              // height is infinite, so it crashed the whole layout (blank
              // screen). IntrinsicHeight gives it a finite height.
              ? const IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: missionCard),
                      SizedBox(width: 24),
                      Expanded(child: visionCard),
                    ],
                  ),
                )
              : const Column(
                  children: [missionCard, SizedBox(height: 24), visionCard]),
          const SizedBox(height: 24),
          _CardGrid(
            columns: isWide ? 4 : 2,
            gap: bp == _Breakpoint.mobile ? 12 : 20,
            children: [
              for (final v in values)
                _HoverScale(
                  endScale: 1.03,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
                    decoration: BoxDecoration(
                      color: _Palette.bgCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _Palette.cardBorder),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(v[0] as String,
                            textAlign: TextAlign.center,
                            style: _Fonts.display(
                                size: 14,
                                color: v[2] as Color,
                                height: 1.2)),
                        const SizedBox(height: 6),
                        Text(v[1] as String,
                            textAlign: TextAlign.center,
                            style: _Fonts.body(
                                size: 13, color: _Palette.mutedGray)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ).animate().fade(duration: 500.ms).slideY(begin: 0.12);
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
      endScale: 1.012,
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: 0.16),
              _Palette.bgCard,
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accent.withValues(alpha: 0.8), width: 1.3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _OutlineIcon(icon: icon, color: accent, size: 44),
            const SizedBox(height: 20),
            Text(title, style: _Fonts.display(size: 21)),
            const SizedBox(height: 14),
            Text(body,
                style: _Fonts.body(
                    size: 16, height: 1.55, color: _Palette.offWhite)),
            const SizedBox(height: 12),
            Text(sub,
                style: _Fonts.body(
                    size: 14, height: 1.55, color: _Palette.mutedGray)),
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
        badge: 'RECOMMENDED',
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

    // Desktop: 4-across Row. Mobile/tablet use a Wrap with an explicit
    // per-card width (1 column on mobile, 2 on tablet) computed from the
    // section's own content width, so cards stack/reflow instead of
    // shrinking to fit their own content.
    final Widget plansLayout;
    if (bp == _Breakpoint.desktop) {
      plansLayout = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < plans.length; i++) ...[
            if (i > 0) const SizedBox(width: 18),
            Expanded(child: plans[i]),
          ],
        ],
      );
    } else {
      final screenWidth = MediaQuery.of(context).size.width;
      final contentWidth = screenWidth - sectionPadding.horizontal;
      const spacing = 18.0;
      final columns = bp == _Breakpoint.tablet ? 2 : 1;
      final cardWidth = (contentWidth - spacing * (columns - 1)) / columns;
      plansLayout = Wrap(
        spacing: spacing,
        runSpacing: 28,
        children:
            plans.map((p) => SizedBox(width: cardWidth, child: p)).toList(),
      );
    }

    return _SectionShell(
      background: _Palette.bgDarkGraySection,
      child: Column(
        children: [
          const _SectionHeader(
              eyebrow: 'Plans & pricing', title: 'Membership subscriptions'),
          plansLayout,
          const SizedBox(height: 28),
          RichText(
            text: TextSpan(
              style: _Fonts.body(size: 14, color: _Palette.mutedGray),
              children: [
                const TextSpan(text: 'Already a member? '),
                TextSpan(
                  text: 'Sign in to your account',
                  style: GoogleFonts.barlow(
                      color: _Palette.cyan,
                      fontWeight: FontWeight.w700,
                      fontSize: 14),
                  recognizer: _signInRecognizer,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 500.ms).slideY(begin: 0.12);
  }
}

class _PlanCard extends StatefulWidget {
  final String name;
  final String price;
  final String? badge;
  final List<String> features;
  final VoidCallback onGetStarted;

  /// The one visually-highlighted plan: gold border + glow + a floating
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
        ? _Palette.yellow
        : (_hovered ? _Palette.yellow : _Palette.cardBorder);
    final baseScale = rec ? 1.04 : 1.0;

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
          scale: _hovered ? baseScale + 0.02 : baseScale,
          duration: const Duration(milliseconds: 180),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
                decoration: BoxDecoration(
                  color: rec
                      ? Color.alphaBlend(
                          _Palette.yellow.withValues(alpha: 0.08),
                          _Palette.bgCard)
                      : _Palette.bgCard,
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: borderColor, width: rec ? 1.6 : 1.1),
                  boxShadow: rec
                      ? [
                          BoxShadow(
                              color: _Palette.yellow.withValues(alpha: 0.22),
                              blurRadius: 36),
                        ]
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.name,
                        style: _Fonts.heading(
                            size: 15.5, weight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Text(widget.price,
                        style: _Fonts.display(
                            size: 32,
                            color: rec ? _Palette.yellow : _Palette.cyan)),
                    const SizedBox(height: 20),
                    ...widget.features.map((f) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 9,
                                height: 9,
                                decoration: const BoxDecoration(
                                    color: _Palette.yellow,
                                    shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                  child: Text(f,
                                      style: _Fonts.body(
                                          size: 13.5,
                                          color: _Palette.offWhite))),
                            ],
                          ),
                        )),
                    const SizedBox(height: 22),
                    PillButton(
                      'Get Started',
                      expand: true,
                      variant: rec ? PillVariant.primary : PillVariant.outline,
                      color: rec ? null : AppColors.cyan,
                      // Non-recommended cards: cyan outline that
                      // solidifies to gold on hover/press, matching
                      // the Recommended plan's already-gold button.
                      hoverFillColor: rec ? null : AppColors.gold,
                      hoverForegroundColor: rec ? null : AppColors.onGold,
                      onPressed: widget.onGetStarted,
                    ),
                  ],
                ),
              ),
              if (rec)
                Positioned(
                  top: -13,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: const BoxDecoration(
                        color: _Palette.yellow,
                        borderRadius: BorderRadius.all(Radius.circular(999)),
                      ),
                      child: Text('RECOMMENDED',
                          style: AppText.badgeLabel(
                              size: 10,
                              color: AppColors.onGold,
                              weight: FontWeight.w800)),
                    ),
                  ),
                ),
              if (widget.badge != null && !rec)
                Positioned(
                  top: -11,
                  right: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                    decoration: BoxDecoration(
                        color: _Palette.cyan,
                        borderRadius: BorderRadius.circular(999)),
                    child: Text(widget.badge!,
                        style: AppText.badgeLabel(
                            size: 9.5,
                            color: _Palette.ink,
                            weight: FontWeight.w800)),
                  ),
                ),
            ],
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
  final String qrAsset;
  const _PaymentOptionInfo(this.name, this.subtitle, this.icon, this.qrAsset);
}

// The QR images are the same ones the Create Account payment step uses.
const List<_PaymentOptionInfo> _kPlanPaymentOptions = [
  _PaymentOptionInfo('GCash', 'Mobile wallet — instant transfer',
      Icons.smartphone_outlined, 'assets/qr/gcash_qr.jpg'),
  _PaymentOptionInfo('Maya', 'Mobile wallet — e-money',
      Icons.account_balance_wallet_outlined, 'assets/qr/maya_qr.jpg'),
];

/// Shown when a member taps a plan card in the Membership Subscriptions
/// section -- a slightly bigger card with that plan's full details plus
/// the payment methods. Tapping GCash or Maya reveals that e-wallet's QR
/// code (large, on a white background so it scans reliably). UI only; no
/// payment processing here -- the account and receipt upload still happen
/// through "GET STARTED" -> create account.
class _PlanDetailsDialog extends StatefulWidget {
  final String name;
  final String price;
  final String? badge;
  final List<String> features;

  const _PlanDetailsDialog({
    required this.name,
    required this.price,
    required this.badge,
    required this.features,
  });

  @override
  State<_PlanDetailsDialog> createState() => _PlanDetailsDialogState();
}

class _PlanDetailsDialogState extends State<_PlanDetailsDialog> {
  static const _accent = AppColors.gold;

  // Which payment method's QR is currently showing (null = none).
  int? _selectedPayment;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Container(
          decoration: BoxDecoration(
            color: _Palette.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _Palette.cardBorder),
            boxShadow: AppColors.softCardShadow,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    widget.badge != null
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 11, vertical: 5),
                            decoration: BoxDecoration(
                                color: _accent,
                                borderRadius: BorderRadius.circular(999)),
                            child: Text(widget.badge!,
                                style: AppText.badgeLabel(
                                    size: 10.5,
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
                            color: _Palette.lightGray, size: 24),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(widget.name,
                    style: _Fonts.heading(size: 22, weight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(widget.price,
                    style: _Fonts.display(size: 40, color: _Palette.cyan)),
                const SizedBox(height: 20),
                ...widget.features.map((f) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 9,
                            height: 9,
                            decoration: const BoxDecoration(
                                color: _Palette.yellow, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(f,
                                  style: _Fonts.body(
                                      size: 14.5, color: _Palette.offWhite))),
                        ],
                      ),
                    )),
                const SizedBox(height: 26),
                Text('PAYMENT METHOD',
                    style: _Fonts.sectionLabel(color: _Palette.cyan)),
                const SizedBox(height: 4),
                Text('Tap GCash or Maya to show its QR code.',
                    style: _Fonts.body(size: 12.5, color: _Palette.mutedGray)),
                const SizedBox(height: 14),
                for (int i = 0; i < _kPlanPaymentOptions.length; i++) ...[
                  _paymentOptionTile(i),
                  // The selected wallet's QR panel opens right under its tile.
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    alignment: Alignment.topCenter,
                    child: _selectedPayment == i
                        ? _qrPanel(_kPlanPaymentOptions[i])
                        : const SizedBox(width: double.infinity),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _paymentOptionTile(int index) {
    final option = _kPlanPaymentOptions[index];
    final selected = _selectedPayment == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: selected
            ? _Palette.cyan.withValues(alpha: 0.08)
            : _Palette.bgDarkGraySection,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: selected ? _Palette.cyan : _Palette.cardBorder,
            width: selected ? 1.5 : 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          // Tap again to hide the QR.
          onTap: () =>
              setState(() => _selectedPayment = selected ? null : index),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _OutlineIcon(icon: option.icon, color: _Palette.cyan, size: 42),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(option.name, style: _Fonts.heading(size: 15)),
                      const SizedBox(height: 2),
                      Text(option.subtitle, style: _Fonts.body(size: 12)),
                    ],
                  ),
                ),
                Icon(
                    selected
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.qr_code_2_rounded,
                    color: selected ? _Palette.cyan : _Palette.lightGray,
                    size: selected ? 26 : 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Large QR on a white card: white background + padding keeps the code's
  // quiet zone intact so phone cameras scan it reliably.
  Widget _qrPanel(_PaymentOptionInfo option) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _Palette.bgDarkGraySection,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Palette.cyan.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text('Scan to pay via ${option.name}',
              style: _Fonts.heading(size: 15)),
          const SizedBox(height: 2),
          Text(widget.price,
              style: _Fonts.display(size: 26, color: _Palette.cyan)),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              option.qrAsset,
              height: 380,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) => SizedBox(
                height: 200,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.qr_code_2,
                        size: 80, color: Color(0xFFC8CCD2)),
                    const SizedBox(height: 8),
                    Text('QR code unavailable',
                        style: _Fonts.body(
                            size: 12.5, color: const Color(0xFF6B7280))),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Open your ${option.name} app and scan this code. After paying, '
            'tap "Get Started" to create your account and attach your receipt.',
            textAlign: TextAlign.center,
            style:
                _Fonts.body(size: 12, color: _Palette.mutedGray, height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// RESULTS / MEMBER TRANSFORMATIONS
/// ---------------------------------------------------------------------
/// Placeholder content -- swap the quotes/names for real members.
class _ResultsSection extends StatelessWidget {
  const _ResultsSection();

  static const _results = [
    (
      'Jamie R.',
      'Down 12 kg and finally training pain-free. The coaches actually check in on you.',
      ['−12 kg', '6 months'],
    ),
    (
      'Marco D.',
      'Went from never lifting to a 100 kg deadlift. Best decision I made this year.',
      ['+18 kg lift', '4 months'],
    ),
    (
      'Alyssa T.',
      'The community keeps me coming back. I look forward to my sessions now.',
      ['−8 kg', '3 months'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cols = w < 720 ? 1 : 3;
    return _SectionShell(
      background: _Palette.bgDarkGraySection,
      child: Column(
        children: [
          const _SectionHeader(
              eyebrow: 'Real results', title: 'Members who put in the work'),
          _CardGrid(
            columns: cols,
            children: [
              for (final r in _results)
                _HoverScale(
                  endScale: 1.02,
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: _Palette.bgCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _Palette.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (int i = 0; i < r.$3.length; i++)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 11, vertical: 5),
                                decoration: BoxDecoration(
                                  color: i == 0
                                      ? _Palette.yellow
                                      : _Palette.bgDarkGraySection,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(r.$3[i],
                                    style: GoogleFonts.barlow(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: i == 0
                                            ? AppColors.onGold
                                            : _Palette.lightGray)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text('"${r.$2}"',
                            style: _Fonts.body(
                                size: 16.5,
                                height: 1.5,
                                color: _Palette.offWhite)),
                        const SizedBox(height: 18),
                        Text(r.$1,
                            style: _Fonts.heading(
                                size: 14.5, weight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// GALLERY -- "Step inside the gym"
/// ---------------------------------------------------------------------
/// Images come from `assets/images/gallery/` via [GalleryImages] -- see
/// that file to add photos.
class _GallerySection extends StatelessWidget {
  const _GallerySection();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cols = w < 640 ? 2 : 3;
    return _SectionShell(
      background: _Palette.bgNearBlack,
      child: Column(
        children: [
          const _SectionHeader(
              eyebrow: 'Step inside the gym', title: 'Where it all happens'),
          FutureBuilder<List<String>>(
            future: GalleryImages.load(),
            initialData: GalleryImages.fallback,
            builder: (context, snapshot) {
              final shots = snapshot.data ?? GalleryImages.fallback;
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.35,
                children: [
                  for (int i = 0; i < shots.length; i++)
                    _HoverScale(
                      endScale: 1.03,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _Palette.bgCard,
                            border: Border.all(color: _Palette.cardBorder),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(
                            shots[i],
                            fit: BoxFit.cover,
                            alignment: i.isEven
                                ? Alignment.center
                                : Alignment.topCenter,
                            errorBuilder: (_, __, ___) => Container(
                              color: _Palette.bgCard,
                              alignment: Alignment.center,
                              child: Icon(Icons.photo_outlined,
                                  color: _Palette.cyan.withValues(alpha: 0.5),
                                  size: 32),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// MERCHANDISE / PRIMEFIT STORE (in-store only — no cart/checkout)
/// ---------------------------------------------------------------------

// Where the "IN-STORE PURCHASE ONLY · VISIT US TO BUY" pill sends people:
// PrimeFit's Facebook page, so they can message the gym and inquire.
const String _kPrimeFitFacebookUrl =
    'https://www.facebook.com/profile.php?id=61579305812618';

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

/// The "IN-STORE PURCHASE ONLY · VISIT US TO BUY" pill. Tapping it opens
/// PrimeFit's Facebook page so visitors can inquire there.
class _StoreInquiryPill extends StatelessWidget {
  final Color color;
  final bool expand;
  const _StoreInquiryPill({required this.color, this.expand = false});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Inquire on PrimeFit\'s Facebook page',
      child: Material(
        color: color,
        clipBehavior: Clip.antiAlias,
        shape: StadiumBorder(
          side: BorderSide(color: _Palette.yellow.withValues(alpha: 0.85)),
        ),
        child: InkWell(
          onTap: () => _launchUri(Uri.parse(_kPrimeFitFacebookUrl)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    'IN-STORE PURCHASE ONLY · VISIT US TO BUY',
                    textAlign: TextAlign.center,
                    style: _Fonts.sectionLabel(color: _Palette.yellow)
                        .copyWith(fontSize: 11.5, letterSpacing: 1.6),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.open_in_new, color: _Palette.yellow, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
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

    final bp = _breakpointOf(context);
    final sectionPadding = _sectionPadding(context);

    // Cards get an even gap and identical sizes (every card has the same
    // fixed-height slots):
    //   desktop -> 3 equal columns, tablet -> 2 per row, mobile -> 1.
    const gap = 24.0;
    final Widget cardsLayout;
    if (bp == _Breakpoint.desktop) {
      cardsLayout = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: gap),
            Expanded(child: _MerchCard(item: items[i])),
          ],
        ],
      );
    } else {
      final contentWidth =
          MediaQuery.of(context).size.width - sectionPadding.horizontal;
      final cardWidth = bp == _Breakpoint.tablet
          ? (contentWidth - gap) / 2
          : contentWidth.clamp(0.0, 420.0).toDouble();
      cardsLayout = Wrap(
        spacing: gap,
        runSpacing: gap,
        alignment: WrapAlignment.center,
        children: [
          for (final item in items)
            SizedBox(width: cardWidth, child: _MerchCard(item: item)),
        ],
      );
    }

    return _SectionShell(
      background: _Palette.bgDarkGraySection,
      child: Column(
        children: [
          const _SectionHeader(
            eyebrow: 'PrimeFit store',
            title: 'Merch & apparel',
            subtitle:
                "Rep the gym with PrimeFit's official apparel. Available exclusively at our Taguig City location.",
          ),
          // Tap -> opens PrimeFit's Facebook page to inquire.
          Transform.translate(
            offset: const Offset(0, -20),
            child: const _StoreInquiryPill(color: Colors.transparent),
          ),
          const SizedBox(height: 16),
          cardsLayout,
        ],
      ),
    ).animate().fade(duration: 500.ms).slideY(begin: 0.12);
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
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => showDialog(
            context: context,
            builder: (_) => _MerchDetailsDialog(item: item),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _Palette.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _Palette.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // White card behind the product photo (the photos have a
                // white background, so it blends in cleanly).
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 230,
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(
                      item.imagePath,
                      fit: BoxFit.contain,
                      // Falls back to the category icon if the photo isn't
                      // found yet, instead of crashing the page.
                      errorBuilder: (context, error, stackTrace) => Icon(
                        item.icon,
                        color: item.badgeColor.withValues(alpha: 0.6),
                        size: 56,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: item.badgeColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(item.category,
                            style: _Fonts.sectionLabel(color: item.badgeColor)
                                .copyWith(fontSize: 10.5, letterSpacing: 2)),
                      ),
                      const SizedBox(height: 12),
                      // Fixed two-line slot so every card has the same
                      // height, whether the name wraps to one line or two.
                      SizedBox(
                        height: 44,
                        child: Text(item.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: _Fonts.heading(
                                    size: 16.5, weight: FontWeight.w700)
                                .copyWith(height: 1.3)),
                      ),
                      const SizedBox(height: 4),
                      Text(item.code,
                          style: _Fonts.body(
                              size: 12, color: _Palette.mutedGray)),
                      const SizedBox(height: 12),
                      Text(item.price,
                          style: _Fonts.display(
                              size: 22, color: _Palette.yellow)),
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

/// Shown when a member taps a merch card -- a slightly bigger card with
/// the item's photo, category, name, code and price. The in-store note
/// at the bottom is tappable and opens PrimeFit's Facebook page.
class _MerchDetailsDialog extends StatelessWidget {
  final _MerchItem item;
  const _MerchDetailsDialog({required this.item});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          decoration: BoxDecoration(
            color: _Palette.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _Palette.cardBorder),
            boxShadow: AppColors.softCardShadow,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
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
                          color: _Palette.lightGray, size: 24),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 300,
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.all(14),
                    child: Image.asset(
                      item.imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        item.icon,
                        color: item.badgeColor.withValues(alpha: 0.6),
                        size: 64,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.badgeColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(item.category,
                      style: _Fonts.sectionLabel(color: item.badgeColor)
                          .copyWith(fontSize: 11)),
                ),
                const SizedBox(height: 14),
                Text(item.name,
                    style: _Fonts.heading(size: 21, weight: FontWeight.w700)
                        .copyWith(height: 1.3)),
                const SizedBox(height: 6),
                Text(item.code,
                    style: _Fonts.body(size: 13, color: _Palette.mutedGray)),
                const SizedBox(height: 16),
                Text(item.price,
                    style: _Fonts.display(size: 32, color: _Palette.yellow)),
                const SizedBox(height: 22),
                // Tap -> opens PrimeFit's Facebook page to inquire.
                const _StoreInquiryPill(
                    color: _Palette.bgDarkSection, expand: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// LOCATION (photo + info + map card -- the map card/info rows are
/// tappable: opens Google Maps, the dialer, or the social pages)
/// ---------------------------------------------------------------------
class _LocationSection extends StatefulWidget {
  const _LocationSection();

  @override
  State<_LocationSection> createState() => _LocationSectionState();
}

class _LocationSectionState extends State<_LocationSection> {
  final _searchController = TextEditingController();
  final _mapController = MapController();
  final _distance = const Distance();

  LatLng? _visitorLocation;
  String? _foundLabel;
  double? _distanceKm;
  bool _loading = false;
  String? _error;

  Future<void> _searchAddress() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1',
      );
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'PrimeFitApp/1.0 (primefitnesstaguig@gmail.com)'
        },
      );

      if (response.statusCode == 200) {
        final results = jsonDecode(response.body) as List;
        if (results.isNotEmpty) {
          final lat = double.parse(results[0]['lat']);
          final lon = double.parse(results[0]['lon']);
          final label = results[0]['display_name'] as String;
          _setVisitorLocation(LatLng(lat, lon), label);
        } else {
          setState(() => _error = 'No location found for that address.');
        }
      } else {
        setState(() => _error = 'Search failed. Try again.');
      }
    } catch (e) {
      setState(() => _error = 'Something went wrong. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _error = 'Location permission denied.');
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      _setVisitorLocation(
        LatLng(position.latitude, position.longitude),
        'Your current location',
      );
    } catch (e) {
      setState(() => _error = 'Could not get your location.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _setVisitorLocation(LatLng point, String label) {
    final meters = _distance(_primeFitLatLng, point);
    setState(() {
      _visitorLocation = point;
      _foundLabel = label;
      _distanceKm = meters / 1000;
    });
    _mapController.move(point, 14);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _zoomButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(4),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 30,
          height: 30,
          child: Icon(icon, size: 18, color: Colors.black87),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bp = _breakpointOf(context);
    // Side-by-side only on desktop. Tablet and mobile stack the photo on
    // top and the info underneath, so nothing gets squeezed.
    final isRow = bp == _Breakpoint.desktop;
    final twoColTiles = bp != _Breakpoint.mobile;

    void openInMaps() => _launchUri(Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(_primeFitAddress)}',
        ));
    void openDirections() => _launchUri(Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(_primeFitAddress)}',
        ));

    // ---- PHOTO (fills whatever space it is given) ----
    final photo = Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/about_gym.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: _Palette.bgDeepBlack),
        ),
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
                  fontSize: isRow ? 24 : 20, height: 1.2, letterSpacing: -0.3),
              children: const [
                TextSpan(
                    text: 'TRAIN HARD.\n',
                    style: TextStyle(color: Colors.white)),
                TextSpan(
                    text: 'LIVE STRONG.',
                    style: TextStyle(color: _Palette.yellow)),
              ],
            ),
          ),
        ),
      ],
    );

    // ---- INFO TILES (2 x 2 grid, or one column on phones) ----
    final locationTile = _infoTile(
        Icons.location_on_outlined, 'LOCATION', _primeFitAddress, _Palette.cyan,
        onTap: openInMaps);
    final phoneTile = _infoTile(
        Icons.call_outlined, 'PHONE', '+63 917 847 8351', _Palette.cyan,
        onTap: () => _launchUri(Uri.parse('tel:+639178478351')));
    final hoursTile = _infoTile(Icons.schedule_outlined, 'OPERATING HOURS',
        'Mon–Sun: 7:00 AM – 10:00 PM', _Palette.yellow);
    final socialTile = _infoTile(
        Icons.share_outlined, 'SOCIAL MEDIA', null, _Palette.yellow,
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
        ));

    Widget tileRow(Widget a, Widget b) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: a),
            const SizedBox(width: 16),
            Expanded(child: b),
          ],
        );

    final tiles = twoColTiles
        ? Column(
            children: [
              tileRow(locationTile, phoneTile),
              const SizedBox(height: 14),
              tileRow(hoursTile, socialTile),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              locationTile,
              const SizedBox(height: 14),
              phoneTile,
              const SizedBox(height: 14),
              hoursTile,
              const SizedBox(height: 14),
              socialTile,
            ],
          );

    // ---- MAP (zoom buttons + distance search bar sit on top of it) ----
    Widget mapView() => ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: FlutterMap(
                  mapController: _mapController,
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
                                      color:
                                          Colors.black.withValues(alpha: 0.75),
                                      borderRadius: BorderRadius.circular(8)),
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
                        if (_visitorLocation != null)
                          Marker(
                            point: _visitorLocation!,
                            width: 90,
                            height: 60,
                            alignment: Alignment.topCenter,
                            child: const IgnorePointer(
                              child: Icon(Icons.person_pin_circle,
                                  color: Colors.redAccent, size: 32),
                            ),
                          ),
                      ],
                    ),
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution(
                          'OpenStreetMap contributors',
                          onTap: () => _launchUri(Uri.parse(
                              'https://www.openstreetmap.org/copyright')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Zoom buttons (top-left)
              Positioned(
                top: 10,
                left: 10,
                child: Column(
                  children: [
                    _zoomButton(Icons.add, () {
                      _mapController.move(_mapController.camera.center,
                          _mapController.camera.zoom + 1);
                    }),
                    const SizedBox(height: 4),
                    _zoomButton(Icons.remove, () {
                      _mapController.move(_mapController.camera.center,
                          _mapController.camera.zoom - 1);
                    }),
                  ],
                ),
              ),
              // Distance search bar (top, next to the zoom buttons)
              Positioned(
                top: 10,
                left: 52,
                right: 10,
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.only(left: 14, right: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xEB121316),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _Palette.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onSubmitted: (_) => _searchAddress(),
                          cursorColor: _Palette.cyan,
                          style: _Fonts.body(size: 13, color: _Palette.white),
                          decoration: InputDecoration(
                            hintText: 'Enter your address...',
                            hintStyle: _Fonts.body(
                                size: 13, color: _Palette.mutedGray),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Search',
                        visualDensity: VisualDensity.compact,
                        onPressed: _loading ? null : _searchAddress,
                        icon: _loading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: _Palette.cyan))
                            : const Icon(Icons.search,
                                size: 19, color: _Palette.cyan),
                      ),
                      IconButton(
                        tooltip: 'Use my current location',
                        visualDensity: VisualDensity.compact,
                        onPressed: _loading ? null : _useCurrentLocation,
                        icon: const Icon(Icons.my_location,
                            size: 17, color: _Palette.white),
                      ),
                    ],
                  ),
                ),
              ),
              // Thin frame on top of the map
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
        );

    // Caption under the map: normal hint, or the distance result / error.
    final hasResult = _foundLabel != null && _distanceKm != null;
    final captionText = _error ??
        (hasResult
            ? 'Found: $_foundLabel — ${_distanceKm!.toStringAsFixed(1)} km away'
            : 'Use the map above to view our exact location and nearby streets.');
    final captionStyle = _error != null
        ? _Fonts.body(size: 12.5, color: Colors.redAccent)
        : (hasResult
            ? _Fonts.body(size: 12.5, color: _Palette.cyan)
            : _Fonts.body(size: 12.5, color: _Palette.mutedGray));

    // ---- INFO COLUMN ----
    final infoColumn = Padding(
      padding: EdgeInsets.all(isRow ? 28 : 18),
      child: Column(
        // Desktop: the map takes all the leftover height of the card.
        mainAxisSize: isRow ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('VISIT PRIMEFIT GYM',
              style: _Fonts.display(size: isRow ? 24 : 20)),
          const SizedBox(height: 6),
          Text(
            'Find our gym, view its exact location, and get directions '
            'in seconds.',
            style: _Fonts.body(
                size: 13.5, color: _Palette.lightGray, height: 1.4),
          ),
          const SizedBox(height: 18),
          tiles,
          const SizedBox(height: 14),
          const Divider(color: _Palette.cardBorder, height: 1),
          const SizedBox(height: 14),
          if (isRow)
            Expanded(child: mapView())
          else
            SizedBox(height: 320, child: mapView()),
          const SizedBox(height: 10),
          Text(captionText,
              maxLines: 2, overflow: TextOverflow.ellipsis, style: captionStyle),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: openDirections,
              borderRadius: BorderRadius.circular(6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Open in Google Maps',
                      style: GoogleFonts.barlow(
                          fontSize: 14.5,
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
      ),
      clipBehavior: Clip.antiAlias,
      child: isRow
          // Fixed card height -> the photo fills it edge to edge and the
          // map stretches to use whatever height is left in the info side.
          ? SizedBox(
              height: 760,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 4, child: photo),
                  Expanded(flex: 7, child: infoColumn),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 240, child: photo),
                infoColumn,
              ],
            ),
    );

    return _SectionShell(
      background: _Palette.bgDarkGraySection,
      child: Column(
        children: [
          const _SectionHeader(
            eyebrow: 'Find us',
            title: 'PrimeFit location',
            subtitle:
                "Come visit us at our Taguig City gym — we're open every day.",
          ),
          card,
        ],
      ),
    ).animate().fade(duration: 500.ms).slideY(begin: 0.12);
  }

  Widget _infoTile(IconData icon, String label, String? value, Color accent,
      {VoidCallback? onTap, Widget? valueChild}) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.center,
          child: Icon(icon, color: accent, size: 14),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: _Fonts.sectionLabel(color: _Palette.mutedGray)
                      .copyWith(fontSize: 10.5, letterSpacing: 2)),
              const SizedBox(height: 2),
              if (valueChild != null)
                valueChild
              else
                Text(
                  value ?? '',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.barlow(
                    color: onTap != null ? _Palette.cyan : _Palette.offWhite,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
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
    final isWide = _breakpointOf(context) == _Breakpoint.desktop;

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

    // Desktop: five equal-height cards in one row. Smaller screens: fixed
    // width cards that wrap and stay centred.
    final Widget cards = isWide
        ? _CardGrid(
            columns: 5,
            gap: 16,
            children: items.map((it) => _ContactCard(item: it)).toList(),
          )
        : Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: items
                .map((it) => _ContactCard(item: it, fixedWidth: 260))
                .toList(),
          );

    return _SectionShell(
      background: _Palette.bgNearBlack,
      child: Column(
        children: [
          const _SectionHeader(
              eyebrow: 'Get in touch', title: 'Contact PrimeFit'),
          cards,
          const SizedBox(height: 28),
          const _BusinessHoursCard(),
        ],
      ),
    ).animate().fade(duration: 500.ms).slideY(begin: 0.12);
  }
}

class _ContactCard extends StatelessWidget {
  final _ContactItem item;

  /// When set (wrapped layout), the card is exactly this wide with a
  /// minimum height so all five line up; otherwise it stretches to fill the
  /// grid cell it's placed in.
  final double? fixedWidth;
  const _ContactCard({required this.item, this.fixedWidth});

  @override
  Widget build(BuildContext context) {
    final isLongValue = item.value.length > 24;
    final card = Container(
      width: fixedWidth,
      constraints: BoxConstraints(minHeight: fixedWidth != null ? 220 : 0),
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 26),
      decoration: BoxDecoration(
        color: _Palette.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _Palette.cardBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _OutlineIcon(icon: item.icon, color: item.accent, size: 50),
          const SizedBox(height: 16),
          Text(
            item.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: _Fonts.sectionLabel(color: _Palette.mutedGray)
                .copyWith(fontSize: 11, letterSpacing: 2),
          ),
          const SizedBox(height: 10),
          Text(
            item.value,
            textAlign: TextAlign.center,
            style: GoogleFonts.barlow(
              fontWeight: FontWeight.w700,
              fontSize: isLongValue ? 13.5 : 16.5,
              height: 1.4,
              color: item.looksLikeLink ? _Palette.cyan : _Palette.offWhite,
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
        padding: const EdgeInsets.fromLTRB(28, 22, 28, 22),
        decoration: BoxDecoration(
          color: _Palette.bgCard,
          borderRadius: BorderRadius.circular(18),
          // One uniform border -- Flutter can't paint rounded corners with
          // a different color/width per side (that was what made this card
          // render blank).
          border: Border.all(color: _Palette.yellow, width: 1.4),
        ),
        child: Column(
          children: [
            Text('Business Hours',
                style: _Fonts.heading(size: 17, color: Colors.white)),
            const SizedBox(height: 12),
            Text('Monday – Saturday: 7:00 AM – 10:00 PM',
                textAlign: TextAlign.center, style: _Fonts.body(size: 14.5)),
            const SizedBox(height: 4),
            Text('Sunday: 8:00 AM – 8:00 PM',
                textAlign: TextAlign.center, style: _Fonts.body(size: 14.5)),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// FINAL CTA BAND -- gold -> cyan gradient
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [_Palette.yellow, _Palette.cyan],
        ),
      ),
      padding: EdgeInsets.symmetric(
          horizontal: w < 600 ? 20 : 48, vertical: w < 600 ? 52 : 72),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            children: [
              Text('READY TO START TRAINING?',
                  textAlign: TextAlign.center,
                  style: _Fonts.display(
                      size: w < 600 ? 26 : 40,
                      color: _Palette.ink,
                      height: 1.15)),
              const SizedBox(height: 14),
              Text(
                'Join PrimeFit today — no joining fee, cancel anytime.',
                textAlign: TextAlign.center,
                style: GoogleFonts.barlow(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _Palette.ink),
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 14,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _InkPill('JOIN NOW', onTap: onJoin, filled: true),
                  _InkPill('VIEW PLANS', onTap: onViewPlans),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Black pill button for use on the gradient CTA band.
class _InkPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool filled;
  const _InkPill(this.label, {required this.onTap, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? _Palette.ink : Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: const StadiumBorder(side: BorderSide(color: _Palette.ink, width: 1.6)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 15),
          child: Text(label,
              style: _Fonts.button(
                  size: 14, color: filled ? Colors.white : _Palette.ink)),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// FOOTER
/// ---------------------------------------------------------------------
///
/// Layout pattern: four columns -- Brand, Quick Links, Visit Us, Follow
/// Along -- stack on narrow widths and sit side-by-side on wide ones,
/// followed by a thin copyright bar.
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
        Container(
          width: double.infinity,
          color: _Palette.bgDeepBlack,
          padding: EdgeInsets.symmetric(
              horizontal: 24, vertical: isWide ? 56 : 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _kContentMaxWidth),
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
            style: _Fonts.body(size: 14.5, color: _Palette.white)),
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
        Text('Mon–Sat 7:00 AM – 10:00 PM', style: _Fonts.body(size: 14)),
        const SizedBox(height: 4),
        Text('Sun 8:00 AM – 8:00 PM', style: _Fonts.body(size: 14)),
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
                style: _Fonts.body(size: 14.5, color: _Palette.cyan)),
          ],
        ),
      ),
    );
  }
}
