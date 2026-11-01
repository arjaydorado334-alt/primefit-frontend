import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A thin gold divider that fades in from transparent at both ends — used
/// between major landing-page sections to echo the gold CTA band's energy
/// without adding another solid-gold block. Reuse this rather than
/// hand-rolling gold lines per section.
class GoldRule extends StatelessWidget {
  final double thickness;
  final double maxWidth;
  final double verticalMargin;

  const GoldRule({
    super.key,
    this.thickness = 2,
    this.maxWidth = 900,
    this.verticalMargin = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.darkBg,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: verticalMargin),
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          height: thickness,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(thickness),
            gradient: LinearGradient(
              colors: [
                AppColors.gold.withValues(alpha: 0),
                AppColors.gold.withValues(alpha: 0.85),
                AppColors.gold.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
