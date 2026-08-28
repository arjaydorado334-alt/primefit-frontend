import 'package:flutter/material.dart';

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
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.lightBg,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.cyan),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Color(0xFF1F2937)),
      ),
    );
  }

  static ThemeData get darkThemeData {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.cyan, brightness: Brightness.dark),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: AppColors.textMutedOnDark),
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
