import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared typography for the whole app, reconciled 1:1 with the sibling
/// PrimeFit **Admin** app's text-style scheme so the two read as one product.
///
/// Font families (see [AppTheme]):
///   * page-title headings + the "PrimeFit" wordmark -> Archivo Black
///   * everything else                                -> Inter
///
/// Role → size / weight (mirror in the admin app):
///   page title .......... Archivo Black 30
///   page subtitle ....... Inter 14.5  w400
///   card/section title .. Inter 15.5  w700  (plum)
///   card subtitle ....... Inter 12.5  w400
///   stat number ......... Inter 28    w700
///   stat caption ........ Inter 13    w500
///   field label ......... Inter 13    w600
///   table header ........ Inter 11.5  w700
///   table cell .......... Inter 13.5  w400
///   sidebar nav ......... Inter 14    w700 active / w600 inactive
///   banner eyebrow ...... Inter 11.5  w700  (plum)
///   banner title ........ Inter 24    w800  (white)
///   banner subtitle ..... Inter 14    w400  (white)
///   button .............. Inter 14    w600
///   body ................ Inter 14    w400
///   body small .......... Inter 12.5  w400
///   status badge/pill ... Inter 12    w600
class AppText {
  AppText._();

  static TextStyle _i(double size, FontWeight w, Color? color,
          {double? ls, double? height}) =>
      TextStyle(
          fontSize: size,
          fontWeight: w,
          color: color,
          letterSpacing: ls,
          height: height);

  /// Page title at the top of a screen (Archivo Black, 30).
  static TextStyle pageTitle({double size = 30, Color? color}) =>
      GoogleFonts.archivoBlack(
          fontSize: size, color: color, height: 1.15, letterSpacing: -0.3);

  /// Page subtitle line under a [pageTitle].
  static TextStyle pageSubtitle({Color? color}) =>
      _i(14.5, FontWeight.w400, color);

  /// Card / section title in the white content area — plum accent, w700.
  /// Pass a lighter [color] (e.g. `Color(0xFFB39DDB)`) on dark surfaces.
  static TextStyle sectionTitle({double size = 15.5, Color? color}) =>
      _i(size, FontWeight.w700, color ?? AppColors.plum, ls: 0.1);

  /// Card subtitle / helper line.
  static TextStyle cardSubtitle({Color? color}) =>
      _i(12.5, FontWeight.w400, color);

  /// Large numeric display (stat cards, counters) — w700.
  static TextStyle statNumber({double size = 28, Color? color}) =>
      _i(size, FontWeight.w700, color);

  /// Caption under a [statNumber] — w500.
  static TextStyle statCaption({Color? color}) =>
      _i(13, FontWeight.w500, color);

  /// Form field label — w600.
  static TextStyle fieldLabel({Color? color}) =>
      _i(13, FontWeight.w600, color);

  /// Data-table / list column header — w700, muted.
  static TextStyle tableHeader({double size = 11.5, Color? color}) =>
      _i(size, FontWeight.w700, color ?? AppColors.textMuted);

  /// Data-table cell text — normal.
  static TextStyle tableCell({Color? color}) =>
      _i(13.5, FontWeight.w400, color);

  /// Sidebar nav item label — w600, or w700 when [active].
  static TextStyle navItem(
          {bool active = false, double size = 14, Color? color}) =>
      _i(size, active ? FontWeight.w700 : FontWeight.w600, color);

  /// Header-banner uppercase eyebrow — w700, plum.
  static TextStyle eyebrow({Color? color}) =>
      _i(11.5, FontWeight.w700, color ?? AppColors.plum, ls: 1.4);

  /// Header-banner title — Inter w800, white.
  static TextStyle bannerTitle({double size = 24, Color? color}) =>
      _i(size, FontWeight.w800, color ?? Colors.white, height: 1.15);

  /// Header-banner subtitle — normal, white.
  static TextStyle bannerSubtitle({Color? color}) =>
      _i(14, FontWeight.w400, color ?? Colors.white, height: 1.4);

  /// Button label — w600.
  static TextStyle button({Color? color}) => _i(14, FontWeight.w600, color);

  /// Long body / paragraph text — normal. Do not bulk-bold.
  static TextStyle bodyText({double size = 14, Color? color, double? height}) =>
      _i(size, FontWeight.w400, color, height: height);

  /// Body small / caption — normal.
  static TextStyle bodySmall({Color? color}) =>
      _i(12.5, FontWeight.w400, color);

  /// Status badge / pill label — w600 (pass [weight] w700 for emphasis).
  static TextStyle badgeLabel(
          {double size = 12, Color? color, FontWeight weight = FontWeight.w600}) =>
      _i(size, weight, color);
}

/// Fully-rounded ("pill") button styles used across the public landing page
/// and any other marketing-style surface. Built on the same gold accent as
/// the app-wide `ElevatedButtonThemeData`, just with a [StadiumBorder] and a
/// touch more horizontal padding. Prefer the [PillButton] widget
/// (`lib/widgets/pill_button.dart`) over calling these directly.
enum PillVariant { primary, outline, ghost, dark, darkOutline }

