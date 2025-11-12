import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

// import '../../../../core/constants/app_constants.dart'; // Unused import
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/providers/search_provider.dart';
import '../../../../shared/widgets/star_rating_widget.dart';
import '../../../../shared/services/search_service.dart';
import '../../../music/presentation/pages/rate_music_page.dart';

class AdvancedSearchPage extends ConsumerStatefulWidget {
  const AdvancedSearchPage({super.key});

  @override
  ConsumerState<AdvancedSearchPage> createState() => _AdvancedSearchPageState();
}

class _AdvancedSearchPageState extends ConsumerState<AdvancedSearchPage>
    with TickerProviderStateMixin {
  late TextEditingController _searchController;
  late TabController _tabController;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);
    final filters = ref.watch(searchFiltersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gelişmiş Arama'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Şarkılar'),
            Tab(text: 'Sanatçılar'),
            Tab(text: 'Albümler'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list : Icons.filter_list_outlined),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),
          
          // Filters
          if (_showFilters) _buildFilters(),
          
          // Search Results
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTracksResults(searchQuery, filters),
                _buildArtistsResults(searchQuery, filters),
                _buildAlbumsResults(searchQuery, filters),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Şarkı, sanatçı veya albüm ara...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).state = value;
              },
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _performSearch(value.trim());
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () {
              if (_searchController.text.trim().isNotEmpty) {
                _performSearch(_searchController.text.trim());
              }
            },
            icon: const Icon(Icons.search),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final filters = ref.watch(searchFiltersProvider);
    final filtersNotifier = ref.read(searchFiltersProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.textSecondary.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filtreler',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: filtersNotifier.clearFilters,
                child: const Text('Temizle'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Şarkılar'),
                selected: filters.showTracks,
                onSelected: (_) => filtersNotifier.toggleTracks(),
              ),
              FilterChip(
                label: const Text('Sanatçılar'),
                selected: filters.showArtists,
                onSelected: (_) => filtersNotifier.toggleArtists(),
              ),
              FilterChip(
                label: const Text('Albümler'),
                selected: filters.showAlbums,
                onSelected: (_) => filtersNotifier.toggleAlbums(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Minimum Puan: '),
              StarRatingWidget(
                rating: filters.minRating,
                interactive: true,
                size: 20,
                onRatingChanged: (rating) {
                  filtersNotifier.setMinRating(rating);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTracksResults(String query, SearchFilters filters) {
    if (query.isEmpty) {
      return _buildEmptyState('Şarkı aramak için yukarıdaki arama kutusunu kullanın');
    }

    return Consumer(
      builder: (context, ref, child) {
        final tracksAsync = ref.watch(searchTracksProvider(query));
        
        return tracksAsync.when(
          data: (tracks) {
            if (tracks.isEmpty) {
              return _buildEmptyState('Aradığınız kriterlere uygun şarkı bulunamadı');
            }

            // Apply filters
            final filteredTracks = tracks.where((track) {
              if (track['rating'] < filters.minRating) return false;
              if (filters.selectedTags.isNotEmpty) {
                final trackTags = List<String>.from(track['tags'] ?? []);
                if (!filters.selectedTags.any((tag) => trackTags.contains(tag))) {
                  return false;
                }
              }
              return true;
            }).toList();

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredTracks.length,
              itemBuilder: (context, index) {
                final track = filteredTracks[index];
                return _buildTrackCard(track);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState('Arama sırasında bir hata oluştu: $error'),
        );
      },
    );
  }

  Widget _buildArtistsResults(String query, SearchFilters filters) {
    if (query.isEmpty) {
      return _buildEmptyState('Sanatçı aramak için yukarıdaki arama kutusunu kullanın');
    }

    return Consumer(
      builder: (context, ref, child) {
        final artistsAsync = ref.watch(searchArtistsProvider(query));
        
        return artistsAsync.when(
          data: (artists) {
            if (artists.isEmpty) {
              return _buildEmptyState('Aradığınız kriterlere uygun sanatçı bulunamadı');
            }

            // Apply filters
            final filteredArtists = artists.where((artist) {
              if (artist['averageRating'] < filters.minRating) return false;
              return true;
            }).toList();

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredArtists.length,
              itemBuilder: (context, index) {
                final artist = filteredArtists[index];
                return _buildArtistCard(artist);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState('Arama sırasında bir hata oluştu: $error'),
        );
      },
    );
  }

  Widget _buildAlbumsResults(String query, SearchFilters filters) {
    if (query.isEmpty) {
      return _buildEmptyState('Albüm aramak için yukarıdaki arama kutusunu kullanın');
    }

    return Consumer(
      builder: (context, ref, child) {
        final albumsAsync = ref.watch(searchAlbumsProvider(query));
        
        return albumsAsync.when(
          data: (albums) {
            if (albums.isEmpty) {
              return _buildEmptyState('Aradığınız kriterlere uygun albüm bulunamadı');
            }

            // Apply filters
            final filteredAlbums = albums.where((album) {
              if (album['averageRating'] < filters.minRating) return false;
              return true;
            }).toList();

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredAlbums.length,
              itemBuilder: (context, index) {
                final album = filteredAlbums[index];
                return _buildAlbumCard(album);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState('Arama sırasında bir hata oluştu: $error'),
        );
      },
    );
  }

  Widget _buildTrackCard(Map<String, dynamic> track) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: track['albumImage'] != null
              ? CachedNetworkImage(
                  imageUrl: track['albumImage'],
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.music_note),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.music_note),
                  ),
                )
              : Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[300],
                  child: const Icon(Icons.music_note),
                ),
        ),
        title: Text(
          track['trackName'] ?? 'Bilinmeyen Şarkı',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(track['artists'] ?? 'Bilinmeyen Sanatçı'),
            if (track['albumName'] != null)
              Text(track['albumName']),
            const SizedBox(height: 4),
            StarRatingDisplay(
              rating: track['rating'] ?? 0,
              size: 16,
              showNumber: true,
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.star_border),
          onPressed: () => _openRateMusicPage(track),
        ),
        onTap: () => _openRateMusicPage(track),
      ),
    );
  }

  Widget _buildArtistCard(Map<String, dynamic> artist) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
          child: Text(
            artist['name'].toString().split(' ').map((word) => word[0]).join(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        title: Text(
          artist['name'] ?? 'Bilinmeyen Sanatçı',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${artist['trackCount']} şarkı'),
            const SizedBox(height: 4),
            StarRatingDisplay(
              rating: (artist['averageRating'] ?? 0.0).round(),
              size: 16,
              showNumber: true,
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _showArtistDetails(artist),
      ),
    );
  }

  Widget _buildAlbumCard(Map<String, dynamic> album) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: album['albumImage'] != null
              ? CachedNetworkImage(
                  imageUrl: album['albumImage'],
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.album),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.album),
                  ),
                )
              : Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[300],
                  child: const Icon(Icons.album),
                ),
        ),
        title: Text(
          album['name'] ?? 'Bilinmeyen Albüm',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(album['artist'] ?? 'Bilinmeyen Sanatçı'),
            Text('${album['trackCount']} şarkı'),
            const SizedBox(height: 4),
            StarRatingDisplay(
              rating: (album['averageRating'] ?? 0.0).round(),
              size: 16,
              showNumber: true,
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _showAlbumDetails(album),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: AppTheme.primaryColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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

  void _performSearch(String query) {
    // Save search to history
    SearchService.saveSearchHistory(query);
  }

  void _openRateMusicPage(Map<String, dynamic> track) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RateMusicPage(track: track),
      ),
    );
  }

  void _showArtistDetails(Map<String, dynamic> artist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(artist['name'] ?? 'Bilinmeyen Sanatçı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Şarkı Sayısı: ${artist['trackCount']}'),
            Text('Ortalama Puan: ${(artist['averageRating'] ?? 0.0).toStringAsFixed(1)}'),
            const SizedBox(height: 16),
            const Text('Şarkılar:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...(artist['tracks'] as List<String>).take(5).map((track) => 
              Text('• $track')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showAlbumDetails(Map<String, dynamic> album) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(album['name'] ?? 'Bilinmeyen Albüm'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sanatçı: ${album['artist']}'),
            Text('Şarkı Sayısı: ${album['trackCount']}'),
            Text('Ortalama Puan: ${(album['averageRating'] ?? 0.0).toStringAsFixed(1)}'),
            const SizedBox(height: 16),
            const Text('Şarkılar:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...(album['tracks'] as List<String>).take(5).map((track) => 
              Text('• $track')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}
