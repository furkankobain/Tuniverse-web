import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import '../../../../core/theme/modern_design_system.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/services/enhanced_spotify_service.dart';
import '../../../../shared/widgets/loading/shimmer_loading.dart';
import '../../../reviews/presentation/pages/add_review_page.dart';
import '../../../playlists/import_spotify_playlists_page.dart';

class CreateContentPage extends ConsumerStatefulWidget {
  const CreateContentPage({super.key});

  @override
  ConsumerState<CreateContentPage> createState() => _CreateContentPageState();
}

class _CreateContentPageState extends ConsumerState<CreateContentPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;
  
  bool _isSearching = false;
  String _selectedType = 'review'; // 'review' or 'playlist'
  
  List<Map<String, dynamic>> _tracks = [];
  List<Map<String, dynamic>> _albums = [];
  List<Map<String, dynamic>> _artists = [];

  @override
  void initState() {
    super.initState();
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    
    setState(() => _isSearching = true);

    try {
      print('🔍 Creating search for: $query');
      
      // Use parallel searches for better performance
      final results = await Future.wait([
        EnhancedSpotifyService.searchTracks(query, limit: 20),
        EnhancedSpotifyService.searchAlbums(query, limit: 20),
        EnhancedSpotifyService.searchArtists(query, limit: 20),
      ]);
      
      if (mounted) {
        final tracks = results[0] as List<Map<String, dynamic>>;
        final albums = results[1] as List<Map<String, dynamic>>;
        final artists = results[2] as List<Map<String, dynamic>>;
        
        print('📦 Found ${tracks.length} tracks, ${albums.length} albums, ${artists.length} artists');
        
        setState(() {
          _tracks = tracks;
          _albums = albums;
          _artists = artists;
          _isSearching = false;
        });
      }
    } catch (e) {
      print('❌ Search error: $e');
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _handleItemTap(Map<String, dynamic> item) async {
    if (_selectedType == 'review') {
      // Determine item type
      final itemType = item['type'] as String?;
      if (itemType == null) return;
      
      // Navigate to review creation page
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AddReviewPage(
            item: item,
            itemType: itemType,
          ),
        ),
      );
      
      // If review was posted, go back to home
      if (result == true && mounted) {
        context.go('/');
      }
    } else {
      // Show playlist selection dialog
      _showAddToPlaylistDialog(item);
    }
  }
  
  Future<void> _showAddToPlaylistDialog(Map<String, dynamic> item) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? ModernDesignSystem.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context).t('add_to_playlist'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5E5E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add,
                  color: Color(0xFFFF5E5E),
                ),
              ),
              title: Text(AppLocalizations.of(context).t('create_new_playlist')),
              onTap: () {
                Navigator.pop(context);
                context.push('/playlists/create');
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.library_music,
                  color: Colors.blue,
                ),
              ),
              title: Text(AppLocalizations.of(context).t('view_my_playlists')),
              onTap: () {
                Navigator.pop(context);
                context.go('/');
                // Navigate to playlists tab
                setState(() {});
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? ModernDesignSystem.darkBackground : ModernDesignSystem.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? ModernDesignSystem.darkSurface : ModernDesignSystem.lightSurface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          AppLocalizations.of(context).t('create'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Header with stats
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What would you like to create?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTypeButton(
                        'Review',
                        Icons.rate_review,
                        'review',
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTypeButton(
                        'Playlist',
                        Icons.playlist_add,
                        'playlist',
                        isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'Search tracks, albums, artists...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[500]),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _tracks.clear();
                            _albums.clear();
                            _artists.clear();
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {});
                _debounceTimer?.cancel();
                
                if (value.isNotEmpty) {
                  _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                    _performSearch(value);
                  });
                } else {
                  setState(() {
                    _tracks.clear();
                    _albums.clear();
                    _artists.clear();
                  });
                }
              },
              onSubmitted: _performSearch,
            ),
          ),

          const SizedBox(height: 16),

          // Results
          Expanded(
            child: _buildResults(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String label, IconData icon, String type, bool isDark) {
    final isSelected = _selectedType == type;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF5E5E)
              : (isDark ? Colors.grey[800] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600]),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600]),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(bool isDark) {
    if (_searchController.text.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 12),
            if (_selectedType == 'playlist')
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Navigate to Spotify import page
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ImportSpotifyPlaylistsPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1DB954),
                  ),
                  icon: const Icon(Icons.library_music),
                  label: const Text('Import from Spotify'),
                ),
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5E5E), Color(0xFFFF8E8E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5E5E).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.8, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) => Transform.scale(
                      scale: value,
                      child: Icon(
                        _selectedType == 'review' ? Icons.rate_review : Icons.playlist_add,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _selectedType == 'review'
                        ? 'Share Your Opinion'
                        : 'Build Your Collection',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedType == 'review'
                        ? 'Search for any track, album, or artist to write a review'
                        : 'Search for music to create your perfect playlist',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildQuickTips(isDark),
          ],
        ),
      );
    }

    if (_isSearching) {
      return const ShimmerList(itemCount: 10);
    }

    final hasResults = _tracks.isNotEmpty || _albums.isNotEmpty || _artists.isNotEmpty;
    if (!hasResults) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_tracks.isNotEmpty) ...[
          _buildSectionHeader('Tracks', isDark),
          ..._tracks.map((track) => _buildResultItem(track, 'track', isDark)),
          const SizedBox(height: 16),
        ],
        if (_albums.isNotEmpty) ...[
          _buildSectionHeader('Albums', isDark),
          ..._albums.map((album) => _buildResultItem(album, 'album', isDark)),
          const SizedBox(height: 16),
        ],
        if (_artists.isNotEmpty) ...[
          _buildSectionHeader('Artists', isDark),
          ..._artists.map((artist) => _buildResultItem(artist, 'artist', isDark)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _buildResultItem(Map<String, dynamic> item, String type, bool isDark) {
    final name = item['name'] as String? ?? 'Unknown';
    String? imageUrl;
    String subtitle = '';

    if (type == 'track') {
      final album = item['album'] as Map<String, dynamic>?;
      final images = album?['images'] as List?;
      imageUrl = images?.isNotEmpty == true ? images![0]['url'] as String? : null;
      final artists = item['artists'] as List?;
      subtitle = artists?.isNotEmpty == true
          ? artists!.map((a) => a['name']).join(', ')
          : 'Unknown Artist';
    } else if (type == 'album') {
      final images = item['images'] as List?;
      imageUrl = images?.isNotEmpty == true ? images![0]['url'] as String? : null;
      final artists = item['artists'] as List?;
      subtitle = artists?.isNotEmpty == true
          ? artists!.map((a) => a['name']).join(', ')
          : 'Unknown Artist';
    } else if (type == 'artist') {
      final images = item['images'] as List?;
      imageUrl = images?.isNotEmpty == true ? images![0]['url'] as String? : null;
      subtitle = 'Artist';
    }

    return GestureDetector(
      onTap: () => _handleItemTap(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(type == 'artist' ? 28 : 8),
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl == null
                  ? Icon(
                      type == 'track' ? Icons.music_note : (type == 'album' ? Icons.album : Icons.person),
                      color: Colors.grey[600],
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickTips(bool isDark) {
    final tips = _selectedType == 'review'
        ? [
            {'icon': Icons.star, 'title': 'Rate & Review', 'desc': 'Share your thoughts on music you love'},
            {'icon': Icons.people, 'title': 'Connect', 'desc': 'Help others discover great music'},
            {'icon': Icons.trending_up, 'title': 'Track Stats', 'desc': 'See your review history and impact'},
          ]
        : [
            {'icon': Icons.queue_music, 'title': 'Organize', 'desc': 'Create playlists for any mood or occasion'},
            {'icon': Icons.share, 'title': 'Share', 'desc': 'Share your playlists with friends'},
            {'icon': Icons.shuffle, 'title': 'Discover', 'desc': 'Get recommendations based on your taste'},
          ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Tips',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        ...tips.map((tip) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5E5E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  tip['icon'] as IconData,
                  color: const Color(0xFFFF5E5E),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tip['title'] as String,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tip['desc'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}
