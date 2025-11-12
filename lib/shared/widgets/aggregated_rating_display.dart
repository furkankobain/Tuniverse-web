import 'package:flutter/material.dart';
import '../services/rating_aggregation_service.dart';
import '../../core/theme/app_theme.dart';

class AggregatedRatingDisplay extends StatelessWidget {
  final AggregatedRating rating;
  final bool showBreakdown;
  final bool showStats;
  final bool compact;

  const AggregatedRatingDisplay({
    super.key,
    required this.rating,
    this.showBreakdown = true,
    this.showStats = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactDisplay(context);
    }
    return _buildFullDisplay(context);
  }

  Widget _buildCompactDisplay(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getGradientColors(rating.overall),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getRatingColor(rating.overall).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getRatingIcon(rating.overall),
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            rating.displayRating,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullDisplay(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getRatingColor(rating.overall).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main rating
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _getGradientColors(rating.overall),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _getRatingColor(rating.overall).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getRatingIcon(rating.overall),
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      rating.displayRating,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getRatingLabel(rating.overall),
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildConfidenceBadge(rating.confidenceLevel, isDark),
                        const SizedBox(width: 8),
                        Text(
                          '${rating.sources.length} ${rating.sources.length == 1 ? 'source' : 'sources'}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Rating bar
          const SizedBox(height: 16),
          _buildRatingBar(rating.overall),

          // Breakdown
          if (showBreakdown && rating.sources.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Source Breakdown',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[700],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildSourceBreakdown(isDark),
          ],

          // Stats
          if (showStats && (rating.lastFmPlaycount != null || rating.appRatingCount != null)) ...[
            const SizedBox(height: 16),
            _buildStats(isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingBar(double score) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: score / 10,
        minHeight: 8,
        backgroundColor: Colors.grey[300],
        valueColor: AlwaysStoppedAnimation(
          _getRatingColor(score),
        ),
      ),
    );
  }

  Widget _buildConfidenceBadge(String confidence, bool isDark) {
    Color color;
    switch (confidence) {
      case 'High':
        color = Colors.green;
        break;
      case 'Medium':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        confidence,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSourceBreakdown(bool isDark) {
    return Column(
      children: [
        if (rating.spotifyScore != null)
          _buildSourceItem(
            'Spotify',
            rating.spotifyScore!,
            Icons.music_note,
            const Color(0xFF1DB954),
            isDark,
          ),
        if (rating.lastFmScore != null)
          _buildSourceItem(
            'Last.fm',
            rating.lastFmScore!,
            Icons.radio,
            const Color(0xFFD51007),
            isDark,
          ),
        if (rating.appScore != null)
          _buildSourceItem(
            'Community',
            rating.appScore!,
            Icons.people,
            AppTheme.primaryColor,
            isDark,
          ),
      ],
    );
  }

  Widget _buildSourceItem(
    String source,
    double score,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              source,
              style: TextStyle(
                color: isDark ? Colors.grey[300] : Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ),
          Text(
            score.toStringAsFixed(1),
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: score / 10,
                minHeight: 4,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(bool isDark) {
    return Row(
      children: [
        if (rating.lastFmPlaycount != null)
          Expanded(
            child: _buildStatItem(
              'Plays',
              _formatNumber(rating.lastFmPlaycount!),
              Icons.play_arrow,
              isDark,
            ),
          ),
        if (rating.lastFmListeners != null)
          Expanded(
            child: _buildStatItem(
              'Listeners',
              _formatNumber(rating.lastFmListeners!),
              Icons.headphones,
              isDark,
            ),
          ),
        if (rating.appRatingCount != null)
          Expanded(
            child: _buildStatItem(
              'Ratings',
              rating.appRatingCount.toString(),
              Icons.star,
              isDark,
            ),
          ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, bool isDark) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Color _getRatingColor(double score) {
    if (score >= 8.5) return const Color(0xFF4CAF50); // Green
    if (score >= 7.0) return const Color(0xFF8BC34A); // Light Green
    if (score >= 5.5) return const Color(0xFFFFEB3B); // Yellow
    if (score >= 4.0) return const Color(0xFFFF9800); // Orange
    return const Color(0xFFF44336); // Red
  }

  List<Color> _getGradientColors(double score) {
    final baseColor = _getRatingColor(score);
    return [
      baseColor,
      Color.lerp(baseColor, Colors.black, 0.2)!,
    ];
  }

  IconData _getRatingIcon(double score) {
    if (score >= 8.5) return Icons.star;
    if (score >= 7.0) return Icons.star_half;
    if (score >= 5.5) return Icons.thumb_up;
    if (score >= 4.0) return Icons.thumbs_up_down;
    return Icons.thumb_down;
  }

  String _getRatingLabel(double score) {
    if (score >= 9.0) return 'Masterpiece';
    if (score >= 8.5) return 'Excellent';
    if (score >= 7.5) return 'Great';
    if (score >= 6.5) return 'Good';
    if (score >= 5.5) return 'Decent';
    if (score >= 4.5) return 'Mixed';
    if (score >= 3.5) return 'Below Average';
    return 'Poor';
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
