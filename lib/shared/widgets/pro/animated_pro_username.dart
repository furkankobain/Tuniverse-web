import 'package:flutter/material.dart';

/// Animated gradient username widget for Pro users
/// Shows a shimmering gradient effect on the username
class AnimatedProUsername extends StatefulWidget {
  final String username;
  final TextStyle? style;
  final bool isPro;
  final List<Color>? customGradient;

  const AnimatedProUsername({
    super.key,
    required this.username,
    this.style,
    this.isPro = false,
    this.customGradient,
  });

  @override
  State<AnimatedProUsername> createState() => _AnimatedProUsernameState();
}

class _AnimatedProUsernameState extends State<AnimatedProUsername>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If not Pro, show regular text
    if (!widget.isPro) {
      return Text(
        widget.username,
        style: widget.style,
      );
    }

    // Default Pro gradient colors
    final gradientColors = widget.customGradient ?? [
      const Color(0xFFFFD700), // Gold
      const Color(0xFFFFE55C), // Light gold
      const Color(0xFFFFF8DC), // Cream
      const Color(0xFFFFE55C), // Light gold
      const Color(0xFFFFD700), // Gold
    ];

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: gradientColors,
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcIn,
          child: Text(
            widget.username,
            style: widget.style?.copyWith(
              fontWeight: FontWeight.bold,
            ) ?? const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}

/// Simple Pro badge icon
class ProBadge extends StatelessWidget {
  final double size;
  
  const ProBadge({
    super.key,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(size * 0.15),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFE55C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        Icons.check_circle,
        size: size * 0.7,
        color: Colors.white,
      ),
    );
  }
}

/// Username with Pro badge
class UsernameWithBadge extends StatelessWidget {
  final String username;
  final bool isPro;
  final TextStyle? style;
  final List<Color>? customGradient;
  final double badgeSize;

  const UsernameWithBadge({
    super.key,
    required this.username,
    required this.isPro,
    this.style,
    this.customGradient,
    this.badgeSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedProUsername(
          username: username,
          isPro: isPro,
          style: style,
          customGradient: customGradient,
        ),
        if (isPro) ...[
          const SizedBox(width: 4),
          ProBadge(size: badgeSize),
        ],
      ],
    );
  }
}
