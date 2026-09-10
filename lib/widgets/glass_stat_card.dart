import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shared **dark glass** (glassmorphism) surface for the hero: a backdrop
/// blur, a semi-transparent near-black tint, and a hairline light border —
/// so the element reads as a frosted panel floating over the hero photo
/// rather than a flat dark box. Used by the location pill, the stat cards
/// and the headline backing panel so they all share one treatment.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;

  /// Near-black tint opacity (0.30–0.40 keeps text legible on a busy photo).
  final double tint;

  /// Hairline border opacity (white).
  final double borderOpacity;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    this.radius = 16,
    this.blur = 12,
    this.tint = 0.38,
    this.borderOpacity = 0.14,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: tint),
            borderRadius: r,
            border:
                Border.all(color: Colors.white.withValues(alpha: borderOpacity)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A frosted-glass stat card overlaid on the hero photo (built on
/// [GlassPanel]): a big bold number and a small muted caption.
class GlassStatCard extends StatelessWidget {
  final String value;
  final String caption;

  /// Optional accent for the number (e.g. `AppColors.gold`) so the gold
  /// accent is woven into the hero too. Defaults to white.
  final Color? valueColor;

  const GlassStatCard({
    super.key,
    required this.value,
    required this.caption,
    this.valueColor,
  });

  static const _textShadow = [
    Shadow(color: Colors.black87, blurRadius: 8, offset: Offset(0, 1)),
  ];

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppText.statNumber(size: 26, color: valueColor ?? Colors.white)
                .copyWith(shadows: _textShadow),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            style: AppText.statCaption(color: Colors.white.withValues(alpha: 0.82))
                .copyWith(shadows: _textShadow),
          ),
        ],
      ),
    );
  }
}
