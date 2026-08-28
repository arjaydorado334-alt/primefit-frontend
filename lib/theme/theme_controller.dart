import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide dark mode switch, persisted globally (not per-account).
/// A plain singleton `ChangeNotifier` -- mirrors `UserSession`'s singleton
/// style -- so `MaterialApp` can listen for changes without pulling in a
/// state-management package.
class ThemeController extends ChangeNotifier {
  ThemeController._internal();
  static final ThemeController instance = ThemeController._internal();

  static const _prefsKey = 'dark_mode_enabled';

  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _mode = (prefs.getBool(_prefsKey) ?? false) ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> setDarkMode(bool enabled) async {
    _mode = enabled ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, enabled);
  }
}
