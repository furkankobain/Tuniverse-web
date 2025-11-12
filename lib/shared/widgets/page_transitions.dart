import 'package:flutter/material.dart';

/// Fade page transition
class FadePageTransition extends PageRouteBuilder {
  final Widget page;

  FadePageTransition({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        );
}

/// Slide page transition
class SlidePageTransition extends PageRouteBuilder {
  final Widget page;
  final SlideDirection direction;

  SlidePageTransition({
    required this.page,
    this.direction = SlideDirection.fromRight,
  }) : super(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final offset = _getOffset(direction);
      final tween = Tween(begin: offset, end: Offset.zero);
      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 400),
  );

  static Offset _getOffset(SlideDirection direction) {
    switch (direction) {
      case SlideDirection.fromRight:
        return const Offset(1.0, 0.0);
      case SlideDirection.fromLeft:
        return const Offset(-1.0, 0.0);
      case SlideDirection.fromTop:
        return const Offset(0.0, -1.0);
      case SlideDirection.fromBottom:
        return const Offset(0.0, 1.0);
    }
  }
}

enum SlideDirection { fromRight, fromLeft, fromTop, fromBottom }

/// Scale page transition
class ScalePageTransition extends PageRouteBuilder {
  final Widget page;

  ScalePageTransition({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return ScaleTransition(
              scale: animation.drive(Tween(begin: 0.0, end: 1.0)),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        );
}

/// Rotate page transition
class RotatePageTransition extends PageRouteBuilder {
  final Widget page;

  RotatePageTransition({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return RotationTransition(
              turns: animation.drive(Tween(begin: 0.0, end: 1.0)),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        );
}

/// Size page transition
class SizePageTransition extends PageRouteBuilder {
  final Widget page;

  SizePageTransition({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return ScaleTransition(
              scale: animation,
              alignment: Alignment.center,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        );
}

/// Combined transitions
class CombinedPageTransition extends PageRouteBuilder {
  final Widget page;

  CombinedPageTransition({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  animation.drive(Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        );
}

/// Shared axis transition (Material Design 3)
class SharedAxisTransition extends PageRouteBuilder {
  final Widget page;
  final SharedAxisTransitionType transitionType;

  SharedAxisTransition({
    required this.page,
    this.transitionType = SharedAxisTransitionType.horizontal,
  }) : super(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final isForwardDirection = animation.status == AnimationStatus.forward;

      switch (transitionType) {
        case SharedAxisTransitionType.horizontal:
          return SlideTransition(
            position: animation.drive(
              Tween(
                begin: Offset(isForwardDirection ? 1.0 : -1.0, 0.0),
                end: Offset.zero,
              ),
            ),
            child: FadeTransition(opacity: animation, child: child),
          );
        case SharedAxisTransitionType.vertical:
          return SlideTransition(
            position: animation.drive(
              Tween(
                begin: Offset(0.0, isForwardDirection ? 1.0 : -1.0),
                end: Offset.zero,
              ),
            ),
            child: FadeTransition(opacity: animation, child: child),
          );
        case SharedAxisTransitionType.scaled:
          return ScaleTransition(
            scale: animation.drive(Tween(begin: 0.0, end: 1.0)),
            child: FadeTransition(opacity: animation, child: child),
          );
      }
    },
    transitionDuration: const Duration(milliseconds: 500),
  );
}

enum SharedAxisTransitionType { horizontal, vertical, scaled }

/// Button press animation
class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Duration duration;
  final double scale;

  const AnimatedButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.duration = const Duration(milliseconds: 150),
    this.scale = 0.95,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    _controller.forward();
  }

  void _onPointerUp(PointerUpEvent event) {
    _controller.reverse();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

/// List item animation
class ListItemAnimation extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration staggerDuration;

  const ListItemAnimation({
    super.key,
    required this.child,
    required this.index,
    this.staggerDuration = const Duration(milliseconds: 100),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + (index * staggerDuration.inMilliseconds)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Bounce animation
class BounceAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const BounceAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  State<BounceAnimation> createState() => _BounceAnimationState();
}

class _BounceAnimationState extends State<BounceAnimation>
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

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: widget.child,
    );
  }
}
