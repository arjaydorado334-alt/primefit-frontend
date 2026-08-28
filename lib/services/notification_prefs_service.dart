import 'package:shared_preferences/shared_preferences.dart';

/// Per-account notifications preference (whether StatusAlertBanner shows
/// for this member). Local-only -- no backend call, so unlike the other
/// services in this folder this doesn't hit a PHP endpoint, it just reads
/// and writes a member-scoped key in shared_preferences.
class NotificationPrefsService {
  NotificationPrefsService._();

  static String _key(int memberId) => 'notifications_enabled_$memberId';

  static Future<bool> isEnabled(int memberId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(memberId)) ?? true;
  }

  static Future<void> setEnabled(int memberId, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(memberId), enabled);
  }
}
