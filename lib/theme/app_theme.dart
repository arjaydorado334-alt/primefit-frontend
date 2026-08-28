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
}
