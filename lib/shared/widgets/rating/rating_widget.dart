import 'package:flutter/material.dart';
import '../../../core/theme/modern_design_system.dart';

class RatingWidget extends StatefulWidget {
  final double initialRating;
  final Function(double) onRatingChanged;
  final double size;
  final bool enabled;
  final bool showLabel;
  final Color? activeColor;
  final Color? inactiveColor;

  const RatingWidget({
    super.key,
    this.initialRating = 0.0,
    required this.onRatingChanged,
    this.size = 40.0,
    this.enabled = true,
    this.showLabel = true,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<RatingWidget> createState() => _RatingWidgetState();
}

class _RatingWidgetState extends State<RatingWidget> with SingleTickerProviderStateMixin {
  late double _currentRating;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  int? _hoveredStar;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateRating(double rating) {
    if (!widget.enabled) return;
    
    setState(() => _currentRating = rating);
    widget.onRatingChanged(rating);
    _animationController.forward().then((_) => _animationController.reverse());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = widget.activeColor ?? ModernDesignSystem.accentYellow;
    final inactiveColor = widget.inactiveColor ?? (isDark ? Colors.grey[700]! : Colors.grey[300]!);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final starValue = index + 1.0;
            final isActive = _currentRating >= starValue;
            final isHalfActive = _currentRating > index && _currentRating < starValue;

            return MouseRegion(
              onEnter: (_) {
                if (widget.enabled) {
                  setState(() => _hoveredStar = index);
                }
              },
              onExit: (_) {
                if (widget.enabled) {
                  setState(() => _hoveredStar = null);
                }
              },
              child: GestureDetector(
                onTap: () => _updateRating(starValue),
                child: AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    final isAnimating = _currentRating == starValue;
                    final scale = isAnimating ? _scaleAnimation.value : 1.0;

                    return Transform.scale(
                      scale: _hoveredStar == index ? 1.1 : scale,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: widget.size * 0.05),
                        child: Icon(
                          isActive
                              ? Icons.star
                              : (isHalfActive ? Icons.star_half : Icons.star_border),
                          size: widget.size,
                          color: (isActive || isHalfActive) ? activeColor : inactiveColor,
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          }),
        ),
        if (widget.showLabel && _currentRating > 0) ...[
          const SizedBox(height: 8),
          Text(
            _getRatingLabel(_currentRating),
            style: TextStyle(
              fontSize: ModernDesignSystem.fontSizeS,
              fontWeight: FontWeight.w600,
              color: activeColor,
            ),
          ),
        ],
      ],
    );
  }

  String _getRatingLabel(double rating) {
    if (rating >= 4.5) return 'Mükemmel! ⭐';
    if (rating >= 3.5) return 'Harika! 🎵';
    if (rating >= 2.5) return 'İyi 👍';
    if (rating >= 1.5) return 'Fena Değil';
    return 'Kötü 👎';
  }
}

/// Compact rating display widget (read-only)
class RatingDisplay extends StatelessWidget {
  final double rating;
  final int? ratingCount;
  final double size;
  final bool showCount;
  final Color? color;

  const RatingDisplay({
    super.key,
    required this.rating,
    this.ratingCount,
    this.size = 16.0,
    this.showCount = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final starColor = color ?? ModernDesignSystem.accentYellow;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star,
          size: size,
          color: starColor,
        ),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: size * 0.9,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        if (showCount && ratingCount != null && ratingCount! > 0) ...[
          const SizedBox(width: 4),
          Text(
            '($ratingCount)',
            style: TextStyle(
              fontSize: size * 0.75,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }
}

/// Rating distribution chart
class RatingDistribution extends StatelessWidget {
  final Map<int, int> distribution;
  final int totalRatings;
  final double height;

  const RatingDistribution({
    super.key,
    required this.distribution,
    required this.totalRatings,
    this.height = 150,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ModernDesignSystem.darkCard : ModernDesignSystem.lightCard,
        borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
        border: Border.all(
          color: isDark ? ModernDesignSystem.darkBorder : ModernDesignSystem.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rating Dağılımı',
            style: TextStyle(
              fontSize: ModernDesignSystem.fontSizeL,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                final star = 5 - index;
                final count = distribution[star] ?? 0;
                final percentage = totalRatings > 0 ? count / totalRatings : 0.0;

                return _buildDistributionBar(
                  star: star,
                  count: count,
                  percentage: percentage,
                  isDark: isDark,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionBar({
    required int star,
    required int count,
    required double percentage,
    required bool isDark,
  }) {
    return Row(
      children: [
        // Star label
        SizedBox(
          width: 30,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$star',
                style: TextStyle(
                  fontSize: ModernDesignSystem.fontSizeS,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.star,
                size: 12,
                color: ModernDesignSystem.accentYellow,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Progress bar
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getBarColor(star),
              ),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Count
        SizedBox(
          width: 40,
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: ModernDesignSystem.fontSizeS,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Color _getBarColor(int star) {
    switch (star) {
      case 5:
        return Colors.green;
      case 4:
        return Colors.lightGreen;
      case 3:
        return ModernDesignSystem.accentYellow;
      case 2:
        return Colors.orange;
      case 1:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
