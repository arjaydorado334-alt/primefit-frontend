import 'package:flutter/material.dart';
import '../screens/user_session.dart';
import '../theme/app_theme.dart';

/// Shows contextual alert banners for membership expiry and low session
/// credits. Renders nothing if neither condition applies. [onManageTap]
/// is called when the action button is tapped -- pass null to hide the
/// button (e.g. on pages that don't need a navigation shortcut).
class StatusAlertBanner extends StatelessWidget {
  final UserSession session;
  final VoidCallback? onManageTap;

  const StatusAlertBanner({super.key, required this.session, this.onManageTap});

  @override
  Widget build(BuildContext context) {
    if (!session.notificationsEnabled) return const SizedBox.shrink();

    final banners = <Widget>[];

    if (session.isMembershipExpired) {
      banners.add(_Banner(
        icon: Icons.error_outline,
        color: const Color(0xFFDC2626),
        bg: const Color(0xFFFEF2F2),
        border: const Color(0xFFFECACA),
        title: 'Your membership has expired',
        subtitle:
            'Renew your plan to keep checking in and earning session credits.',
        actionLabel: 'Renew Now',
        onTap: onManageTap,
      ));
    } else if (session.isMembershipExpiringSoon) {
      final days = session.daysUntilRenewal;
      banners.add(_Banner(
        icon: Icons.schedule,
        color: const Color(0xFFD97706),
        bg: const Color(0xFFFFFBEB),
        border: const Color(0xFFFDE68A),
        title: days <= 0
            ? 'Your membership renews today'
            : 'Membership expiring in $days day${days == 1 ? '' : 's'}',
        subtitle: 'Renew now to avoid any interruption to your access.',
        actionLabel: 'Renew Now',
        onTap: onManageTap,
      ));
    }

    if (session.isCreditsLow) {
      final left = session.creditsTotal - session.sessionsUsed;
      banners.add(_Banner(
        icon: Icons.confirmation_number_outlined,
        color: const Color(0xFFD97706),
        bg: const Color(0xFFFFFBEB),
        border: const Color(0xFFFDE68A),
        title: 'Session credits running low',
        subtitle:
            'Only $left of ${session.creditsTotal} credits left this period.',
        actionLabel: 'View Plans',
        onTap: onManageTap,
      ));
    }

    if (session.needsFoodReminder) {
      banners.add(const _Banner(
        icon: Icons.restaurant_outlined,
        color: Color(0xFF2563EB),
        bg: Color(0xFFEFF6FF),
        border: Color(0xFFBFDBFE),
        title: "You haven't logged food today",
        subtitle:
            'Log a meal in Progress Tracker to keep your nutrition on track.',
        actionLabel: '',
        onTap: null,
      ));
    }

    if (session.needsWeighInReminder) {
      final label = session.lastBodyMetricDate == null
          ? "You haven't logged a weigh-in yet"
          : 'Time for your weekly weigh-in';
      banners.add(_Banner(
        icon: Icons.monitor_weight_outlined,
        color: const Color(0xFF7C3AED),
        bg: const Color(0xFFF5F3FF),
        border: const Color(0xFFDDD6FE),
        title: label,
        subtitle:
            'Log your weight in Progress Tracker to keep your BMI history up to date.',
        actionLabel: '',
        onTap: null,
      ));
    }

    if (banners.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final b in banners)
          Padding(padding: const EdgeInsets.only(bottom: 12), child: b),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final Color border;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onTap;

  const _Banner({
    required this.icon,
    required this.color,
    required this.bg,
    required this.border,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
        boxShadow: AppColors.softCardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: color)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12.5, color: color.withValues(alpha: 0.85))),
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 12),
            TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                foregroundColor: color,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              child: Text(actionLabel,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 12.5)),
            ),
          ],
        ],
      ),
    );
  }
}
