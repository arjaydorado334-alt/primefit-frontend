import 'package:flutter/material.dart';
import 'screens/landing_page.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const PrimeFitApp());
}

class PrimeFitApp extends StatelessWidget {
  const PrimeFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PrimeFit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: const LandingPage(),
    );
  }
}
