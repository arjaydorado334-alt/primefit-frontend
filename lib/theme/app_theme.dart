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
}

/// Central place for every color / gradient used across the app so all
/// screens stay visually consistent with the Figma design.
class AppColors {
  AppColors._();

  static const Color cyan = Color(0xFF22D3EE);
  static const Color yellow = Color(0xFFFBBF24);
  static const Color green = Color(0xFFA3E635);

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
