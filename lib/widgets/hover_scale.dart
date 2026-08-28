import 'package:flutter/material.dart';

/// A stateful wrapper that scales its child on hover with a subtle shadow effect.
class HoverScale extends StatefulWidget {
  final Widget child;
  final double endScale;
  final Duration duration;
  final double shadowBlur;
  final double shadowOffset;

  const HoverScale({
    super.key,
    required this.child,
    this.endScale = 1.03,
    this.duration = const Duration(milliseconds: 200),
    this.shadowBlur = 12,
    this.shadowOffset = 4,
  });

  @override
  State<HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<HoverScale> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? widget.endScale : 1.0,
        duration: widget.duration,
        child: AnimatedContainer(
          duration: widget.duration,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: widget.shadowBlur,
                      offset: Offset(0, widget.shadowOffset),
                    ),
                  ]
                : const [BoxShadow(color: Colors.transparent, blurRadius: 0, offset: Offset.zero)],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}