import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/modern_design_system.dart';
import '../../../features/album/data/models/review_model.dart';
import 'rating_widget.dart';

class ReviewCard extends StatefulWidget {
  final Review review;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final bool isCurrentUser;
  final bool showActions;

  const ReviewCard({
    super.key,
    required this.review,
    this.onLike,
    this.onDislike,
    this.onDelete,
    this.onEdit,
    this.isCurrentUser = false,
    this.showActions = true,
  });

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  bool _isExpanded = false;
  static const int _previewLength = 150;

  bool get _needsExpansion => widget.review.reviewText.length > _previewLength;

  String get _displayText {
    if (!_needsExpansion || _isExpanded) {
      return widget.review.reviewText;
    }
    return '${widget.review.reviewText.substring(0, _previewLength)}...';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          // Header: User info + rating
          Row(
            children: [
              // User avatar
              CircleAvatar(
                radius: 20,
                backgroundImage: widget.review.userPhotoUrl != null
                    ? NetworkImage(widget.review.userPhotoUrl!)
                    : null,
                child: widget.review.userPhotoUrl == null
                    ? Text(
                        widget.review.userName[0].toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // User name + timestamp
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.review.userName,
                      style: TextStyle(
                        fontSize: ModernDesignSystem.fontSizeM,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      timeago.format(widget.review.createdAt),
                      style: TextStyle(
                        fontSize: ModernDesignSystem.fontSizeS,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Rating
              RatingDisplay(
                rating: widget.review.rating,
                showCount: false,
                size: 18,
              ),

              // Actions menu
              if (widget.isCurrentUser)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  onSelected: (value) {
                    if (value == 'edit' && widget.onEdit != null) {
                      widget.onEdit!();
                    } else if (value == 'delete' && widget.onDelete != null) {
                      widget.onDelete!();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Düzenle'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Sil', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Review text
          Text(
            _displayText,
            style: TextStyle(
              fontSize: ModernDesignSystem.fontSizeM,
              height: 1.5,
              color: isDark ? Colors.grey[300] : Colors.grey[800],
            ),
          ),

          // Show more/less button
          if (_needsExpansion) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Text(
                _isExpanded ? 'Daha az göster' : 'Devamını oku',
                style: TextStyle(
                  fontSize: ModernDesignSystem.fontSizeS,
                  color: ModernDesignSystem.accentPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          if (widget.showActions) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Action buttons
            Row(
              children: [
                // Like button
                _ActionButton(
                  icon: widget.review.userReaction == 'like'
                      ? Icons.thumb_up
                      : Icons.thumb_up_outlined,
                  label: widget.review.likes.toString(),
                  isActive: widget.review.userReaction == 'like',
                  onTap: widget.onLike,
                ),
                const SizedBox(width: 16),

                // Dislike button
                _ActionButton(
                  icon: widget.review.userReaction == 'dislike'
                      ? Icons.thumb_down
                      : Icons.thumb_down_outlined,
                  label: widget.review.dislikes.toString(),
                  isActive: widget.review.userReaction == 'dislike',
                  onTap: widget.onDislike,
                ),

                const Spacer(),

                // Edit indicator
                if (widget.review.isEdited)
                  Text(
                    'düzenlendi',
                    style: TextStyle(
                      fontSize: ModernDesignSystem.fontSizeXS,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isActive
        ? ModernDesignSystem.accentPurple
        : (isDark ? Colors.grey[400] : Colors.grey[600]);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: ModernDesignSystem.fontSizeS,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact review summary for lists
class ReviewSummary extends StatelessWidget {
  final String userName;
  final String? userPhotoUrl;
  final double rating;
  final String snippet;
  final DateTime createdAt;
  final VoidCallback? onTap;

  const ReviewSummary({
    super.key,
    required this.userName,
    this.userPhotoUrl,
    required this.rating,
    required this.snippet,
    required this.createdAt,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ModernDesignSystem.radiusS),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? ModernDesignSystem.darkCard : ModernDesignSystem.lightCard,
          borderRadius: BorderRadius.circular(ModernDesignSystem.radiusS),
          border: Border.all(
            color: isDark ? ModernDesignSystem.darkBorder : ModernDesignSystem.lightBorder,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              radius: 16,
              backgroundImage: userPhotoUrl != null ? NetworkImage(userPhotoUrl!) : null,
              child: userPhotoUrl == null
                  ? Text(
                      userName[0].toUpperCase(),
                      style: const TextStyle(fontSize: 14),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          userName,
                          style: TextStyle(
                            fontSize: ModernDesignSystem.fontSizeS,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      RatingDisplay(
                        rating: rating,
                        showCount: false,
                        size: 14,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    snippet,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: ModernDesignSystem.fontSizeS,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeago.format(createdAt),
                    style: TextStyle(
                      fontSize: ModernDesignSystem.fontSizeXS,
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