class AppButtons {
  AppButtons._();

  static const EdgeInsets _pad =
      EdgeInsets.symmetric(horizontal: 26, vertical: 15);

  /// Solid gold, near-black label — the main call to action.
  static ButtonStyle pillPrimary() => ElevatedButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.onGold,
        disabledBackgroundColor: const Color(0xFFEAD9A0),
        elevation: 0,
        padding: _pad,
        textStyle: AppText.button(),
        shape: const StadiumBorder(),
      );

  /// Transparent with a hairline border — the secondary CTA. Light by
  /// default (the landing page runs on a dark theme); pass a darker
  /// [color] when placing it on a light surface.
  static ButtonStyle pillOutline({Color color = const Color(0xFFE9EAEE)}) =>
      OutlinedButton.styleFrom(
        foregroundColor: color,
        backgroundColor: Colors.transparent,
        side: BorderSide(color: color.withValues(alpha: 0.55), width: 1.5),
        padding: _pad,
        textStyle: AppText.button(color: color),
        shape: const StadiumBorder(),
      );

  /// Ghost — white label + border, for use on a dark photo (hero overlay).
  static ButtonStyle pillGhost() => OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.white.withValues(alpha: 0.08),
        side: const BorderSide(color: Colors.white70, width: 1.5),
        padding: _pad,
        textStyle: AppText.button(color: Colors.white),
        shape: const StadiumBorder(),
      );

  /// Solid near-black, for use on a gold band (final CTA).
  static ButtonStyle pillDark() => ElevatedButton.styleFrom(
        backgroundColor: AppColors.dark,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: _pad,
        textStyle: AppText.button(color: Colors.white),
        shape: const StadiumBorder(),
      );

  /// Dark outline, for use on a gold band beside [pillDark].
  static ButtonStyle pillDarkOutline() => OutlinedButton.styleFrom(
        foregroundColor: AppColors.dark,
        backgroundColor: Colors.transparent,
        side: const BorderSide(color: AppColors.dark, width: 1.5),
        padding: _pad,
        textStyle: AppText.button(),
        shape: const StadiumBorder(),
      );
}

/// Central place for every color / gradient used across the app so all
/// screens stay visually consistent with the Figma design.
class AppColors {
  AppColors._();

  // ══════════════════════════════════════════════════════════════════════
  // ADMIN-PARITY PALETTE — exact hex match to the PrimeFit Admin app's
  // AppColors. Keep these in lock-step with the admin theme file.
  // ══════════════════════════════════════════════════════════════════════

  /// Primary brand cyan — sidebar fill + every header banner. (admin: cyan)
  static const Color cyan = Color(0xFF17C3D6);

  /// Deeper cyan — admin uses it for its sidebar user-card bg. (admin: cyanDark)
  static const Color cyanDark = Color(0xFF0E8FA0);

  /// Pastel cyan. (admin: cyanBg — its form-field fill)
  static const Color cyanBg = Color(0xFFE0F7FA);

  /// Gold accent — buttons, "Fit" wordmark, banner icons. (admin: gold)
  static const Color gold = Color(0xFFF2B705);

  /// Gold hover / pressed state for buttons. (admin: goldDark)
  static const Color goldDark = Color(0xFFC99400);

  /// Pastel gold. (admin: goldBg — its payment-field tint)
  static const Color goldBg = Color(0xFFFEF3C7);

  /// Purple accent — section titles + eyebrow labels. (admin: plum)
  static const Color plum = Color(0xFF7E57C2);

  /// Near-black — text/icon that sits on a gold surface. (admin: dark)
  static const Color dark = Color(0xFF0B0B0D);

  /// "Prime" wordmark text colour. (admin: darkGray)
  static const Color darkGray = Color(0xFF424242);

  static const Color textMuted = Color(0xFF6B7280); // (admin: textMuted)
  static const Color bg = Color(0xFFF6F7F9); // page background (admin: bg)
  static const Color cardBorder = Color(0xFFE7E9EE); // (admin: cardBorder)

