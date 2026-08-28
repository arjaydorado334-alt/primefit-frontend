import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../screens/membership_page.dart';
import '../screens/profile_settings.dart';
import '../screens/programs_page.dart';
import '../screens/progress_page.dart';
import '../screens/user_session.dart';
import '../widgets/qr_checkin_view.dart';

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
    final selected = selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() {
            selectedIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xffDDF7FC)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected
                    ? const Color(0xff18B7D9)
                    : Colors.grey[700],
              ),
              const SizedBox(width: 18),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: selected
                      ? FontWeight.bold
                      : FontWeight.w500,
                  color: selected
                      ? const Color(0xff18B7D9)
                      : Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().slideX(begin: -.2);
  }

  Widget _buildSidebar() {
    return Container(
      width: 300,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Color(0xffE5E7EB)),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    image: const DecorationImage(
                      image: AssetImage("assets/images/PrimeFit_Logo.png"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "PrimeFit",
                      style: TextStyle(
                        fontSize: 31,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff14B8E6),
                      ),
                    ),
                    Text(
                      "Member Portal",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          _navItem(Icons.dashboard_outlined, "Dashboard", 0),
          _navItem(Icons.show_chart, "Progress", 1),
          _navItem(Icons.fitness_center, "Programs", 2),
          _navItem(Icons.card_membership, "Membership", 3),
          _navItem(Icons.qr_code_scanner, "Check-In", 4),
          _navItem(Icons.person_outline, "Profile", 5),
          const Spacer(),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: Color(0xff14B8E6),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "John Doe",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "7 Months",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 500.ms);
  }
}

class _DashboardView extends StatelessWidget {
  final ValueChanged<int>? onNavigate;
  const _DashboardView({this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final session = UserSession.instance;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(session),
          const SizedBox(height: 25),
          _buildTopCards(session),
          const SizedBox(height: 25),
          _buildWeekTracker(session),
          const SizedBox(height: 25),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildSessionCredits(session)),
              const SizedBox(width: 20),
              Expanded(child: _buildMembershipCard(session)),
            ],
          ),
          const SizedBox(height: 30),
          _buildAttendanceList(),
          const SizedBox(height: 30),
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

  Widget _buildHeader(UserSession session) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome back, ${session.firstName}",
          style: const TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.bold,
            color: Color(0xff1F2937),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Here's a quick look at your activity.",
          style: TextStyle(fontSize: 20, color: Color(0xff6B7280)),
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
          child: _statCard(
            Icons.calendar_today,
            Colors.cyan.shade100,
            const Color(0xff06B6D4),
            Text('$visitsThisWeek', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            "Visits this week",
          ),
        ),
        const SizedBox(width: 22),
        Expanded(
          child: _statCard(
            Icons.local_fire_department,
            Colors.amber.shade100,
            Colors.orange,
            Text('$dayStreak', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            "Day streak",
          ),
        ),
        const SizedBox(width: 22),
        Expanded(
          child: _statCard(
            Icons.adjust,
            Colors.purple.shade100,
            Colors.deepPurple,
            Text('$monthlyGoal%', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            "Monthly goal",
          ),
        ),
      ],
    );
  }

  Widget _statCard(IconData icon, Color bg, Color iconColor, Widget number, String title) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(22),
        height: 165,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const Spacer(),
            number,
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontSize: 18, color: Colors.grey)),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("This Week", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('${weekActiveDays.length} visit${weekActiveDays.length == 1 ? '' : 's'} this week', style: const TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 72,
        height: 90,
        decoration: BoxDecoration(
          color: active ? const Color(0xffDDF7FC) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(day, style: TextStyle(fontWeight: FontWeight.bold, color: active ? const Color(0xff18B7D9) : Colors.grey)),
            const SizedBox(height: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? const Color(0xff18B7D9) : Colors.white,
                border: Border.all(color: active ? const Color(0xff18B7D9) : Colors.grey.shade300),
              ),
              child: active
                  ? const Icon(Icons.check, size: 20, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    ).animate().scale(end: const Offset(1.05, 1.05), duration: 200.ms, curve: Curves.easeOut).onHover();
  }

Widget _buildSessionCredits(UserSession session) {
    final used = session.sessionsUsed;
    final total = session.creditsTotal;
    final remaining = total - used;
    final usedPercent = total > 0 ? used / total : 0.0;
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xff18B7D9).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.confirmation_number_outlined, color: Color(0xff18B7D9), size: 20),
              ),
              const SizedBox(width: 12),
              const Text("Session Credits", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _creditStatCard(icon: Icons.check_circle_outline, label: 'Remaining', value: '$remaining', color: const Color(0xFF059669), bg: const Color(0xFFECFDF5))),
              const SizedBox(width: 16),
              Expanded(child: _creditStatCard(icon: Icons.access_time_outlined, label: 'Used This Period', value: '$used', color: const Color(0xFFD97706), bg: const Color(0xFFFFFBEB))),
              const SizedBox(width: 16),
              Expanded(child: _creditStatCard(icon: Icons.all_inclusive_outlined, label: 'Total Credits', value: '$total', color: const Color(0xff18B7D9), bg: const Color(0xffDDF7FC))),
            ],
          ),
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${(usedPercent * 100).round()}% used', style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                  Text('$remaining of $total left', style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: usedPercent.clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: const Color(0xFFF3F4F6),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xff18B7D9)),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fade().slideY(begin: .2).onHover(duration: 200.ms, curve: Curves.easeOut).scale(end: const Offset(1.02, 1.02));
  }

  Widget _creditStatCard({required IconData icon, required String label, required String value, required Color color, required Color bg}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.15))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

