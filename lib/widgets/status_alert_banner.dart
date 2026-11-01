import 'package:flutter/material.dart';
import '../screens/user_session.dart';
import '../theme/app_theme.dart';

/// Shows contextual alert banners for membership expiry and low session
/// credits. Renders nothing if neither condition applies. [onManageTap]
/// is called when the action button is tapped -- pass null to hide the
/// button (e.g. on pages that don't need a navigation shortcut).
///
/// Restyled to match the admin portal: neutral white cards with a small
/// colored icon tile and a thin colored bar on the left edge. The conditions
/// that decide which banners show, their text and their actions are unchanged.
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
        color: AppColors.cyan,
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
        color: AppColors.cyan,
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
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onTap;

  const _Banner({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = dark ? AppColors.darkCard : Colors.white;
    final cardBorder = dark ? AppColors.darkBorder : AppColors.cardBorder;
    final heading = dark ? Colors.white : const Color(0xFF1F2937);
    final muted = dark ? AppColors.textMutedOnDark : const Color(0xFF6B7280);
    // Lighten the icon color a bit in dark mode so it stays legible.
    final iconFg = dark ? (Color.lerp(color, Colors.white, 0.45) ?? color) : color;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: dark ? const [] : AppColors.softCardShadow,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: dark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: iconFg, size: 19),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: heading)),
                      const SizedBox(height: 3),
                      Text(subtitle,
                          style: TextStyle(fontSize: 12.5, color: muted)),
                    ],
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dark ? AppColors.cyan : const Color(0xFF111827),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(actionLabel,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12.5)),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 4, color: color),
          ),
        ],
      ),
    );
  }
}
