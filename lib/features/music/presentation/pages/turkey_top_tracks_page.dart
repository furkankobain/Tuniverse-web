import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/modern_design_system.dart';
import '../../../../shared/services/enhanced_spotify_service.dart';

class TurkeyTopTracksPage extends ConsumerStatefulWidget {
  const TurkeyTopTracksPage({super.key});

  @override
  ConsumerState<TurkeyTopTracksPage> createState() => _TurkeyTopTracksPageState();
}

class _TurkeyTopTracksPageState extends ConsumerState<TurkeyTopTracksPage> {
  List<Map<String, dynamic>> _tracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    setState(() => _isLoading = true);
    
    try {
      final tracks = await EnhancedSpotifyService.getTurkeyTopTracks(limit: 50);
      if (mounted) {
        setState(() {
          _tracks = tracks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Türkiye\'nin En Popüler Şarkıları',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark 
              ? ModernDesignSystem.darkGradient
              : LinearGradient(
                  colors: [
                    ModernDesignSystem.lightBackground,
                    ModernDesignSystem.primaryGreen.withValues(alpha: 0.02),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
        ),
        child: _isLoading
            ? _buildLoadingState()
            : _buildTracksList(isDark),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Popüler şarkılar yükleniyor...'),
        ],
      ),
    );
  }

  Widget _buildTracksList(bool isDark) {
    return ListView.builder(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      itemCount: _tracks.length,
      itemBuilder: (context, index) {
        final track = _tracks[index];
        return _buildTrackCard(track, index + 1, isDark);
      },
    );
  }

  Widget _buildTrackCard(Map<String, dynamic> track, int rank, bool isDark) {
    final imageUrl = (track['album']?['images'] as List?)?.isNotEmpty == true
        ? track['album']['images'][0]['url']
        : null;
    final artistNames = (track['artists'] as List?)
        ?.map((a) => a['name'])
        .join(', ') ?? 'Unknown Artist';

    // Different gradient for top 3
    final Gradient rankGradient;
    if (rank == 1) {
      rankGradient = ModernDesignSystem.sunsetGradient;
    } else if (rank == 2) {
      rankGradient = ModernDesignSystem.primaryGradient;
    } else if (rank == 3) {
      rankGradient = ModernDesignSystem.blueGradient;
    } else {
      rankGradient = LinearGradient(
        colors: [
          isDark ? Colors.grey[800]! : Colors.grey[300]!,
          isDark ? Colors.grey[900]! : Colors.grey[400]!,
        ],
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: isDark 
          ? ModernDesignSystem.darkGlassmorphism
          : BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(ModernDesignSystem.radiusL),
              boxShadow: ModernDesignSystem.mediumShadow,
            ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rank badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: rankGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: rank <= 3 ? [
                  BoxShadow(
                    color: rankGradient.colors.first.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ] : null,
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Album cover
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: imageUrl == null ? ModernDesignSystem.primaryGradient : null,
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl == null
                  ? const Icon(Icons.music_note_rounded, color: Colors.white)
                  : null,
            ),
          ],
        ),
        title: Text(
          track['name'] ?? 'Unknown Track',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: isDark ? Colors.white : ModernDesignSystem.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              artistNames,
              style: TextStyle(
                fontSize: 13,
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.6)
                    : ModernDesignSystem.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 12,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDuration(track['duration_ms'] ?? 0),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.album_rounded,
                  size: 12,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    track['album']?['name'] ?? 'Unknown Album',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(
          Icons.play_circle_filled_rounded,
          color: ModernDesignSystem.primaryGreen,
          size: 32,
        ),
        onTap: () {
          // Play track or show details
        },
      ),
    );
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
