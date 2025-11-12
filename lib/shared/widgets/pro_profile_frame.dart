import 'package:flutter/material.dart';
import 'dart:math' as math;

class ProProfileFrame extends StatefulWidget {
  final Widget child;
  final double size;
  final double borderWidth;
  
  const ProProfileFrame({
    super.key,
    required this.child,
    this.size = 120,
    this.borderWidth = 3,
  });

  @override
  State<ProProfileFrame> createState() => _ProProfileFrameState();
}

class _ProProfileFrameState extends State<ProProfileFrame>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated gradient border
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _controller.value * 2 * math.pi,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: const [
                        Color(0xFFFFD700), // Gold
                        Color(0xFFFFA500), // Orange
                        Color(0xFFFF6B6B), // Red
                        Color(0xFFAA00FF), // Purple
                        Color(0xFF00D4FF), // Cyan
                        Color(0xFFFFD700), // Gold
                      ],
                      stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
                      transform: GradientRotation(_controller.value * 2 * math.pi),
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Inner circle (background)
          Container(
            width: widget.size - (widget.borderWidth * 2),
            height: widget.size - (widget.borderWidth * 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
          ),
          
          // Profile image
          ClipOval(
            child: SizedBox(
              width: widget.size - (widget.borderWidth * 2) - 4,
              height: widget.size - (widget.borderWidth * 2) - 4,
              child: widget.child,
            ),
          ),
          
          // Glow effect
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                width: widget.size + 10,
                height: widget.size + 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color.lerp(
                        const Color(0xFFFFD700),
                        const Color(0xFFAA00FF),
                        _controller.value,
                      )!.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Simple static pro frame without animation (for performance)
class StaticProProfileFrame extends StatelessWidget {
  final Widget child;
  final double size;
  final double borderWidth;
  
  const StaticProProfileFrame({
    super.key,
    required this.child,
    this.size = 120,
    this.borderWidth = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFD700),
            Color(0xFFFFA500),
            Color(0xFFFF6B6B),
            Color(0xFFAA00FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      padding: EdgeInsets.all(borderWidth),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        padding: const EdgeInsets.all(2),
        child: ClipOval(child: child),
      ),
    );
  }
}