Widget _buildMembershipCard(UserSession session) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xff1CB5E0), Color(0xff000851)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Membership", style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 12),
          Text(session.membershipPlan, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 35),
          const Text("Valid Until", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(session.renewsOnLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: () => onNavigate?.call(3),
              child: const Text("Manage Membership", style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    ).animate().fade().slideX(begin: .2).onHover(duration: 200.ms, curve: Curves.easeOut).scale(end: const Offset(1.02, 1.02));
  }

  Widget _buildAttendanceList() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Attendance", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _attendanceRow("Mon, Jul 14", "09:30 AM", true),
          _attendanceRow("Tue, Jul 15", "08:15 AM", true),
          _attendanceRow("Wed, Jul 16", "10:00 AM", true),
          _attendanceRow("Thu, Jul 17", "07:45 AM", true),
          _attendanceRow("Fri, Jul 18", "09:00 AM", true),
          _attendanceRow("Sat, Jul 19", "11:30 AM", true),
          _attendanceRow("Sun, Jul 20", "08:00 AM", false),
        ],
      ),
    );
  }

  Widget _attendanceRow(String date, String time, bool checkedIn) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: checkedIn ? const Color(0xFFE7F9EE) : const Color(0xFFFFF3D6),
              borderRadius: BorderRadius.circular(8),
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
                Text(date, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(time, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: checkedIn ? const Color(0xFFE7F9EE) : const Color(0xFFFFF3D6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(checkedIn ? 'Checked In' : 'Absent', style: TextStyle(fontSize: 11, color: checkedIn ? const Color(0xFF16A34A) : Colors.orange, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Quick Actions", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _quickActionButton(Icons.qr_code_scanner, "Check-In", onTap: () => onNavigate?.call(4))),
              const SizedBox(width: 20),
              Expanded(child: _quickActionButton(Icons.bar_chart, "View Progress", onTap: () => onNavigate?.call(1))),
              const SizedBox(width: 20),
              Expanded(child: _quickActionButton(Icons.fitness_center, "My Programs", onTap: () => onNavigate?.call(2))),
            ],
          ),
        ],
      ),
    ).animate().fade().slideY(begin: .2);
  }

  Widget _quickActionButton(IconData icon, String title, {VoidCallback? onTap}) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade100,
        foregroundColor: Colors.black,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: child,
    );
  }
}

extension on Animate {
  Animate onHover({Duration? duration, Curve? curve}) => this;
}

