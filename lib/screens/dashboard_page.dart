import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/membership_page.dart';
import '../screens/profile_settings.dart';
import '../screens/programs_page.dart';
import '../screens/progress_page.dart';
import '../screens/user_session.dart';
import '../theme/app_theme.dart';
import '../widgets/qr_checkin_view.dart';

/// Colors used by this page (light page, same palette as the admin portal).
class _Ui {
  static const Color cyan = Color(0xff18B7D9);
  static const Color heading = Color(0xff1F2937);
  static const Color muted = Color(0xff6B7280);
  static const Color border = Color(0xffE5E7EB);
  static const Color subtle = Color(0xffF3F4F6);

  /// Muted white used on the dark sidebar.
  static const Color railMuted = Color(0x8CFFFFFF);
  static const Color railDivider = Color(0x14FFFFFF);
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
_pages = [
      _DashboardView(onNavigate: (index) {
        setState(() => selectedIndex = index);
      }),
      const WorkoutProgramsScreen(),
      const MembershipPage(),
      const QrCheckinView(
        memberName: 'John Doe',
        memberId: 'PF-2026-00000',
        planName: '7 Months',
        memberSince: 'July 2025',
        renewsOn: 'July 10, 2026',
        creditsTotal: 30,
        dbMemberId: 4,
        initialSessionsUsed: 12,
        qrCodeData: '',
      ),
      const ProgressTrackerPage(),
      const ProfileSettingsPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(child: _pages[selectedIndex]),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xff18B7D9),
        onPressed: () {},
        child: const Icon(Icons.chat_bubble_outline),
      ).animate().scale(),
    );
  }

  Widget _navItem(IconData icon, String title, int index) {
    return _NavTile(
      icon: icon,
      title: title,
      selected: selectedIndex == index,
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
    ).animate().slideX(begin: -.2);
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      // Same dark gray the dark-mode version uses.
      color: AppColors.darkCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------------- Branding ----------------
          // Logo + wordmark directly on the rail ("Prime" cyan, "Fit" gold).
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 1.5,
                    ),
                    image: const DecorationImage(
                      image: AssetImage("assets/images/PrimeFit_Logo.png"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        style: GoogleFonts.archivoBlack(
                          fontSize: 18,
                          letterSpacing: -0.3,
                        ),
                        children: const [
                          TextSpan(text: 'Prime', style: TextStyle(color: _Ui.cyan)),
                          TextSpan(text: 'Fit', style: TextStyle(color: AppColors.gold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Member Portal'.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        color: _Ui.railMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ---------------- Navigation ----------------
          const Padding(
            padding: EdgeInsets.fromLTRB(26, 18, 20, 8),
            child: Text(
              'MY PORTAL',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: _Ui.railMuted,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                _navItem(Icons.dashboard_outlined, "Dashboard", 0),
                _navItem(Icons.show_chart, "Progress", 1),
                _navItem(Icons.fitness_center, "Programs", 2),
                _navItem(Icons.card_membership, "Membership", 3),
                _navItem(Icons.qr_code_scanner, "Check-In", 4),
                _navItem(Icons.person_outline, "Profile", 5),
              ],
            ),
          ),
          const Spacer(),
          const Divider(height: 1, color: _Ui.railDivider),

          // ---------------- Member profile + Sign Out ----------------
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _Ui.cyan.withValues(alpha: 0.18),
                    border: Border.all(color: _Ui.cyan.withValues(alpha: 0.45)),
                  ),
                  child: const Icon(Icons.person, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "John Doe",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "7 Months",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
            child: _SignOutTile(onTap: () {}),
          ),
        ],
      ),
    ).animate().fade(duration: 500.ms);
  }
}

