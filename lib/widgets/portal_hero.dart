import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The solid flat-cyan header banner shown at the top of every member-portal
/// screen — same single colour as the sidebar (explicitly no gradient),
/// rounded corners, soft shadow. Mirrors the PrimeFit Admin app's header
/// treatment: a gold uppercase eyebrow, a gold leading icon (no emoji), a
/// bold white title, and an optional muted-white subtitle. Purely
/// presentational — it renders whatever each screen passes in.
class PortalHero extends StatelessWidget {
  /// Gold uppercase eyebrow label (e.g. "DASHBOARD").
  final String eyebrow;

  /// Gold icon shown immediately before the white title. No emojis.
  final IconData icon;

  final String title;
  final String? subtitle;

  /// Optional widget pinned to the right of the banner (e.g. a status
  /// pill). Hidden automatically on the narrowest layout.
  final Widget? trailing;

  const PortalHero({
    super.key,
    required this.eyebrow,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final pad = context.isMobile ? 20.0 : 26.0;
    final titleSize = context.isMobile ? 21.0 : 24.0;

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: const TextStyle(
            color: AppColors.goldOnCyanText,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.goldOnCyan, size: titleSize + 4),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                title,
                style: AppText.pageTitle(size: titleSize, color: Colors.white),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
        ],
      ],
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: AppColors.heroFill,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softCardShadow,
      ),
      child: (trailing != null && !context.isMobile)
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: text),
                const SizedBox(width: 16),
                trailing!,
              ],
            )
          : text,
    );
  }
}
