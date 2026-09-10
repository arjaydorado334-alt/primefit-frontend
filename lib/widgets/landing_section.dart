import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shared scaffold for a public landing-page section: a centered uppercase
/// eyebrow label, a bold heading, an optional subtitle, then the section's
/// content — inside a max-width column with consistent vertical padding.
/// The landing page runs on a dark theme, so the heading/subtitle colours
/// here are light-on-dark; the accent eyebrow keeps the brand colour.
class LandingSection extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget child;

  /// Eyebrow accent — cyan by default (the landing page's accent system is
  /// cyan + gold only).
  final Color eyebrowColor;

  /// Section background — near-black page ground or the slightly lighter
  /// alternating tone, set by the caller so adjacent sections separate.
  final Color background;

  /// Centre the header block (default) or left-align it.
  final bool centerHeader;

  final double maxWidth;

  const LandingSection({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.child,
    this.subtitle,
    this.eyebrowColor = AppColors.cyan,
    this.background = AppColors.darkBg,
    this.centerHeader = true,
    this.maxWidth = 1140,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final pad = w < 600 ? 20.0 : (w < 1024 ? 40.0 : 64.0);
    final align =
        centerHeader ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final textAlign = centerHeader ? TextAlign.center : TextAlign.start;

    return Container(
      width: double.infinity,
      color: background,
      padding: EdgeInsets.symmetric(horizontal: pad, vertical: w < 600 ? 56 : 88),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: align,
            children: [
              Text(
                eyebrow.toUpperCase(),
                textAlign: textAlign,
                style: AppText.eyebrow(color: eyebrowColor),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: textAlign,
                style: AppText.pageTitle(
                    size: w < 600 ? 26 : 34, color: const Color(0xFFF4F5F7)),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Text(
                    subtitle!,
                    textAlign: textAlign,
                    style: AppText.bodyText(
                        color: AppColors.textMutedOnDark, height: 1.6),
                  ),
                ),
              ],
              SizedBox(height: w < 600 ? 32 : 48),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
