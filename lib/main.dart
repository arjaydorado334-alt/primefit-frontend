import 'package:flutter/material.dart';
import 'screens/landing_page.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.instance.loadFromPrefs();
  runApp(const PrimeFitApp());
}

class PrimeFitApp extends StatelessWidget {
  const PrimeFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) => MaterialApp(
        title: 'PrimeFit',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.themeData,
        darkTheme: AppTheme.darkThemeData,
        themeMode: ThemeController.instance.mode,
        home: const LandingPage(),
      ),
    );
  }
}