/// One sidebar row: active = cyan-tinted pill with a cyan border; hover = a
/// light cyan wash; inactive = muted white.
class _NavTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.selected;
    const cyan = _Ui.cyan;

    final Color rowBg = active
        ? cyan.withValues(alpha: 0.28)
        : (_hovered ? cyan.withValues(alpha: 0.20) : Colors.transparent);
    final Color borderColor = active
        ? cyan.withValues(alpha: 0.55)
        : (_hovered ? cyan.withValues(alpha: 0.30) : Colors.transparent);
    final Color textColor =
        (active || _hovered) ? Colors.white : Colors.white.withValues(alpha: 0.72);
    final Color iconColor =
        (active || _hovered) ? cyan : Colors.white.withValues(alpha: 0.65);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: rowBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Row(
                  children: [
                    Icon(widget.icon, size: 19, color: iconColor),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                          letterSpacing: -0.1,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sign Out row: quiet by default, soft red on hover.
class _SignOutTile extends StatefulWidget {
  final VoidCallback onTap;
  const _SignOutTile({required this.onTap});

  @override
  State<_SignOutTile> createState() => _SignOutTileState();
}

class _SignOutTileState extends State<_SignOutTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final Color fg =
        _hovered ? const Color(0xFFFCA5A5) : Colors.white.withValues(alpha: 0.65);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          hoverColor: const Color(0x14FFFFFF),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Icon(Icons.logout, size: 18, color: fg),
                const SizedBox(width: 13),
                Text(
                  'Sign Out',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.1,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardView extends StatelessWidget {
  final ValueChanged<int>? onNavigate;
  const _DashboardView({this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final session = UserSession.instance;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(session),
          const SizedBox(height: 24),
          _buildTopCards(session),
          const SizedBox(height: 24),
          _buildWeekTracker(session),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildSessionCredits(session)),
              const SizedBox(width: 20),
              Expanded(child: _buildMembershipCard(session)),
            ],
          ),
          const SizedBox(height: 24),
          _buildAttendanceList(),
          const SizedBox(height: 24),
          _buildQuickActions(),
        ],
      ),
    );
  }

  int _computeDayStreak(UserSession session) {
    if (session.visitDates.isEmpty) return 0;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final visitSet = session.visitDates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet();
    if (!visitSet.contains(todayDate)) {
      final yesterday = todayDate.subtract(const Duration(days: 1));
      if (!visitSet.contains(yesterday)) return 0;
    }
    var streak = 0;
    var checkDate = todayDate;
    while (true) {
      if (visitSet.contains(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  /// Small uppercase gray card title.
  Widget _panelTitle(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: _Ui.muted,
      ),
    );
  }

  Widget _buildHeader(UserSession session) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome back, ${session.firstName}",
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: _Ui.heading,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Here's a quick look at your activity.",
          style: TextStyle(fontSize: 14, color: _Ui.muted),
        ),
      ],
    ).animate().fade().slideY(begin: -.2);
  }

  Widget _buildTopCards(UserSession session) {
    final visitsThisWeek = session.visitsThisWeek;
    final dayStreak = _computeDayStreak(session);
    final monthlyGoal = session.creditsTotal > 0 ? ((session.sessionsUsed / session.creditsTotal) * 100).round() : 0;
    return Row(
      children: [
        Expanded(
          child: _statCard(Icons.calendar_today, '$visitsThisWeek', "Visits this week"),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _statCard(Icons.local_fire_department, '$dayStreak', "Day streak"),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _statCard(Icons.adjust, '$monthlyGoal%', "Monthly goal"),
        ),
      ],
    );
  }

  /// KPI card: small gray label + small cyan icon tile on top, big bold number.
  Widget _statCard(IconData icon, String value, String title) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: _Panel(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _Ui.muted,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _Ui.cyan.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: _Ui.cyan),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: _Ui.heading,
              ),
            ),
          ],
        ),
      ),
    ).animate().fade().slideY(begin: .2);
  }

  Widget _buildWeekTracker(UserSession session) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekDates = <DateTime>[];
    for (var i = 0; i < 7; i++) {
      weekDates.add(monday.add(Duration(days: i)));
    }
    final visitDates = session.visitDates;
    final weekActiveDays = <int>{};
    for (final vd in visitDates) {
      if (vd.year == now.year && vd.month == now.month) {
        for (var i = 0; i < 7; i++) {
          final wd = weekDates[i];
          if (vd.year == wd.year && vd.month == wd.month && vd.day == wd.day) {
            weekActiveDays.add(vd.weekday);
            break;
          }
        }
      }
    }
    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return _Panel(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle("This Week"),
          const SizedBox(height: 6),
          Text(
            '${weekActiveDays.length} visit${weekActiveDays.length == 1 ? '' : 's'} this week',
            style: const TextStyle(color: _Ui.muted, fontSize: 14),
          ),
          const SizedBox(height: 22),
          Row(
            children: List.generate(7, (index) {
              final isActive = weekActiveDays.contains(weekDates[index].weekday);
              return _dayCard(dayLabels[index], isActive);
            }),
          ),
        ],
      ),
    ).animate().fade().slideY(begin: .15);
  }

  Widget _dayCard(String day, bool active) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 90,
            decoration: BoxDecoration(
              color: active ? _Ui.cyan.withValues(alpha: 0.10) : _Ui.subtle,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: active ? _Ui.cyan.withValues(alpha: 0.35) : Colors.transparent,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: active ? _Ui.cyan : _Ui.muted,
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active ? _Ui.cyan : Colors.white,
                    border: Border.all(color: active ? _Ui.cyan : _Ui.border),
                  ),
                  child: active
                      ? const Icon(Icons.check, size: 19, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
        ).animate().scale(end: const Offset(1.05, 1.05), duration: 200.ms, curve: Curves.easeOut).onHover(),
      ),
    );
  }

