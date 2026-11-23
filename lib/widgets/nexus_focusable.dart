import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NexusFocusable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSelect;
  final FocusNode? focusNode;
  final bool autoFocus;
  final BorderRadius? borderRadius;
  final double scale;
  final Color? activeBorderColor;
  final Color? activeGlowColor;
  final bool showGlow;

  const NexusFocusable({
    super.key,
    required this.child,
    this.onSelect,
    this.focusNode,
    this.autoFocus = false,
    this.borderRadius,
    this.scale = 1.04,
    this.activeBorderColor,
    this.activeGlowColor,
    this.showGlow = true,
  });

  @override
  State<NexusFocusable> createState() => _NexusFocusableState();
}

class _NexusFocusableState extends State<NexusFocusable> {
  late FocusNode _node;
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _node = widget.focusNode ?? FocusNode();
    _node.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _node.hasFocus;
      });
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _node.dispose();
    } else {
      _node.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).primaryColor;
    final r = widget.borderRadius ?? BorderRadius.circular(14);
    final isActive = _isFocused || _isHovered;
    final borderColor = widget.activeBorderColor ?? accent;
    final glowColor = widget.activeGlowColor ?? accent;

    return Focus(
      focusNode: _node,
      autofocus: widget.autoFocus,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
             event.logicalKey == LogicalKeyboardKey.enter ||
             event.logicalKey == LogicalKeyboardKey.numpadEnter ||
             event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
          widget.onSelect?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onSelect,
          child: AnimatedScale(
            scale: isActive ? widget.scale : 1.0,
            duration: const Duration(milliseconds: 170),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 170),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                borderRadius: r,
                border: Border.all(
                  color: isActive ? borderColor : Colors.transparent,
                  width: isActive ? 2.2 : 0,
                ),
                boxShadow: (isActive && widget.showGlow)
                    ? [
                        BoxShadow(
                          color: glowColor.withValues(alpha: 0.45),
                          blurRadius: 18,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: r,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
