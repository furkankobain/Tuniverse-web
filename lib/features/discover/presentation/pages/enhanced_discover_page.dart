import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../../shared/models/music_review.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/spotify/spotify_connect_button.dart';

class EnhancedDiscoverPage extends ConsumerWidget {
  const EnhancedDiscoverPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundColor : Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Spotify Bağlantı Butonu
              const SpotifyConnectButton(),
              
              const SizedBox(height: 16),
              
              // En Çok Beğenilen Notlar
              _buildSectionHeader(
                'Öne Çıkan Notlar',
                '🔥',
                isDark,
              ),
              const SizedBox(height: 12),
              _buildFeaturedNotes(isDark),
              
              const SizedBox(height: 32),
              
              // Popüler Hesaplar
              _buildSectionHeader(
                'Popüler Hesaplar',
                '⭐',
                isDark,
              ),
              const SizedBox(height: 12),
              _buildPopularAccounts(isDark),
              
              const SizedBox(height: 32),
              
              // Rastgele Keşfet
              _buildSectionHeader(
                'Keşfet',
                '🎲',
                isDark,
              ),
              const SizedBox(height: 12),
              _buildRandomNotes(isDark),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String emoji, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedNotes(bool isDark) {
    final notes = _getMockFeaturedNotes();
    
    return Column(
      children: notes.map((note) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: _buildNoteCard(note, isDark, isFeatured: true),
      )).toList(),
    );
  }

  Widget _buildPopularAccounts(bool isDark) {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 10,
        itemBuilder: (context, index) {
          return _buildAccountCard(
            'Kullanıcı ${index + 1}',
            '${100 + index * 50} takipçi',
            '${20 + index * 5} not',
            isDark,
          );
        },
      ),
    );
  }

  Widget _buildRandomNotes(bool isDark) {
    final notes = _getMockRandomNotes();
    
    return Column(
      children: notes.map((note) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: _buildNoteCard(note, isDark),
      )).toList(),
    );
  }

  Widget _buildNoteCard(MusicReview review, bool isDark, {bool isFeatured = false}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFeatured 
              ? AppTheme.primaryColor.withOpacity(0.3)
              : isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: isFeatured ? 2 : 1,
        ),
        boxShadow: isFeatured ? [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ] : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                  child: Text(
                    review.username[0].toUpperCase(),
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            review.username,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          if (isFeatured) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.primaryColor,
                                    AppTheme.primaryColor.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'ÖNE ÇIKAN',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                          if (review.rating != null) ...[
                            const SizedBox(width: 8),
                            Row(
                              children: List.generate(
                                5,
                                (index) => Icon(
                                  index < review.rating! ? Icons.star : Icons.star_border,
                                  size: 14,
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(review.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Music Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.music_note,
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.trackName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          review.artists,
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
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Note Text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              review.reviewText,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: isDark ? Colors.grey[200] : Colors.grey[800],
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Tags
          if (review.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: review.tags.take(3).map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      '#$tag',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.favorite,
                  size: 18,
                  color: Colors.red[400],
                ),
                const SizedBox(width: 6),
                Text(
                  '${review.likeCount}',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 20),
                Icon(
                  Icons.comment,
                  size: 18,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Text(
                  '${review.replyCount}',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(String username, String followers, String notes, bool isDark) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
              child: Text(
                username[0].toUpperCase(),
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              username,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? Colors.white : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              followers,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            Text(
              notes,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Az önce';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} saat önce';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return DateFormat('dd MMM yyyy').format(timestamp);
    }
  }

  List<MusicReview> _getMockFeaturedNotes() {
    return [
      MusicReview(
        id: 'featured_1',
        userId: 'user_1',
        username: 'Melodi Avcısı',
        trackId: 'track_1',
        trackName: 'Bohemian Rhapsody',
        artists: 'Queen',
        rating: 5,
        reviewText: 'Müzik tarihinin걸작lerinden biri! Her dinlediğimde farklı katmanlar keşfediyorum. Freddie Mercury\'nin vokali efsanevi, Brian May\'in gitar soloları mükemmel. 6 dakikalık bir opera rock şaheseri.',
        tags: ['klasik', 'rock', 'efsane'],
        likeCount: 342,
        replyCount: 45,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      MusicReview(
        id: 'featured_2',
        userId: 'user_2',
        username: 'Ritim Tutkunu',
        trackId: 'track_2',
        trackName: 'Billie Jean',
        artists: 'Michael Jackson',
        rating: 5,
        reviewText: 'Pop müziğin zirvesi! Bass line efsanevi, ritim mükemmel. Michael\'ın dans hareketleriyle birleşince ortaya benzersiz bir sanat eseri çıkıyor.',
        tags: ['pop', 'dans', 'klasik'],
        likeCount: 289,
        replyCount: 38,
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 8)),
      ),
    ];
  }

  List<MusicReview> _getMockRandomNotes() {
    return List.generate(3, (index) {
      return MusicReview(
        id: 'random_$index',
        userId: 'user_${index + 10}',
        username: 'Müzik Sever ${index + 1}',
        trackId: 'track_${index + 10}',
        trackName: 'Rastgele Şarkı ${index + 1}',
        artists: 'Sanatçı Adı',
        rating: 3 + index,
        reviewText: index == 0
            ? 'İlk dinleyişte çok etkiledi. Melodi kulağımda kaldı, hala mırıldanıyorum.'
            : index == 1
            ? 'Sözler çok anlamlı. Enstrümantasyon da gayet başarılı.'
            : 'Güzel bir parça ama biraz daha orijinal olabilirdi.',
        tags: index == 0 ? ['yeni', 'keşfet'] : [],
        likeCount: 15 + index * 8,
        replyCount: 3 + index * 2,
        createdAt: DateTime.now().subtract(Duration(hours: 10 + index * 3)),
        updatedAt: DateTime.now().subtract(Duration(hours: 10 + index * 3)),
      );
    });
  }
}
