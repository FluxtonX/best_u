import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Pretty Skew Animation Wrapper
///
/// Provides a premium 3D perspective tilt (toward tap position)
/// and a high-end shimmer sweep effect.
/// Used to wrap any tappable element to give it a "Premium" feel.
class AppBounceAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isDisabled;
  final Duration tapDelay;
  final double scaleFactor;

  const AppBounceAnimation({
    super.key,
    required this.child,
    this.onTap,
    this.isDisabled = false,
    this.tapDelay = const Duration(milliseconds: 80),
    this.scaleFactor = 0.96,
  });

  @override
  State<AppBounceAnimation> createState() => _AppBounceAnimationState();
}

class _AppBounceAnimationState extends State<AppBounceAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _tiltX = 0.0;
  double _tiltY = 0.0;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 300),
    )..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Matrix4 get _transform {
    final t = Curves.easeOut.transform(_controller.value);
    const maxTilt = 0.06; // Subtle 3D tilt

    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.001) // Perspective
      ..rotateX(-maxTilt * _tiltX * t)
      ..rotateY(maxTilt * _tiltY * t);

    final s = 1.0 - (1.0 - widget.scaleFactor) * t;
    // ignore: deprecated_member_use
    matrix.scale(s, s, 1.0);

    return matrix;
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.isDisabled || widget.onTap == null) return;

    final box = context.findRenderObject() as RenderBox;
    final size = box.size;
    final pos = details.localPosition;

    _tiltY = ((pos.dx / size.width) - 0.5) * 2.0;
    _tiltX = ((pos.dy / size.height) - 0.5) * 2.0;

    setState(() => _pressed = true);
    HapticFeedback.lightImpact();
    _controller.forward(from: 0.0);
  }

  void _onTapUp(TapUpDetails _) {
    if (widget.isDisabled || widget.onTap == null) return;
    setState(() => _pressed = false);
    _controller.reverse();

    Future.delayed(widget.tapDelay, () {
      if (mounted) widget.onTap!();
    });
  }

  void _onTapCancel() {
    if (widget.isDisabled) return;
    setState(() => _pressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: Transform(
        transform: _transform,
        alignment: FractionalOffset.center,
        child: widget.child
            .animate(target: _pressed ? 1 : 0)
            .shimmer(
              duration: 400.ms,
              color: const Color.fromRGBO(255, 255, 255, 0.25),
              angle: 0.5,
            )
            .scaleXY(end: 1.0, begin: 1.0, duration: 0.ms),
      ),
    );
  }
}
