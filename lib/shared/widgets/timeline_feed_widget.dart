import 'package:flutter/material.dart';
import '../../core/theme/modern_design_system.dart';

class TimelineFeedWidget extends StatelessWidget {
  final List<Map<String, dynamic>> posts;
  final bool isLoading;

  const TimelineFeedWidget({
    super.key,
    required this.posts,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isLoading) {
      return _buildLoadingSkeleton();
    }

    if (posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Text(
            'No posts yet',
            style: TextStyle(
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return _buildTimelinePost(context, post, isDark);
      },
    );
  }

  Widget _buildTimelinePost(
    BuildContext context,
    Map<String, dynamic> post,
    bool isDark,
  ) {
    final albumCover = post['albumCover'] as String?;
    final title = post['title'] as String? ?? 'Unknown Track';
    final artist = post['artist'] as String? ?? 'Unknown Artist';
    final type = post['albumType'] as String? ?? 'Album';
    final review = post['review'] as String? ?? '';
    final rating = post['rating'] as double? ?? 0.0;
    final userAvatar = post['userAvatar'] as String?;
    final userName = post['userName'] as String? ?? 'User';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ModernDesignSystem.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(ModernDesignSystem.radiusL),
        border: Border.all(
          color: isDark
              ? ModernDesignSystem.darkBorder
              : ModernDesignSystem.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Album/Track info with play button
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.brown.withValues(alpha: 0.3),
                  Colors.brown.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
            ),
            child: Row(
              children: [
                // Album cover
                if (albumCover != null)
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(ModernDesignSystem.radiusS),
                    child: Image.network(
                      albumCover,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(
                                ModernDesignSystem.radiusS),
                          ),
                          child: const Icon(Icons.music_note),
                        );
                      },
                    ),
                  )
                else
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius:
                          BorderRadius.circular(ModernDesignSystem.radiusS),
                    ),
                    child: const Icon(Icons.music_note),
                  ),
                const SizedBox(width: 12),
                // Title and artist
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$artist • $type',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Play button
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.black,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Review/Post title
          Text(
            review,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Rating stars
          Row(
            children: List.generate(
              5,
              (index) => Icon(
                index < rating.toInt() ? Icons.star : Icons.star_border,
                color: ModernDesignSystem.accentYellow,
                size: 18,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Review snippet
          if (post['reviewBody'] != null && (post['reviewBody'] as String).isNotEmpty)
            Text(
              post['reviewBody'] as String,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 12),
          // User info
          Row(
            children: [
              if (userAvatar != null)
                CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(userAvatar),
                )
              else
                CircleAvatar(
                  radius: 16,
                  child: Text(userName[0].toUpperCase()),
                ),
              const SizedBox(width: 8),
              Text(
                userName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(ModernDesignSystem.radiusL),
          ),
          height: 200,
        );
      },
    );
  }
}
