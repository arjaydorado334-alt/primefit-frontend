import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A frosted-glass stat card overlaid on the hero photo: semi-transparent
/// white with a hairline border and a soft blur behind it, a big bold
/// number and a small muted caption. Purely presentational.
class GlassStatCard extends StatelessWidget {
  final String value;
  final String caption;

  const GlassStatCard({super.key, required this.value, required this.caption});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppText.statNumber(size: 26, color: Colors.white)),
              const SizedBox(height: 2),
              Text(
                caption,
                style: AppText.statCaption(
                    color: Colors.white.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
