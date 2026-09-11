import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A fully-rounded ("pill") button for the public landing page and other
/// marketing surfaces. Thin wrapper over the shared [AppButtons] styles so
/// every CTA on the page reads as one system.
class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final PillVariant variant;
  final IconData? icon;

  /// Stretch to the parent's width (pricing cards, mobile CTAs).
  final bool expand;

  /// Override the accent color for [PillVariant.outline] (e.g. cyan or
  /// gold instead of the variant's light-neutral default). Ignored by
  /// every other variant, which already carries its own fixed palette.
  final Color? color;

  /// [PillVariant.outline] only: solidify to this fill on hover/press
  /// (e.g. a cyan outline that turns solid gold on hover), reverting to
  /// the plain outline otherwise. Pass [hoverForegroundColor] alongside
  /// it for readable label/icon color against that fill.
  final Color? hoverFillColor;
  final Color? hoverForegroundColor;

  const PillButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.variant = PillVariant.primary,
    this.icon,
    this.expand = false,
    this.color,
    this.hoverFillColor,
    this.hoverForegroundColor,
  });

  bool get _isElevated =>
      variant == PillVariant.primary || variant == PillVariant.dark;

  ButtonStyle get _style {
    switch (variant) {
      case PillVariant.primary:
        return AppButtons.pillPrimary();
      case PillVariant.outline:
        return AppButtons.pillOutline(
          color: color ?? const Color(0xFFE9EAEE),
          hoverFillColor: hoverFillColor,
          hoverForegroundColor: hoverForegroundColor,
        );
      case PillVariant.ghost:
        return AppButtons.pillGhost();
      case PillVariant.dark:
        return AppButtons.pillDark();
      case PillVariant.darkOutline:
        return AppButtons.pillDarkOutline();
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(label),
            ],
          );

    final Widget button = _isElevated
        ? ElevatedButton(onPressed: onPressed, style: _style, child: child)
        : OutlinedButton(onPressed: onPressed, style: _style, child: child);

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
