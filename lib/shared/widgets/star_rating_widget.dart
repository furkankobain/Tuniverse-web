import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class StarRatingWidget extends StatefulWidget {
  final int rating;
  final bool interactive;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final Function(int)? onRatingChanged;

  const StarRatingWidget({
    super.key,
    required this.rating,
    this.interactive = false,
    this.size = 24.0,
    this.activeColor,
    this.inactiveColor,
    this.onRatingChanged,
  });

  @override
  State<StarRatingWidget> createState() => _StarRatingWidgetState();
}

class _StarRatingWidgetState extends State<StarRatingWidget> {
  late int _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.rating;
  }

  @override
  void didUpdateWidget(StarRatingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rating != widget.rating) {
      _currentRating = widget.rating;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor ?? AppTheme.primaryColor;
    final inactiveColor = widget.inactiveColor ?? Colors.grey.shade300;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final isActive = starIndex <= _currentRating;

        return GestureDetector(
          onTap: widget.interactive ? () => _onStarTapped(starIndex) : null,
          child: Container(
            padding: const EdgeInsets.all(2),
            child: Icon(
              isActive ? Icons.star : Icons.star_border,
              size: widget.size,
              color: isActive ? activeColor : inactiveColor,
            ),
          ),
        );
      }),
    );
  }

  void _onStarTapped(int starIndex) {
    setState(() {
      _currentRating = starIndex;
    });
    
    widget.onRatingChanged?.call(_currentRating);
  }
}

class StarRatingDisplay extends StatelessWidget {
  final int rating;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool showNumber;

  const StarRatingDisplay({
    super.key,
    required this.rating,
    this.size = 20.0,
    this.activeColor,
    this.inactiveColor,
    this.showNumber = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = this.activeColor ?? AppTheme.primaryColor;
    final inactiveColor = this.inactiveColor ?? Colors.grey.shade300;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          final starIndex = index + 1;
          final isActive = starIndex <= rating;

          return Icon(
            isActive ? Icons.star : Icons.star_border,
            size: size,
            color: isActive ? activeColor : inactiveColor,
          );
        }),
        if (showNumber) ...[
          const SizedBox(width: 4),
          Text(
            rating.toString(),
            style: TextStyle(
              fontSize: size * 0.8,
              fontWeight: FontWeight.w600,
              color: activeColor,
            ),
          ),
        ],
      ],
    );
  }
}
