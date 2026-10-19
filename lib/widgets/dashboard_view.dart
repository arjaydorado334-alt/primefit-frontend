import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/user_session.dart';
import 'status_alert_banner.dart';

class _Colors {
  static bool _dark = false;
  static void sync(BuildContext c) => _dark = Theme.of(c).brightness == Brightness.dark;

  static Color get cardBg => _dark ? AppColors.darkCard : Colors.white;
  static Color get cardBorder => _dark ? AppColors.darkBorder : AppColors.cardBorder;
  static Color get heading => _dark ? Colors.white : const Color(0xFF1F2937);
  static Color get textSecondary => _dark ? AppColors.textMutedOnDark : Colors.grey.shade600;
  static Color get textMuted => _dark ? AppColors.textMutedOnDark : Colors.grey.shade500;
  static Color get mutedSurface => _dark ? AppColors.darkBorder : const Color(0xFFF1F2F4);
  static Color get progressTrackBg => _dark ? AppColors.darkBorder : const Color(0xFFEDEEF0);
  static List<BoxShadow> get cardShadow =>
      _dark ? const [] : AppColors.softCardShadow;

  /// Status-pill background, blended toward the dark card surface in dark
  /// mode instead of using the light pastel tint at full strength.
  static Color badgeBg(Color accent, Color lightBg) =>
      _dark ? Color.alphaBlend(accent.withValues(alpha: 0.18), AppColors.darkCard) : lightBg;

  /// Matching pill text colour: lightened toward white in dark mode.
  static Color badgeFg(Color accent, Color lightFg) =>
      _dark ? (Color.lerp(accent, Colors.white, 0.45) ?? accent) : lightFg;
}

class DashboardView extends StatelessWidget {
  final String memberFirstName;
  final int visitsThisWeek;
  final int dayStreak;
  final int monthlyGoalPercent;
  final int monthlyVisits;
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
    this.monthlyVisits = 0,
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
    _Colors.sync(context);
    final isWide = MediaQuery.of(context).size.width > 900;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          const SizedBox(height: 20),
          StatusAlertBanner(session: UserSession.instance, onManageTap: onGoToMembership),
          const SizedBox(height: 4),
          _statGrid(),
          const SizedBox(height: 20),
          _weekCard(),
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
          Text('QUICK ACTIONS',
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _Colors.textMuted,
                  letterSpacing: 1.1)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _QuickAction(icon: Icons.qr_code_2, label: 'Check-In', onTap: onGoToCheckIn),
            ],
          ),
        ],
      ),
    );
  }

  /// Plain page title (replaces the big cyan banner).
  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back, $memberFirstName',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: _Colors.heading,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Here's a quick look at your activity.",
          style: TextStyle(fontSize: 14, color: _Colors.textSecondary),
        ),
      ],
    );
  }

  /// Four KPI cards that share the full width (2 per row on narrower
  /// windows, 1 per row on phones).
  Widget _statGrid() {
    final cards = <Widget>[
      _StatCard(icon: Icons.calendar_today_outlined, value: '$visitsThisWeek', label: 'Visits this week'),
      _StatCard(icon: Icons.local_fire_department, value: '$dayStreak', label: 'Day streak'),
      _StatCard(icon: Icons.adjust, value: '$monthlyGoalPercent%', label: 'Monthly goal'),
      _StatCard(icon: Icons.event_available_outlined, value: '$monthlyVisits', label: 'Monthly attendance'),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final cols = w >= 900 ? 4 : (w >= 520 ? 2 : 1);
      const gap = 16.0;
      final cardWidth = (w - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final c in cards) SizedBox(width: cardWidth, child: c),
        ],
      );
    });
  }

  Widget _weekCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelTitle('This Week'),
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
                          color: state == true ? AppColors.cyan : _Colors.mutedSurface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: state == true
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : null,
                      ),
                      const SizedBox(height: 6),
                      Text(_days[i], style: TextStyle(fontSize: 12, color: _Colors.textSecondary)),
                    ],
                  ),
                ),
              );
            }),
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
              const _PanelTitle('Session Credits'),
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
                      backgroundColor: _Colors.progressTrackBg,
                      valueColor: const AlwaysStoppedAnimation(AppColors.cyan),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$sessionCreditsLeft',
                            style: AppText.statNumber(size: 16, color: _Colors.heading)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$sessionCreditsLeft/$sessionCreditsTotal',
                      style: AppText.statNumber(size: 20, color: _Colors.heading)),
                  Text('$sessionsUsed sessions used', style: TextStyle(color: _Colors.textSecondary, fontSize: 12.5)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _membershipCard() {
    final session = UserSession.instance;
    // Style-only: the colored left bar only shows when the membership is
    // expiring or expired (needs attention).
    final needsAttention =
        session.isMembershipExpired || session.isMembershipExpiringSoon;
    return _Card(
      accent: needsAttention ? AppColors.accentAmber : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _PanelTitle('Membership'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: _Colors.badgeBg(AppColors.success, AppColors.successBg),
                    borderRadius: BorderRadius.circular(20)),
                child: Text('Active',
                    style: AppText.badgeLabel(
                        color: _Colors.badgeFg(AppColors.success, AppColors.success))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Current Plan', style: TextStyle(color: _Colors.textMuted, fontSize: 12)),
          Text(planName, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _Colors.heading)),
          const SizedBox(height: 12),
          Text('Renews on', style: TextStyle(color: _Colors.textMuted, fontSize: 12)),
          Text(renewsOn, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _Colors.heading)),
          const SizedBox(height: 12),
          Text('Monthly Rate', style: TextStyle(color: _Colors.textMuted, fontSize: 12)),
          Text(monthlyRate, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _Colors.heading)),
        ],
      ),
    );
  }
}

/// Small uppercase gray card title (Haws Prints style).
class _PanelTitle extends StatelessWidget {
  final String text;
  const _PanelTitle(this.text);

  @override
  Widget build(BuildContext context) {
    _Colors.sync(context);
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: _Colors.textSecondary,
      ),
    );
  }
}

/// Neutral white card with a hairline border and soft shadow. [accent] draws
/// a thin colored bar on the left edge, reserved for cards that need attention.
class _Card extends StatelessWidget {
  final Widget child;
  final Color? accent;
  const _Card({required this.child, this.accent});

  @override
  Widget build(BuildContext context) {
    _Colors.sync(context);
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _Colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Colors.cardBorder),
        boxShadow: _Colors.cardShadow,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
          if (accent != null)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 4, color: accent),
            ),
        ],
      ),
    );
  }
}

/// KPI card: small gray label + small cyan icon tile on top, big bold number
/// underneath. No tinted fill, so every card matches.
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    _Colors.sync(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      decoration: BoxDecoration(
        color: _Colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Colors.cardBorder),
        boxShadow: _Colors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _Colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: AppColors.cyan),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: AppText.statNumber(size: 32, color: _Colors.heading)),
        ],
      ),
    );
  }
}

/// Quick action as an outlined pill (Haws Prints "View" button style).
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    _Colors.sync(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _Colors.heading.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: _Colors.heading),
              const SizedBox(width: 10),
              Text(label,
                  style: TextStyle(fontWeight: FontWeight.w600, color: _Colors.heading)),
            ],
          ),
        ),
      ),
    );
  }
}