Widget _buildSessionCredits(UserSession session) {
    final used = session.sessionsUsed;
    final total = session.creditsTotal;
    final remaining = total - used;
    final usedPercent = total > 0 ? used / total : 0.0;
    return _Panel(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _Ui.cyan.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.confirmation_number_outlined, color: _Ui.cyan, size: 18),
              ),
              const SizedBox(width: 12),
              _panelTitle("Session Credits"),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(child: _creditStatCard(icon: Icons.check_circle_outline, label: 'Remaining', value: '$remaining', color: const Color(0xFF059669))),
              const SizedBox(width: 14),
              Expanded(child: _creditStatCard(icon: Icons.access_time_outlined, label: 'Used This Period', value: '$used', color: const Color(0xFFD97706))),
              const SizedBox(width: 14),
              Expanded(child: _creditStatCard(icon: Icons.all_inclusive_outlined, label: 'Total Credits', value: '$total', color: _Ui.cyan)),
            ],
          ),
          const SizedBox(height: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${(usedPercent * 100).round()}% used', style: const TextStyle(fontSize: 13, color: _Ui.muted, fontWeight: FontWeight.w500)),
                  Text('$remaining of $total left', style: const TextStyle(fontSize: 13, color: _Ui.muted, fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: usedPercent.clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: _Ui.subtle,
                  valueColor: const AlwaysStoppedAnimation<Color>(_Ui.cyan),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fade().slideY(begin: .2).onHover(duration: 200.ms, curve: Curves.easeOut).scale(end: const Offset(1.02, 1.02));
  }

  /// Neutral credit tile: only the small icon carries a color.
  Widget _creditStatCard({required IconData icon, required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Ui.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: _Ui.heading)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: _Ui.muted, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

Widget _buildMembershipCard(UserSession session) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        // Dark gray (same as the sidebar) instead of the cyan-to-navy gradient.
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "MEMBERSHIP",
            style: TextStyle(
              color: _Ui.railMuted,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(session.membershipPlan, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 28),
          const Text("Valid Until", style: TextStyle(color: _Ui.railMuted)),
          const SizedBox(height: 6),
          Text(session.renewsOnLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20)),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _Ui.heading,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const StadiumBorder(),
              ),
              onPressed: () => onNavigate?.call(3),
              child: const Text("Manage Membership", style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    ).animate().fade().slideX(begin: .2).onHover(duration: 200.ms, curve: Curves.easeOut).scale(end: const Offset(1.02, 1.02));
  }

  Widget _buildAttendanceList() {
    final rows = <List<dynamic>>[
      ["Mon, Jul 14", "09:30 AM", true],
      ["Tue, Jul 15", "08:15 AM", true],
      ["Wed, Jul 16", "10:00 AM", true],
      ["Thu, Jul 17", "07:45 AM", true],
      ["Fri, Jul 18", "09:00 AM", true],
      ["Sat, Jul 19", "11:30 AM", true],
      ["Sun, Jul 20", "08:00 AM", false],
    ];
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle("Attendance"),
          const SizedBox(height: 8),
          for (var i = 0; i < rows.length; i++)
            _attendanceRow(rows[i][0] as String, rows[i][1] as String, rows[i][2] as bool, first: i == 0),
        ],
      ),
    );
  }

  Widget _attendanceRow(String date, String time, bool checkedIn, {bool first = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: first ? null : const Border(top: BorderSide(color: _Ui.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: checkedIn ? const Color(0xFFE7F9EE) : const Color(0xFFFFF3D6),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(
              checkedIn ? Icons.check_circle : Icons.access_time,
              size: 18,
              color: checkedIn ? const Color(0xFF16A34A) : Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: _Ui.heading)),
                Text(time, style: const TextStyle(color: _Ui.muted, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: checkedIn ? const Color(0xFFE7F9EE) : const Color(0xFFFFF3D6),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(checkedIn ? 'Checked In' : 'Absent', style: TextStyle(fontSize: 11.5, color: checkedIn ? const Color(0xFF16A34A) : Colors.orange, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return _Panel(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelTitle("Quick Actions"),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _quickActionButton(Icons.qr_code_scanner, "Check-In", onTap: () => onNavigate?.call(4))),
              const SizedBox(width: 16),
              Expanded(child: _quickActionButton(Icons.bar_chart, "View Progress", onTap: () => onNavigate?.call(1))),
              const SizedBox(width: 16),
              Expanded(child: _quickActionButton(Icons.fitness_center, "My Programs", onTap: () => onNavigate?.call(2))),
            ],
          ),
        ],
      ),
    ).animate().fade().slideY(begin: .2);
  }

  Widget _quickActionButton(IconData icon, String title, {VoidCallback? onTap}) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: _Ui.heading,
        side: BorderSide(color: _Ui.heading.withValues(alpha: 0.35)),
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: const StadiumBorder(),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

/// White rounded card with a hairline border and soft shadow.
class _Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _Panel({required this.child, this.padding = const EdgeInsets.all(24)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Ui.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return _Panel(padding: const EdgeInsets.all(24), child: child);
  }
}

extension on Animate {
  Animate onHover({Duration? duration, Curve? curve}) => this;
}