  // Semantic — Tailwind-600 text + soft bg tints. (admin: success/warning/...)
  static const Color success = Color(0xFF16A34A);
  static const Color successBg = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFCA8A04);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerBg = Color(0xFFFEE2E2);
  static const Color blueIcon = Color(0xFF3B82F6);
  static const Color blueBg = Color(0xFFDBEAFE);
  static const Color greenIcon = Color(0xFF10B981);
  static const Color greenBg = Color(0xFFD1FAE5);
  static const Color tealIcon = Color(0xFF0D9488);
  static const Color tealBg = Color(0xFFCCFBF1);

  // ── Aliases so existing call sites keep working ──────────────────────
  static const Color brandTeal = cyan;
  static const Color sidebarFill = cyan;
  static const Color heroFill = cyan;
  static const Color adminCyan = cyan;
  static const Color adminCyanDark = cyanDark;
  static const Color onGold = dark;
  static const Color textMutedOnLight = textMuted;
  static const Color portalPageBg = bg;

  // ══════════════════════════════════════════════════════════════════════
  // MEMBER-PORTAL-ONLY SURFACES — no admin counterpart (admin sidebar is
  // white, admin is light-only). Kept as designed; do NOT expect a mirror.
  // ══════════════════════════════════════════════════════════════════════

  static const Color yellow = Color(0xFFFBBF24); // legacy member gold (gradients)
  static const Color green = Color(0xFFA3E635); // gradient stop only

  /// Legible tones for content sitting on the cyan fill.
  static const Color onTealMuted = Color(0xFFB9E6F1);
  static const Color onTealSubtle = Color(0xFFCDEEF5);

  /// Gold contrast sub-tones for the cyan sidebar / white active pill.
  static const Color goldOnCyan = Color(0xFFFFD24D); // gold icon on cyan
  static const Color goldOnCyanText = Color(0xFFFFECB3); // gold text on cyan
  static const Color goldPillIcon = Color(0xFFA16207); // gold icon on white pill

  /// Member form-field fill (kept per reconciliation item 4; admin's
  /// equivalent is [cyanBg] #E0F7FA).
  static const Color fieldFill = Color(0xFFEAF9FC);
  static const Color fieldBorder = Color(0xFFC7E9EF);

  /// Member sidebar user-card panel (kept per reconciliation item 4;
  /// admin's equivalent is [cyanDark] #0E8FA0).
  static const Color sidebarFooter = Color(0xFF0B5F76);

  // Dark-theme surfaces (member-only — admin is light-only).
  static const Color darkBg = Color(0xFF0A0A0B);
  static const Color darkCard = Color(0xFF15161A);
  static const Color darkBorder = Color(0xFF262832);
  static const Color textMutedOnDark = Color(0xFF9CA3AF);

  static const Color lightBg = Color(0xFFFFFFFF);
  static const Color lightGray = bg;

  /// Pastel fills for the small icon badges on stat / info cards.
  static const Color cyanTint = Color(0xFFDCF3FF);
  static const Color goldTint = Color(0xFFFFF3D6);

  /// Accent colours used to tint cards by meaning (kept within the
  /// cyan / gold family plus a positive-green and a warning-amber).
  static const Color accentCyan = cyan;
  static const Color accentGold = yellow;
  static const Color accentGreen = success; // #16A34A
  static const Color accentAmber = Color(0xFFD97706);
  static const Color accentViolet = plum; // unify on the plum purple

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
  /// Gold hover / pressed fill for gold buttons. (admin: goldDark)
  static final WidgetStateProperty<Color?> _goldStateBg =
      WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.disabled)) return const Color(0xFFEAD9A0);
    if (states.contains(WidgetState.pressed) ||
        states.contains(WidgetState.hovered)) {
      return AppColors.goldDark;
    }
    return AppColors.gold;
  });

  static final ElevatedButtonThemeData _goldButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: AppColors.onGold,
      disabledForegroundColor: const Color(0x8A0B0B0D),
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      textStyle: AppText.button(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ).copyWith(backgroundColor: _goldStateBg),
  );

  static final FilledButtonThemeData _goldFilledButtonTheme = FilledButtonThemeData(
    style: FilledButton.styleFrom(
      foregroundColor: AppColors.onGold,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      textStyle: AppText.button(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ).copyWith(backgroundColor: _goldStateBg),
  );

  static final OutlinedButtonThemeData _outlineButtonTheme = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.dark,
      backgroundColor: Colors.white,
      side: const BorderSide(color: AppColors.cardBorder),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      textStyle: AppText.button(),
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
      borderSide: const BorderSide(color: AppColors.cyan, width: 1.5),
    ),
  );

  /// Applies the [AppText] body / label weights onto a base Inter text
  /// theme so Material widgets inherit the scheme without per-widget
  /// overrides. Title/section colouring stays explicit at call sites
  /// (`AppText.sectionTitle()`) so it never bleeds onto AppBar / dialog
  /// titles. [bodyColor] is the default paragraph colour.
  static TextTheme _textTheme(TextTheme inter, Color bodyColor) => inter.copyWith(
        titleMedium: inter.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        titleSmall: inter.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        bodyLarge: inter.bodyLarge?.copyWith(fontSize: 14, color: bodyColor),
        bodyMedium: inter.bodyMedium?.copyWith(fontSize: 14, color: bodyColor),
        bodySmall: inter.bodySmall?.copyWith(fontSize: 12.5, color: bodyColor),
        labelLarge: inter.labelLarge
            ?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      );

  static ThemeData get themeData {
    // Inter is the app-wide typeface; page titles / wordmark use Archivo Black.
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.cyan,
        primary: AppColors.cyan,
        secondary: AppColors.gold,
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
    );
    final inter = GoogleFonts.interTextTheme(base.textTheme);
    return base.copyWith(
      textTheme: _textTheme(inter, const Color(0xFF1F2937)),
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
      textTheme: _textTheme(inter, AppColors.textMutedOnDark),
      elevatedButtonTheme: _goldButtonTheme,
      filledButtonTheme: _goldFilledButtonTheme,
      outlinedButtonTheme: _outlineButtonTheme,
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
