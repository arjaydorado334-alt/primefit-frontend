import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Page header shown at the top of the member-portal screens, restyled to
/// match the admin portal: a plain bold title with a muted subtitle (no cyan
/// banner box). Purely presentational — it renders whatever each screen
/// passes in.
///
/// The constructor is unchanged so every screen that uses it keeps compiling:
/// [eyebrow] and [icon] are accepted but no longer drawn (the new design has
/// no eyebrow label or leading icon); [trailing] is still pinned to the right
/// and is hidden on the narrowest layout, as before.
class PortalHero extends StatelessWidget {
  /// Kept for compatibility; not shown in the new design.
  final String eyebrow;

  /// Kept for compatibility; not shown in the new design.
  final IconData icon;

  final String title;
  final String? subtitle;

  /// Optional widget pinned to the right of the header (e.g. a status pill).
  /// Hidden automatically on the narrowest layout.
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final heading = dark ? Colors.white : const Color(0xFF1F2937);
    final muted = dark ? AppColors.textMutedOnDark : const Color(0xFF6B7280);
    final titleSize = context.isMobile ? 22.0 : 28.0;

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: heading,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: TextStyle(fontSize: 14, color: muted)),
        ],
      ],
    );

    return SizedBox(
      width: double.infinity,
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
