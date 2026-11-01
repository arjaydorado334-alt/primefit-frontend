import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import 'prime_fit_logo.dart';

/// The site-wide footer (Brand / Quick Links / Visit Us / Follow Along +
/// copyright bar) -- originally built for the landing page, extracted here
/// so the Sign In and Create Account pages can reuse the exact same
/// widget instead of rebuilding it. `landing_page.dart` imports [SiteFooter]
/// too; nothing about its look changed in the move.
///
/// The `onAbout` / `onMission` / `onMembership` / `onMerchandise` /
/// `onContact` callbacks are supplied by the caller -- on the landing page
/// itself they scroll the current page; from another page (Sign In,
/// Create Account) they navigate to the landing page and land on that
/// section (see `LandingPage`'s `initialSection` in `landing_page.dart`).
/// `onLogoTap` is the same idea for the logo/wordmark: scroll-to-top on
/// the landing page itself, or navigate there from elsewhere.
class SiteFooter extends StatelessWidget {
  final VoidCallback onLogoTap;
  final VoidCallback onAbout;
  final VoidCallback onMission;
  final VoidCallback onMembership;
  final VoidCallback onMerchandise;
  final VoidCallback onContact;

  const SiteFooter({
    super.key,
    required this.onLogoTap,
    required this.onAbout,
    required this.onMission,
    required this.onMembership,
    required this.onMerchandise,
    required this.onContact,
  });

  // Below this width the four columns stack instead of sitting side by
  // side -- same 1024 "desktop" cutoff the landing page uses elsewhere.
  static const double _kDesktopMinWidth = 1024;

  // Update this each January rather than computing it from DateTime.now(),
  // so the footer doesn't silently roll over mid-way through a deploy or
  // depend on the visitor's device clock.
  static const int _kCopyrightYear = 2026;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= _kDesktopMinWidth;

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: _FooterColors.bgDeepBlack,
          padding: EdgeInsets.symmetric(
              horizontal: isWide ? 72 : 24, vertical: isWide ? 56 : 40),
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        flex: 3,
                        child: _FooterBrandColumn(onLogoTap: onLogoTap)),
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
                    _FooterBrandColumn(onLogoTap: onLogoTap),
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
            color: _FooterColors.bgDeepBlack,
            border: Border(
                top: BorderSide(color: _FooterColors.cardBorder, width: 1)),
          ),
          child: Center(
            child: Text(
              '© $_kCopyrightYear PrimeFit. All rights reserved.',
              style: _FooterText.body(size: 12, color: _FooterColors.mutedGray),
            ),
          ),
        ),
      ],
    );
  }
}

class _FooterBrandColumn extends StatelessWidget {
  final VoidCallback onLogoTap;
  const _FooterBrandColumn({required this.onLogoTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onLogoTap,
          borderRadius: BorderRadius.circular(8),
          child: Row(
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
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: 260,
          child: Text('Your fitness journey starts here.',
              style: _FooterText.body(size: 13.5)),
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
        Text('QUICK LINKS',
            style: _FooterText.sectionLabel(color: _FooterColors.cyan)),
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
            style: _FooterText.body(size: 14, color: _FooterColors.lightGray)),
      ),
    );
  }
}

// Kept in sync with landing_page.dart's own `_primeFitAddress` -- both are
// the same literal PrimeFit gym address, just duplicated as plain data so
// this file doesn't need to reach into that page's private constants.
const String _kFooterAddress =
    '31 Bernardo St, near Army Road, Central Signal, Taguig, Metro Manila, Philippines 1633';

class _FooterVisitUsColumn extends StatelessWidget {
  const _FooterVisitUsColumn();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('VISIT US',
            style: _FooterText.sectionLabel(color: _FooterColors.cyan)),
        const SizedBox(height: 18),
        SizedBox(
          width: 280,
          child: Text(_kFooterAddress, style: _FooterText.body(size: 14)),
        ),
        const SizedBox(height: 14),
        Text('Monday – Saturday: 7:00 AM – 10:00 PM',
            style: _FooterText.body(size: 14)),
        const SizedBox(height: 4),
        Text('Sunday: 8:00 AM – 8:00 PM', style: _FooterText.body(size: 14)),
      ],
    );
  }
}

class _FooterFollowColumn extends StatelessWidget {
  const _FooterFollowColumn();

  Future<void> _launch(Uri uri) async {
    try {
      await launchUrl(uri);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('FOLLOW ALONG',
            style: _FooterText.sectionLabel(color: _FooterColors.cyan)),
        const SizedBox(height: 18),
        _FooterSocialLink(
          icon: Icons.facebook_outlined,
          label: 'Facebook',
          onTap: () => _launch(Uri.parse(
              'https://www.facebook.com/profile.php?id=61579305812618')),
        ),
        _FooterSocialLink(
          icon: Icons.music_note_outlined,
          label: 'TikTok',
          onTap: () =>
              _launch(Uri.parse('https://www.tiktok.com/@primefit.fitness.g')),
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
            Icon(icon, size: 16, color: _FooterColors.cyan),
            const SizedBox(width: 8),
            Text(label,
                style:
                    _FooterText.body(size: 14, color: _FooterColors.lightGray)),
          ],
        ),
      ),
    );
  }
}

/// The handful of `AppColors` aliases the footer needs, named to match
/// landing_page.dart's own private `_Palette` so the moved code above
/// reads the same as it did there.
class _FooterColors {
  _FooterColors._();
  static const bgDeepBlack = Color(0xFF060608);
  static const cardBorder = AppColors.darkBorder;
  static const mutedGray = Color(0xFF868D99);
  static const cyan = AppColors.cyan;
  static const lightGray = AppColors.textMutedOnDark;
}

/// The two type styles the footer needs, matching landing_page.dart's own
/// private `_Fonts.sectionLabel` / `_Fonts.body` exactly.
class _FooterText {
  _FooterText._();

  static TextStyle sectionLabel({Color color = _FooterColors.cyan}) =>
      GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 3.5,
      );

  static TextStyle body({
    double size = 15,
    Color color = _FooterColors.lightGray,
    double height = 1.6,
    FontWeight weight = FontWeight.w400,
  }) =>
      GoogleFonts.inter(
          fontSize: size, color: color, height: height, fontWeight: weight);
}
