import 'package:flutter/material.dart';

/// Entrance animation for list and section content: a short fade paired with
/// a small upward slide. [index] staggers siblings so a list arrives in
/// sequence rather than all at once.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    required this.child,
    this.index = 0,
    this.offset = 16,
    this.duration = const Duration(milliseconds: 320),
    this.stagger = const Duration(milliseconds: 55),
    super.key,
  });

  final Widget child;
  final int index;

  /// How far below its resting place the child starts, in logical pixels.
  final double offset;
  final Duration duration;
  final Duration stagger;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();

    // Cap the stagger so a long list does not leave the last rows waiting.
    final delay = widget.stagger * widget.index.clamp(0, 8);
    final total = delay + widget.duration;

    // The delay is an interval inside one controller rather than a timer, so
    // the whole entrance is a single animation the framework can wait on.
    _controller = AnimationController(vsync: this, duration: total)..forward();
    _curve = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(
          offset: Offset(0, widget.offset * (1 - _curve.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Scales its child in from slightly small, for a single hero element.
class PopIn extends StatefulWidget {
  const PopIn({
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
    super.key,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final double _start;

  @override
  void initState() {
    super.initState();

    final total = widget.delay + widget.duration;
    _controller = AnimationController(vsync: this, duration: total)..forward();
    _start = widget.delay.inMicroseconds / total.inMicroseconds;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.6, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(_start, 1, curve: Curves.elasticOut),
        ),
      ),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _controller,
          curve: Interval(_start, 1, curve: Curves.easeOut),
        ),
        child: widget.child,
      ),
    );
  }
}
