import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/user_session.dart';
import 'status_alert_banner.dart';

class DashboardView extends StatelessWidget {
  final String memberFirstName;
  final int visitsThisWeek;
  final int dayStreak;
  final int monthlyGoalPercent;
  final List<bool?> weekCheckins; // null = future day, true = checked, false = missed
  final int sessionCreditsLeft;
  final int sessionCreditsTotal;
  final int sessionsUsed;
  final String planName;
  final String renewsOn;
  final String monthlyRate;
  final VoidCallback onGoToCheckIn;
  final VoidCallback? onGoToMembership;

  const DashboardView({
    super.key,
    this.memberFirstName = 'John',
    this.visitsThisWeek = 0,
    this.dayStreak = 0,
    this.monthlyGoalPercent = 0,
    this.weekCheckins = const [],
    this.sessionCreditsLeft = 0,
    this.sessionCreditsTotal = 0,
    this.sessionsUsed = 0,
    this.planName = 'Premium · 1 Month',
    this.renewsOn = 'July 10, 2026',
    this.monthlyRate = '₱1,299',
    required this.onGoToCheckIn,
    this.onGoToMembership,
  });

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome back, $memberFirstName', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text("Here's a quick look at your activity.", style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 20),
          StatusAlertBanner(session: UserSession.instance, onManageTap: onGoToMembership),
          const SizedBox(height: 4),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _StatCard(icon: Icons.calendar_today_outlined, iconBg: const Color(0xFFDCF3FF), value: '$visitsThisWeek', label: 'Visits this week'),
              _StatCard(icon: Icons.local_fire_department, iconBg: const Color(0xFFFFF3D6), value: '$dayStreak', label: 'Day streak'),
              _StatCard(icon: Icons.adjust, iconBg: const Color(0xFFF0E6FF), value: '$monthlyGoalPercent%', label: 'Monthly goal'),
            ],
          ),
          const SizedBox(height: 20),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('This Week', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 16),
                Row(
                  children: List.generate(_days.length, (i) {
                    final state = i < weekCheckins.length ? weekCheckins[i] : null;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          children: [
                            Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: state == true ? AppColors.cyan : const Color(0xFFF1F2F4),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: state == true
                                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                                  : null,
                            ),
                            const SizedBox(height: 6),
                            Text(_days[i], style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _sessionCreditsCard()),
                    const SizedBox(width: 20),
                    Expanded(child: _membershipCard()),
                  ],
                )
              : Column(children: [_sessionCreditsCard(), const SizedBox(height: 20), _membershipCard()]),
          const SizedBox(height: 24),
          const Text('QUICK ACTIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey, letterSpacing: 1)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _QuickAction(icon: Icons.qr_code_2, label: 'Check-In', bg: const Color(0xFFDCF3FF), onTap: onGoToCheckIn),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sessionCreditsCard() {
    final progress = sessionCreditsTotal == 0 ? 0.0 : (sessionCreditsTotal - sessionCreditsLeft) / sessionCreditsTotal;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Session Credits', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              TextButton.icon(
                onPressed: onGoToCheckIn,
                icon: const Icon(Icons.qr_code_2, size: 16, color: AppColors.cyan),
                label: const Text('Check-In', style: TextStyle(color: AppColors.cyan, fontSize: 13)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 6,
                      backgroundColor: const Color(0xFFEDEEF0),
                      valueColor: const AlwaysStoppedAnimation(AppColors.cyan),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$sessionCreditsLeft', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$sessionCreditsLeft/$sessionCreditsTotal', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                  Text('$sessionsUsed sessions used', style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _membershipCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Membership', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFE7F9EE), borderRadius: BorderRadius.circular(20)),
                child: const Text('Active', style: TextStyle(color: Color(0xFF16A34A), fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Current Plan', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          Text(planName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 12),
          Text('Renews on', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          Text(renewsOn, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 12),
          Text('Monthly Rate', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          Text(monthlyRate, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.yellow)),
        ],
      ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: child,
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String value;
  final String label;

  const _StatCard({required this.icon, required this.iconBg, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: Colors.black87),
          ),
          const SizedBox(height: 14),
          Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.bg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: Icon(icon, size: 20, color: Colors.black87),
              ),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
