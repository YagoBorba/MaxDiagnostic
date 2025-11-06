import 'package:flutter/material.dart';

class AnimatedTimeRemaining extends StatefulWidget {
  final int seconds;

  const AnimatedTimeRemaining({
    super.key,
    required this.seconds,
  });

  @override
  State<AnimatedTimeRemaining> createState() => _AnimatedTimeRemainingState();
}

class _AnimatedTimeRemainingState extends State<AnimatedTimeRemaining>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _previousSeconds = 0;
  int _currentSeconds = 0;

  @override
  void initState() {
    super.initState();
    _previousSeconds = widget.seconds;
    _currentSeconds = widget.seconds;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: _previousSeconds.toDouble(),
      end: _currentSeconds.toDouble(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void didUpdateWidget(AnimatedTimeRemaining oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.seconds != widget.seconds) {
      _previousSeconds = _currentSeconds;
      _currentSeconds = widget.seconds;

      _animation = Tween<double>(
        begin: _previousSeconds.toDouble(),
        end: _currentSeconds.toDouble(),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));

      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final displaySeconds = _animation.value.round();
        return Text(
          '${displaySeconds}s restantes',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        );
      },
    );
  }
}
