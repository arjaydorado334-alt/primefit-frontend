// THROWAWAY visual-preview harness — NOT part of the shipped app.
// Renders the member-portal shell (sidebar + each screen) with a mock
// UserSession so the redesign can be screenshotted without a backend or
// login. Run with:  flutter run -d chrome -t lib/portal_preview.dart
// or:               flutter build web -t lib/portal_preview.dart
//
// Safe to delete. It imports only existing widgets/screens and mutates
// the in-memory UserSession singleton; it touches no APIs itself (the
// screens' own service calls all no-op when dbMemberId is null).
import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'screens/user_session.dart';
import 'screens/membership_page.dart';
import 'screens/programs_page.dart';
import 'screens/profile_settings.dart';
import 'screens/progress_page.dart';
import 'widgets/dashboard_view.dart';
import 'widgets/member_sidebar.dart';
import 'widgets/qr_checkin_view.dart';

void main() {
  final s = UserSession.instance;
  s.firstName = 'Alex';
  s.lastName = 'Rivera';
  s.email = 'alex.rivera@example.com';
  s.membershipPlan = '7 Months';
  s.membershipStatus = 'Active';
  s.memberId = 'PF-2026-00142';
  s.creditsTotal = 30;
  s.sessionsUsed = 11;
  s.visitsThisWeek = 3;
  s.totalSessions = 68;
  s.planPrice = 3500;
  s.notificationsEnabled = false; // keep the alert banner quiet in preview
  s.qrCodeData = 'PREVIEW-QR-TOKEN-DEMO';
  s.visitDates
    ..clear()
    ..addAll([
      DateTime.now().subtract(const Duration(days: 1)),
      DateTime.now().subtract(const Duration(days: 3)),
      DateTime.now().subtract(const Duration(days: 5)),
    ]);
  runApp(const _PreviewApp());
}

class _PreviewApp extends StatelessWidget {
  const _PreviewApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Portal Preview',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: const _PreviewShell(),
    );
  }
}

class _PreviewShell extends StatefulWidget {
  const _PreviewShell();
  @override
  State<_PreviewShell> createState() => _PreviewShellState();
}

class _PreviewShellState extends State<_PreviewShell> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final s = UserSession.instance;
    final Widget body;
    switch (_i) {
      case 0:
        body = DashboardView(
          memberFirstName: s.firstName,
          visitsThisWeek: 3,
          dayStreak: 4,
          monthlyGoalPercent: 62,
          weekCheckins: const [true, false, true, true, false, null, null],
          planName: s.membershipPlan,
          renewsOn: 'March 12, 2026',
          monthlyRate: '₱3,500',
          sessionCreditsTotal: 30,
          sessionCreditsLeft: 19,
          sessionsUsed: 11,
          onGoToCheckIn: () => setState(() => _i = 2),
          onGoToMembership: () => setState(() => _i = 3),
        );
        break;
      case 1:
        body = const ProgressTrackerPage();
        break;
      case 2:
        body = QrCheckinView(
          memberName: s.fullName,
          memberId: s.memberId,
          planName: s.membershipPlan,
          memberSince: 'August 12, 2025',
          renewsOn: 'March 12, 2026',
          creditsTotal: 30,
          dbMemberId: null,
          initialSessionsUsed: 11,
          qrCodeData: s.qrCodeData,
        );
        break;
      case 3:
        body = const MembershipPage();
        break;
      case 4:
        body = const WorkoutProgramsScreen();
        break;
      case 5:
        body = const ProfileSettingsPage();
        break;
      default:
        body = const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: AppColors.portalPageBg,
      body: Row(
        children: [
          MemberSidebar(
            selectedIndex: _i,
            onSelect: (v) => setState(() => _i = v),
            onLogout: () {},
            memberName: s.fullName,
            memberTier: '${s.membershipPlan} Member',
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
