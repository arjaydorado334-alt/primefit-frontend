import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared typography anchored to the Login / Create Account screens, so the
/// whole app (public auth flow + member portal) reads as one system:
///   * page titles  -> Archivo Black   (matches `_AuthFonts.heading`)
///   * everything else -> Inter        (set as the base font in [AppTheme])
class AppText {
  AppText._();

  /// The big page title at the top of a screen. Same face / metrics as the
  /// Login page's "Welcome Back" heading.
  static TextStyle pageTitle({double size = 26, Color? color}) =>
      GoogleFonts.archivoBlack(
        fontSize: size,
        color: color,
        height: 1.15,
        letterSpacing: -0.3,
      );

  /// Section / card title inside the white content area — the muted plum
  /// accent shared with the admin app. NOT for the white heading inside a
  /// cyan banner (that stays white, use [pageTitle]). Pass a lighter
  /// [color] (e.g. `Color(0xFFB39DDB)`) on dark surfaces.
  static TextStyle sectionTitle({double size = 15, Color? color}) => TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: size,
        color: color ?? AppColors.plum,
        letterSpacing: 0.1,
      );
}

/// Central place for every color / gradient used across the app so all
/// screens stay visually consistent with the Figma design.
class AppColors {
  AppColors._();

  static const Color cyan = Color(0xFF22D3EE);
  static const Color yellow = Color(0xFFFBBF24);
  static const Color green = Color(0xFFA3E635);

  // ---- Admin-portal parity tokens -------------------------------------
  // Mirrors the PrimeFit Admin app's palette (lib/theme/app_theme.dart in
  // primefit_admin) so the two portals render an identical brand cyan.
  // Admin: cyan #17C3D6 / cyanDark #0E8FA0 / gold #F2B705.
  static const Color adminCyan = Color(0xFF17C3D6);
  static const Color adminCyanDark = Color(0xFF0E8FA0);

  /// The single flat brand-cyan fill for the member-portal sidebar and for
  /// every screen's solid header banner (no gradient). Identical to the
  /// admin app's [adminCyan] (#17C3D6) — change it there and here together.
  static const Color brandTeal = adminCyan;

  /// Aliases kept for readability at call sites.
  static const Color sidebarFill = brandTeal;
  static const Color heroFill = brandTeal;

  /// Legible tones for content sitting on [brandTeal].
  static const Color onTealMuted = Color(0xFFB9E6F1); // eyebrow / secondary
  static const Color onTealSubtle = Color(0xFFCDEEF5); // inactive nav label

  /// Gold accent — nav icons, header-banner eyebrow + leading icon, and
  /// primary buttons. Matches the admin app's gold exactly.
  static const Color gold = Color(0xFFF2B705);

  /// Near-black text/icon that sits on a [gold] surface (≈9:1 on gold).
  static const Color onGold = Color(0xFF1A1A1A);

  /// Brighter gold for a gold *icon* on the cyan fill, still reading as gold.
  static const Color goldOnCyan = Color(0xFFFFD24D);

  /// Pale gold for gold *text* (the header eyebrow) on the cyan fill.
  static const Color goldOnCyanText = Color(0xFFFFECB3);

  /// Dark gold for an icon on the white active nav pill (≈4.9:1 on white).
  static const Color goldDark = Color(0xFFA16207);

  /// Muted purple/plum — section & card titles in the white content area
  /// (never the white heading inside a cyan banner). ≈5.2:1 on white.
  static const Color plum = Color(0xFF7E57C2);

  /// Shared light-cyan tint for form field fills (see InputDecorationTheme).
  static const Color fieldFill = Color(0xFFEAF9FC);
  static const Color fieldBorder = Color(0xFFC7E9EF);

  /// Sidebar footer panel — a deeper teal, visibly distinct from the fill.
  static const Color sidebarFooter = Color(0xFF0B5F76);

  // Semantic pill colours (admin parity): text + soft tinted background.
  static const Color successBg = Color(0xFFDCFCE7);
  static const Color success = Color(0xFF15803D);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color warning = Color(0xFF9A6700);
  static const Color dangerBg = Color(0xFFFEE2E2);
  static const Color danger = Color(0xFFB91C1C);

  static const Color darkBg = Color(0xFF0A0A0B);
  static const Color darkCard = Color(0xFF15161A);
  static const Color darkBorder = Color(0xFF262832);

  static const Color textMutedOnDark = Color(0xFF9CA3AF);
  static const Color textMutedOnLight = Color(0xFF6B7280);

