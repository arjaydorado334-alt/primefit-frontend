import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/membership_page.dart';
import '../widgets/dashboard_view.dart';
import '../widgets/member_sidebar.dart';
import '../widgets/qr_checkin_view.dart';
import '../widgets/chat_fab_overlay.dart';
import 'programs_page.dart';
import 'landing_page.dart';
import 'progress_page.dart';
import 'profile_settings.dart';
import 'user_session.dart';
import 'dart:async';
import '../services/attendance_stats_service.dart';
import '../services/body_metrics_service.dart';
import '../services/food_logs_service.dart';
import '../services/notification_prefs_service.dart';

/// The authenticated area of the app. Holds the sidebar and swaps the
/// main content area based on which nav item is selected.
class MemberPortalScreen extends StatefulWidget {
  const MemberPortalScreen({super.key});

  @override
  State<MemberPortalScreen> createState() => _MemberPortalScreenState();
}

class _MemberPortalScreenState extends State<MemberPortalScreen> {
  int _selectedIndex = 0;
  Timer? _attendanceTimer;

  @override
  void initState() {
    super.initState();
    _fetchAttendanceStats();
    // Poll every 10 seconds so a front-desk QR scan (which happens on
    // a different device) shows up here without the member needing to
    // manually refresh the page.
    _attendanceTimer = Timer.periodic(
        const Duration(seconds: 10), (_) => _fetchAttendanceStats());
    _checkReminders();
    _loadNotificationPref();
  }

  Future<void> _loadNotificationPref() async {
    final memberId = UserSession.instance.dbMemberId;
    if (memberId == null) return;

    final enabled = await NotificationPrefsService.isEnabled(memberId);
    if (!mounted) return;

    setState(() => UserSession.instance.notificationsEnabled = enabled);
  }

  /// One-time check (not polled -- nothing here changes fast enough to
  /// need it) for the food-log and weigh-in reminder banners shown via
  /// [StatusAlertBanner]. Populates [UserSession] so those banners can
  /// read live computed getters, same as the membership/credits alerts.
  Future<void> _checkReminders() async {
    final memberId = UserSession.instance.dbMemberId;
    if (memberId == null) return;

    final results = await Future.wait([
      FoodLogsService.fetchLogs(memberId, date: DateTime.now()),
      BodyMetricsService.fetchHistory(memberId),
    ]);
    if (!mounted) return;

    final foodResult = results[0];
    final metricsResult = results[1];

    final hasLoggedFoodToday = foodResult['success'] == true &&
        foodResult['logs'] is List &&
        (foodResult['logs'] as List).isNotEmpty;

    DateTime? lastBodyMetricDate;
    if (metricsResult['success'] == true && metricsResult['metrics'] is List) {
      final metrics = metricsResult['metrics'] as List;
      if (metrics.isNotEmpty) {
        try {
          lastBodyMetricDate =
              DateTime.parse(metrics.first['RecordedAt'].toString());
        } catch (_) {}
      }
    }

    setState(() {
      UserSession.instance.hasLoggedFoodToday = hasLoggedFoodToday;
      UserSession.instance.lastBodyMetricDate = lastBodyMetricDate;
      UserSession.instance.remindersChecked = true;
    });
  }

  @override
  void dispose() {
    _attendanceTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchAttendanceStats() async {
    final memberId = UserSession.instance.dbMemberId;
    if (memberId == null) return;

    final result = await AttendanceStatsService.fetchStats(memberId);
    if (!mounted) return;

    if (result['success'] == true && result['visit_dates'] is List) {
      final parsedDates = <DateTime>[];
      for (final raw in (result['visit_dates'] as List)) {
        try {
          parsedDates.add(DateTime.parse(raw.toString()));
        } catch (_) {}
      }

      final now = DateTime.now();
      final monday = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      final thisWeekDays = parsedDates
          .map((d) => DateTime(d.year, d.month, d.day))
          .where((d) => !d.isBefore(monday))
          .toSet();

      setState(() {
        UserSession.instance.visitDates
          ..clear()
          ..addAll(parsedDates);
        UserSession.instance.visitsThisWeek = thisWeekDays.length;
        UserSession.instance.totalSessions =
            int.tryParse('${result['total_sessions']}') ??
                UserSession.instance.totalSessions;
      });
    }
  }

  void _selectTab(int index) => setState(() => _selectedIndex = index);

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LandingPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sidebar collapses to a drawer only on phone; tablet keeps the
    // (fixed-width) sidebar visible alongside content, same as desktop.
    final isWide = !context.isMobile;
    final session = UserSession.instance;

    final content = ChatFabOverlay(
  memberId: session.dbMemberId,
  child: _buildContent(),
);

    return Scaffold(
      backgroundColor: context.isDarkMode ? AppColors.darkBg : AppColors.lightGray,
      drawer: isWide
          ? null
          : Drawer(
              child: MemberSidebar(
                selectedIndex: _selectedIndex,
                onSelect: (i) {
                  _selectTab(i);
                  Navigator.of(context).pop();
                },
                onLogout: _logout,
                memberName: session.fullName,
                memberTier: session.membershipPlan,
              ),
            ),
      appBar: isWide
          ? null
          : AppBar(
              backgroundColor: context.isDarkMode ? AppColors.darkCard : Colors.white,
              foregroundColor: context.isDarkMode ? Colors.white : Colors.black,
              elevation: 0,
              title: Text(sidebarItems[_selectedIndex].label),
            ),
      body: Row(
        children: [
          if (isWide)
            MemberSidebar(
              selectedIndex: _selectedIndex,
              onSelect: _selectTab,
              onLogout: _logout,
              memberName: session.fullName,
              memberTier: session.membershipPlan,
            ),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final session = UserSession.instance;
    switch (_selectedIndex) {
      case 0:
        return DashboardView(
          memberFirstName: session.firstName,
          visitsThisWeek: session.visitsThisWeek,
          dayStreak: session.dayStreak,
          monthlyGoalPercent: session.monthlyGoalPercent,
          weekCheckins: session.weekCheckins,
          planName: session.membershipPlan,
          renewsOn: session.renewsOnLabel,
          monthlyRate: session.planPriceLabel,
          sessionCreditsTotal: session.creditsTotal,
          sessionCreditsLeft: session.creditsTotal - session.sessionsUsed,
          sessionsUsed: session.sessionsUsed,
          onGoToCheckIn: () => _selectTab(2),
          onGoToMembership: () => _selectTab(3),
        );
      case 1:
        return const ProgressTrackerPage();
      case 2:
        return QrCheckinView(
          memberName: session.fullName,
          memberId: session.memberId,
          planName: session.membershipPlan,
          memberSince: session.memberSinceLabel,
          renewsOn: session.renewsOnLabel,
          creditsTotal: session.creditsTotal,
          dbMemberId: session.dbMemberId,
          initialSessionsUsed: session.sessionsUsed,
          qrCodeData: session.qrCodeData,
        );
      case 3:
        return const MembershipPage();
      case 4:
        return const WorkoutProgramsScreen();
      case 5:
        return const ProfileSettingsPage();
      default:
        return const SizedBox.shrink();
    }
  }
}