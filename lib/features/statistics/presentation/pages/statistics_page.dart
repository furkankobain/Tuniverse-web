import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/providers/statistics_provider.dart';
import '../../../../shared/widgets/star_rating_widget.dart';
// import '../../../music/presentation/pages/rate_music_page.dart'; // Unused import

class StatisticsPage extends ConsumerWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statisticsAsync = ref.watch(userStatisticsProvider);
    final insightsAsync = ref.watch(listeningInsightsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Statistics'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(userStatisticsProvider);
              ref.invalidate(listeningInsightsProvider);
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.1),
              AppTheme.backgroundColor,
            ],
          ),
        ),
        child: statisticsAsync.when(
          data: (statistics) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview Cards
                  _buildOverviewCards(statistics),
                  
                  const SizedBox(height: 24),
                  
                  // Rating Distribution
                  _buildRatingDistribution(statistics),
                  
                  const SizedBox(height: 24),
                  
                  // Top Artists
                  _buildTopArtists(statistics),
                  
                  const SizedBox(height: 24),
                  
                  // Top Albums
                  _buildTopAlbums(statistics),
                  
                  const SizedBox(height: 24),
                  
                  // Monthly Stats
                  _buildMonthlyStats(statistics),
                  
                  const SizedBox(height: 24),
                  
                  // Listening Insights
                  insightsAsync.when(
                    data: (insights) => _buildListeningInsights(insights),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => _buildErrorCard('Error loading insights'),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Most Used Tags
                  _buildMostUsedTags(statistics),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState('Error loading statistics: $error'),
        ),
      ),
    );
  }

  Widget _buildOverviewCards(Map<String, dynamic> statistics) {
    return Row(
      children: [
        Expanded(
          child: _buildOverviewCard(
            'Total Ratings',
            statistics['totalRatings']?.toString() ?? '0',
            Icons.star,
            AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOverviewCard(
            'Average Rating',
            (statistics['averageRating'] ?? 0.0).toStringAsFixed(1),
            Icons.analytics,
            AppTheme.accentColor,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingDistribution(Map<String, dynamic> statistics) {
    final distribution = Map<String, int>.from(statistics['ratingDistribution'] ?? {});
    final total = distribution.values.fold<int>(0, (sum, count) => sum + count);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rating Distribution',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...distribution.entries.map((entry) {
              final rating = int.parse(entry.key);
              final count = entry.value;
              final percentage = total > 0 ? (count / total) * 100 : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    StarRatingDisplay(
                      rating: rating,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: total > 0 ? count / total : 0,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$count (${percentage.toStringAsFixed(1)}%)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopArtists(Map<String, dynamic> statistics) {
    final artists = List<Map<String, dynamic>>.from(statistics['topArtists'] ?? []);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Artists',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (artists.isEmpty)
              const Text(
                'Not enough data yet',
                style: TextStyle(color: AppTheme.textSecondary),
              )
            else
              ...artists.take(5).map((artist) => _buildArtistItem(artist)),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistItem(Map<String, dynamic> artist) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
            child: Text(
              artist['name'].toString().split(' ').map((word) => word[0]).join(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artist['name'] ?? 'Unknown Artist',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${artist['count']} tracks',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          StarRatingDisplay(
            rating: (artist['averageRating'] ?? 0.0).round(),
            size: 16,
            showNumber: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTopAlbums(Map<String, dynamic> statistics) {
    final albums = List<Map<String, dynamic>>.from(statistics['topAlbums'] ?? []);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Rated Albums',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (albums.isEmpty)
              const Text(
                'Not enough data yet',
                style: TextStyle(color: AppTheme.textSecondary),
              )
            else
              ...albums.take(5).map((album) => _buildAlbumItem(album)),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumItem(Map<String, dynamic> album) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: album['image'] != null
                ? CachedNetworkImage(
                    imageUrl: album['image'],
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 40,
                      height: 40,
                      color: Colors.grey[300],
                      child: const Icon(Icons.album),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 40,
                      height: 40,
                      color: Colors.grey[300],
                      child: const Icon(Icons.album),
                    ),
                  )
                : Container(
                    width: 40,
                    height: 40,
                    color: Colors.grey[300],
                    child: const Icon(Icons.album),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  album['name'] ?? 'Unknown Album',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  album['artist'] ?? 'Unknown Artist',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          StarRatingDisplay(
            rating: (album['averageRating'] ?? 0.0).round(),
            size: 16,
            showNumber: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyStats(Map<String, dynamic> statistics) {
    final monthlyStats = List<Map<String, dynamic>>.from(statistics['monthlyStats'] ?? []);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (monthlyStats.isEmpty)
              const Text(
                'Not enough data yet',
                style: TextStyle(color: AppTheme.textSecondary),
              )
            else
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: monthlyStats.length,
                  itemBuilder: (context, index) {
                    final month = monthlyStats[index];
                    return _buildMonthBar(month);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthBar(Map<String, dynamic> month) {
    final count = month['count'] ?? 0;
    final maxCount = 50; // Adjust based on your data
    final height = (count / maxCount) * 150;

    return Container(
      width: 60,
      margin: const EdgeInsets.only(right: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            height: height,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.7),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            month['month']?.toString().split('-').last ?? '',
            style: const TextStyle(fontSize: 10),
          ),
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListeningInsights(Map<String, dynamic> insights) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dinleme İçgörüleri',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInsightCard(
                    'Toplam Dinleme',
                    '${insights['totalListeningTime'] ?? 0} dk',
                    Icons.timer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInsightCard(
                    'Favori Zaman',
                    insights['favoriteTimeOfDay'] ?? 'Öğlen',
                    Icons.schedule,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInsightCard(
                    'En Aktif Gün',
                    insights['mostActiveDay'] ?? 'Pazartesi',
                    Icons.calendar_today,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInsightCard(
                    'Keşif Oranı',
                    '${(insights['discoveryRate'] ?? 0.0).toStringAsFixed(1)}%',
                    Icons.explore,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMostUsedTags(Map<String, dynamic> statistics) {
    final tags = List<Map<String, dynamic>>.from(statistics['mostUsedTags'] ?? []);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'En Çok Kullanılan Etiketler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (tags.isEmpty)
              const Text(
                'Henüz etiket kullanılmamış',
                style: TextStyle(color: AppTheme.textSecondary),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags.take(10).map((tag) => _buildTagChip(tag)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagChip(Map<String, dynamic> tag) {
    return Chip(
      label: Text(
        '${tag['name']} (${tag['count']})',
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
      labelStyle: const TextStyle(color: AppTheme.primaryColor),
    );
  }

  Widget _buildErrorCard(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppTheme.errorColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: AppTheme.errorColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: AppTheme.errorColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.errorColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
