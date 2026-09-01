import 'package:flutter/material.dart';
import 'chat_panel.dart';

/// Wraps a page's content with a persistent floating chat button pinned to
/// the bottom-right of the content area. Tapping it slides a chat panel in
/// from the right edge of the screen.
class ChatFabOverlay extends StatefulWidget {
  final Widget child;
  final int? memberId;

  const ChatFabOverlay({
    super.key,
    required this.child,
    this.memberId,
  });

  @override
  State<ChatFabOverlay> createState() => _ChatFabOverlayState();
}

class _ChatFabOverlayState extends State<ChatFabOverlay>
    with SingleTickerProviderStateMixin {
  bool _open = false;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(1.15, 0),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  void _toggle() {
    setState(() => _open = !_open);
    if (_open) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _close() {
    setState(() => _open = false);
    _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final panelWidth = size.width < 420 ? size.width - 32 : 380.0;
    final panelHeight = (size.height * 0.75).clamp(420.0, 640.0);

    return Stack(
      children: [
        Positioned.fill(child: widget.child),
        Positioned(
          right: 16,
          bottom: 96,
          child: IgnorePointer(
            ignoring: !_open,
            child: SlideTransition(
              position: _slide,
              child: FadeTransition(
                opacity: _controller,
                child: Material(
                  elevation: 12,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    width: panelWidth,
                    height: panelHeight,
                    child: ChatPanel(onClose: _close, memberId: widget.memberId),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton(
            onPressed: _toggle,
            backgroundColor: const Color(0xFF00B4D8),
            shape: const CircleBorder(),
            elevation: 4,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                _open ? Icons.close : Icons.chat_bubble_outline,
                key: ValueKey(_open),
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}