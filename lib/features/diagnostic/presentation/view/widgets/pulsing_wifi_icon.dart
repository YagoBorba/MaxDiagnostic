import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PulsingWifiIcon extends StatefulWidget {
  const PulsingWifiIcon({super.key});

  @override
  State<PulsingWifiIcon> createState() => _PulsingWifiIconState();
}

class _PulsingWifiIconState extends State<PulsingWifiIcon>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final darkerPrimary = Color.alphaBlend(
      Colors.black.withValues(alpha: 0.2),
      primaryColor,
    );

    return FadeTransition(
      opacity: _fadeController,
      child: SizedBox(
        width: 256,
        height: 256,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _PulsingRing(
              size: 256,
              color: primaryColor.withValues(alpha: 0.1),
              duration: const Duration(milliseconds: 1500),
            ),

            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 224,
                  height: 224,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor.withValues(
                      alpha: 0.2 * (1 - _pulseController.value * 0.5),
                    ),
                  ),
                );
              },
            ),

            _PulsingRing(
              size: 192,
              color: primaryColor.withValues(alpha: 0.3),
              duration: const Duration(milliseconds: 1500),
              delay: const Duration(milliseconds: 500),
            ),
            Container(
              width: 144,
              height: 144,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor,
                    darkerPrimary,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.15),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Opacity(
                    opacity: 1.0 - (_pulseController.value * 0.5),
                    child: child,
                  );
                },
                child: const Icon(
                  LucideIcons.wifi,
                  size: 96,
                  color: Colors.white,
                ),
              ),
            ),

            _RotatingDot(
              controller: _rotationController,
              radius: 128,
              size: 12,
              angle: 0,
            ),
            _RotatingDot(
              controller: _rotationController,
              radius: 128,
              size: 8,
              angle: math.pi,
              reverse: true,
              opacity: 0.6,
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingRing extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;
  final Duration delay;

  const _PulsingRing({
    required this.size,
    required this.color,
    required this.duration,
    this.delay = Duration.zero,
  });

  @override
  State<_PulsingRing> createState() => _PulsingRingState();
}

class _PulsingRingState extends State<_PulsingRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat();
      }
    });
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
        final animatedAlpha = widget.color.a * (1 - _animation.value) * 0.5;
        final animatedColor = widget.color.withValues(alpha: animatedAlpha);
        return Container(
          width: widget.size * (0.5 + _animation.value * 0.5),
          height: widget.size * (0.5 + _animation.value * 0.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: animatedColor,
          ),
        );
      },
    );
  }
}

class _RotatingDot extends StatelessWidget {
  final AnimationController controller;
  final double radius;
  final double size;
  final double angle;
  final bool reverse;
  final double opacity;

  const _RotatingDot({
    required this.controller,
    required this.radius,
    required this.size,
    this.angle = 0,
    this.reverse = false,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final rotation = reverse
            ? (1 - controller.value) * 2 * math.pi
            : controller.value * 2 * math.pi;
        final totalAngle = rotation + angle;

        final x = radius * math.cos(totalAngle);
        final y = radius * math.sin(totalAngle);

        return Transform.translate(
          offset: Offset(x, y),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withValues(alpha: opacity),
              boxShadow: [
                BoxShadow(
                  color:
                      primaryColor.withValues(alpha: 0.8 * opacity),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