  static const Color lightBg = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFF7F8FA);
  static const Color cardBorder = Color(0xFFE5E7EB);

  // ---- Member-portal refresh tokens (light theme) ----------------------
  /// The single page background used behind all authenticated portal
  /// screens (was 4 slightly different near-white shades).
  static const Color portalPageBg = Color(0xFFF7F8FA);

  /// Pastel fills for the small icon badges on stat / info cards.
  static const Color cyanTint = Color(0xFFDCF3FF);
  static const Color goldTint = Color(0xFFFFF3D6);

  /// Accent colours used to tint cards by meaning (kept within the
  /// cyan / gold family plus a positive-green and a warning-amber).
  static const Color accentCyan = cyan;
  static const Color accentGold = yellow;
  static const Color accentGreen = Color(0xFF16A34A);
  static const Color accentAmber = Color(0xFFD97706);
  static const Color accentViolet = Color(0xFF8B5CF6);

  /// Very light card background tinted toward [accent] (light theme only —
  /// pass the card's own surface for dark). Subtle by design: individually
  /// it reads as "barely warm/cool", collectively it stops every card from
  /// looking identical.
  static Color cardTint(Color accent) =>
      Color.alphaBlend(accent.withValues(alpha: 0.055), Colors.white);

  /// Matching slightly-stronger tint for a card border, so the accent is
  /// legible without a hard coloured edge.
  static Color cardTintBorder(Color accent) =>
      Color.alphaBlend(accent.withValues(alpha: 0.22), cardBorder);

  /// Soft, wide drop shadow for white cards in light mode. Use `const []`
  /// in dark mode (a shadow on a dark surface just muddies it).
  static const List<BoxShadow> softCardShadow = [
    BoxShadow(color: Color(0x0D0B1220), blurRadius: 18, offset: Offset(0, 6)),
  ];

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [cyan, green, yellow],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient iconGradient = LinearGradient(
    colors: [cyan, yellow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  AppTheme._();

  /// Gold primary buttons with near-black text (admin parity). Applied
  /// app-wide; screens that still pass an explicit `backgroundColor` in
  /// `styleFrom` keep that until individually migrated.
  static final ElevatedButtonThemeData _goldButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.gold,
      foregroundColor: AppColors.onGold,
      disabledBackgroundColor: const Color(0xFFEAD9A0),
      disabledForegroundColor: const Color(0x8A1A1A1A),
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );

  static final FilledButtonThemeData _goldFilledButtonTheme = FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.gold,
      foregroundColor: AppColors.onGold,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );

  static final OutlinedButtonThemeData _outlineButtonTheme = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF1A1A1A),
      backgroundColor: Colors.white,
      side: const BorderSide(color: AppColors.cardBorder),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );

  /// Shared light cyan-tinted form fields (admin parity). Light theme only.
  static final InputDecorationTheme _inputTheme = InputDecorationTheme(
    filled: true,
    fillColor: AppColors.fieldFill,
    hintStyle: const TextStyle(color: AppColors.textMutedOnLight),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.fieldBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.fieldBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.adminCyan, width: 1.5),
    ),
  );

  static ThemeData get themeData {
    // Inter is the app-wide typeface, matching the public landing page
    // (which uses GoogleFonts.inter for body/labels). google_fonts is
    // already a dependency and already fetched at runtime by that page.
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.lightBg,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.cyan),
      fontFamily: GoogleFonts.inter().fontFamily,
    );
    final inter = GoogleFonts.interTextTheme(base.textTheme);
    return base.copyWith(
      textTheme: inter.copyWith(
        bodyMedium: inter.bodyMedium?.copyWith(color: const Color(0xFF1F2937)),
      ),
      elevatedButtonTheme: _goldButtonTheme,
      filledButtonTheme: _goldFilledButtonTheme,
      outlinedButtonTheme: _outlineButtonTheme,
      inputDecorationTheme: _inputTheme,
    );
  }

  static ThemeData get darkThemeData {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.cyan, brightness: Brightness.dark),
      fontFamily: GoogleFonts.inter().fontFamily,
    );
    final inter = GoogleFonts.interTextTheme(base.textTheme);
    return base.copyWith(
      textTheme: inter.copyWith(
        bodyMedium: inter.bodyMedium?.copyWith(color: AppColors.textMutedOnDark),
      ),
      elevatedButtonTheme: _goldButtonTheme,
      filledButtonTheme: _goldFilledButtonTheme,
    );
  }
}

/// Per-screen brightness helpers used while retheming the member portal's
/// content screens for dark mode -- lets a screen ask "what color should
/// this surface/text be right now" without reaching into `ThemeController`
/// directly (it just reads the ambient `Theme.of(context)`, which is kept
/// in sync app-wide via `themeMode` in `main.dart`).
extension AppColorsContext on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  Color get surfaceColor => isDarkMode ? AppColors.darkCard : AppColors.lightBg;
  Color get surfaceBorder => isDarkMode ? AppColors.darkBorder : AppColors.cardBorder;
  Color get textPrimaryColor => isDarkMode ? Colors.white : const Color(0xFF1A1A1A);
  Color get textMutedColor => isDarkMode ? AppColors.textMutedOnDark : AppColors.textMutedOnLight;

  /// Plum section-title colour, lightened on dark surfaces so it keeps AA.
  Color get sectionTitleColor =>
      isDarkMode ? const Color(0xFFB39DDB) : AppColors.plum;
}

/// Shared responsive breakpoints for the member portal: mobile < 600,
/// tablet 600-1024, desktop >= 1024.
enum Breakpoint { mobile, tablet, desktop }

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;

  Breakpoint get breakpoint {
    final w = screenWidth;
    if (w < 600) return Breakpoint.mobile;
    if (w < 1024) return Breakpoint.tablet;
    return Breakpoint.desktop;
  }

  bool get isMobile => breakpoint == Breakpoint.mobile;
  bool get isTablet => breakpoint == Breakpoint.tablet;
  bool get isDesktop => breakpoint == Breakpoint.desktop;

  /// Number of grid columns for stat/card grids: 1 on phone, 2 on
  /// tablet, [desktop] (default 3) on desktop.
  int columnsFor({int desktop = 3}) {
    switch (breakpoint) {
      case Breakpoint.mobile:
        return 1;
      case Breakpoint.tablet:
        return 2;
      case Breakpoint.desktop:
        return desktop;
    }
  }
}
