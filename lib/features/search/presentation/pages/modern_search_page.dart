import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/modern_design_system.dart';
import '../../../../shared/services/enhanced_spotify_service.dart';
import '../../../../shared/services/firebase_bypass_auth_service.dart';

class ModernSearchPage extends ConsumerStatefulWidget {
  const ModernSearchPage({super.key});

  @override
  ConsumerState<ModernSearchPage> createState() => _ModernSearchPageState();
}

class _ModernSearchPageState extends ConsumerState<ModernSearchPage> with SingleTickerProviderStateMixin {
  late TextEditingController _searchController;
  late TabController _tabController;
  Timer? _debounce;
  
  List<Map<String, dynamic>> _trackResults = [];
  List<Map<String, dynamic>> _artistResults = [];
  List<Map<String, dynamic>> _albumResults = [];
  List<Map<String, dynamic>> _userResults = [];
  List<String> _recentSearches = [];
  
  bool _isSearching = false;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _tabController = TabController(length: 4, vsync: this);
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searches = prefs.getStringList('recent_searches') ?? [];
      if (mounted) {
        setState(() => _recentSearches = searches);
      }
    } catch (e) {
      print('Error loading recent searches: $e');
    }
  }

  Future<void> _saveSearch(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searches = prefs.getStringList('recent_searches') ?? [];
      
      // Remove if already exists
      searches.remove(query);
      // Add to beginning
      searches.insert(0, query);
      // Keep only last 10
      if (searches.length > 10) {
        searches.removeRange(10, searches.length);
      }
      
      await prefs.setStringList('recent_searches', searches);
      if (mounted) {
        setState(() => _recentSearches = searches);
      }
    } catch (e) {
      print('Error saving search: $e');
    }
  }

  Future<void> _clearSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('recent_searches');
      if (mounted) {
        setState(() => _recentSearches = []);
      }
    } catch (e) {
      print('Error clearing search history: $e');
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _currentQuery = query;
    });

    // Save to search history
    await _saveSearch(query);

    try {
      // Search all types in parallel
      final results = await Future.wait([
        EnhancedSpotifyService.searchTracks(query, limit: 20),
        EnhancedSpotifyService.searchArtists(query, limit: 20),
        EnhancedSpotifyService.searchAlbums(query, limit: 20),
      ]);

      // Search users from Firebase Bypass Auth
      final userResults = _searchUsers(query);

      if (mounted) {
        setState(() {
          _trackResults = results[0] as List<Map<String, dynamic>>;
          _artistResults = results[1] as List<Map<String, dynamic>>;
          _albumResults = results[2] as List<Map<String, dynamic>>;
          
          _userResults = userResults;
          _isSearching = false;
        });
      }
    } catch (e) {
      print('Search error: $e');
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? ModernDesignSystem.darkBackground : ModernDesignSystem.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? ModernDesignSystem.darkSurface : ModernDesignSystem.lightSurface,
        elevation: 0,
        title: Text(
          'Search',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        automaticallyImplyLeading: true,
        bottom: _currentQuery.isNotEmpty ? PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFFFF5E5E),
            unselectedLabelColor: isDark ? Colors.grey[500] : Colors.grey[600],
            indicatorColor: const Color(0xFFFF5E5E),
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Tracks'),
              Tab(text: 'Artists'),
              Tab(text: 'Albums'),
            ],
          ),
        ) : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildSearchBar(isDark),
          ),
          Expanded(
            child: _currentQuery.isEmpty
                ? _buildRecentSearches(isDark)
                : _isSearching
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFFFF5E5E)),
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildAllResultsView(isDark),
                          _buildTracksTab(isDark),
                          _buildArtistsTab(isDark),
                          _buildAlbumsTab(isDark),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllResultsView(bool isDark) {
    if (_currentQuery.isEmpty) {
      return _buildRecentSearches(isDark);
    }

    if (_isSearching) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Albums Section
          if (_albumResults.isNotEmpty) ...
            [
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 12),
                child: Text(
                  'Albums',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              ..._albumResults.take(5).map((album) => _buildAlbumCard(album, isDark)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: GestureDetector(
                  onTap: () => context.push(
                    '/search-results',
                    extra: {
                      'query': _currentQuery,
                      'type': 'albums',
                      'results': _albumResults,
                    },
                  ),
                  child: Text(
                    'View all albums...',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          // Tracks Section
          if (_trackResults.isNotEmpty) ...
            [
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 12),
                child: Text(
                  'Tracks',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              ..._trackResults.take(5).map((track) => _buildTrackCard(track, isDark)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: GestureDetector(
                  onTap: () => context.push(
                    '/search-results',
                    extra: {
                      'query': _currentQuery,
                      'type': 'tracks',
                      'results': _trackResults,
                    },
                  ),
                  child: Text(
                    'View all songs...',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          // Artists Section
          if (_artistResults.isNotEmpty) ...
            [
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 12),
                child: Text(
                  'Artists',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              ..._artistResults.take(5).map((artist) => _buildArtistCard(artist, isDark)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: GestureDetector(
                  onTap: () => context.push(
                    '/search-results',
                    extra: {
                      'query': _currentQuery,
                      'type': 'artists',
                      'results': _artistResults,
                    },
                  ),
                  child: Text(
                    'View all artists...',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
        ],
      ),
    );
  }

  Widget _buildAlbumCard(Map<String, dynamic> album, bool isDark) {
    final imageUrl = (album['images'] as List?)?.isNotEmpty == true
        ? album['images'][0]['url']
        : null;
    final artistNames = (album['artists'] as List?)
        ?.map((a) => a['name'])
        .join(', ') ?? 'Unknown Artist';

    return GestureDetector(
      onTap: () => context.push('/album-detail', extra: album),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: isDark
            ? ModernDesignSystem.darkGlassmorphism
            : BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
                boxShadow: ModernDesignSystem.subtleShadow,
              ),
        child: Row(
          children: [
            // Album cover
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl == null
                  ? Icon(
                      Icons.album,
                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Album info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album['name'] ?? 'Unknown Album',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    artistNames,
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
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumHorizontalCard(Map<String, dynamic> album, bool isDark) {
    final imageUrl = (album['images'] as List?)?.isNotEmpty == true
        ? album['images'][0]['url']
        : null;

    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              image: imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageUrl == null
                ? Icon(
                    Icons.album,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTrackHorizontalCard(Map<String, dynamic> track, bool isDark) {
    final imageUrl = (track['album']?['images'] as List?)?.isNotEmpty == true
        ? track['album']['images'][0]['url']
        : null;

    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              image: imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageUrl == null
                ? Icon(
                    Icons.music_note,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildArtistHorizontalCard(Map<String, dynamic> artist, bool isDark) {
    final imageUrl = (artist['images'] as List?)?.isNotEmpty == true
        ? artist['images'][0]['url']
        : null;

    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              shape: BoxShape.circle,
              image: imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageUrl == null
                ? Icon(
                    Icons.person,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: 'Search songs, artists, or albums...',
          hintStyle: TextStyle(
            color: isDark ? Colors.grey[500] : Colors.grey[500],
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _currentQuery = '';
                      _trackResults = [];
                      _artistResults = [];
                      _albumResults = [];
                      _userResults = [];
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
        ),
        onChanged: (value) {
          setState(() {});
          
          // Debounce search
          if (_debounce?.isActive ?? false) _debounce!.cancel();
          _debounce = Timer(const Duration(milliseconds: 500), () {
            if (value.length >= 1) {
              _performSearch(value);
            }
          });
        },
        onSubmitted: _performSearch,
      ),
    );
  }

  Widget _buildTracksTab(bool isDark) {
    if (_currentQuery.isEmpty) {
      return _buildRecentSearches(isDark);
    }

    if (_isSearching) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
      );
    }

    if (_trackResults.isEmpty) {
      return _buildEmptyState(
        Icons.search_off,
        'No Results',
        'No songs found for "$_currentQuery"',
        isDark,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _trackResults.length,
      itemBuilder: (context, index) {
        final track = _trackResults[index];
        return _buildTrackCard(track, isDark);
      },
    );
  }

  Widget _buildArtistsTab(bool isDark) {
    if (_currentQuery.isEmpty) {
      return _buildRecentSearches(isDark);
    }

    if (_isSearching) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
      );
    }

    if (_artistResults.isEmpty) {
      return _buildEmptyState(
        Icons.search_off,
        'No Results',
        'No artists found for "$_currentQuery"',
        isDark,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _artistResults.length,
      itemBuilder: (context, index) {
        final artist = _artistResults[index];
        return _buildArtistCard(artist, isDark);
      },
    );
  }

  Widget _buildAlbumsTab(bool isDark) {
    if (_currentQuery.isEmpty) {
      return _buildRecentSearches(isDark);
    }

    if (_isSearching) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
      );
    }

    if (_albumResults.isEmpty) {
      return _buildEmptyState(
        Icons.search_off,
        'No Results',
        'No albums found for "$_currentQuery"',
        isDark,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _albumResults.length,
      itemBuilder: (context, index) {
        final album = _albumResults[index];
        return _buildAlbumGridCard(album, isDark);
      },
    );
  }

  Widget _buildUsersTab(bool isDark) {
    if (_currentQuery.isEmpty) {
      return _buildRecentSearches(isDark);
    }

    if (_isSearching) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
      );
    }

    if (_userResults.isEmpty) {
      return _buildEmptyState(
        Icons.search_off,
        'No Results',
        'No users found for "$_currentQuery"',
        isDark,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _userResults.length,
      itemBuilder: (context, index) {
        final user = _userResults[index];
        return _buildUserCard(user, isDark);
      },
    );
  }

  Widget _buildTrackCard(Map<String, dynamic> track, bool isDark) {
    final imageUrl = (track['album']?['images'] as List?)?.isNotEmpty == true
        ? track['album']['images'][0]['url']
        : null;
    final artistNames = (track['artists'] as List?)
        ?.map((a) => a['name'])
        .join(', ') ?? 'Unknown Artist';

    return GestureDetector(
      onTap: () {
        context.push('/track-detail', extra: track);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: isDark
            ? ModernDesignSystem.darkGlassmorphism
            : BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
                boxShadow: ModernDesignSystem.subtleShadow,
              ),
        child: Row(
          children: [
            // Album cover
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl == null
                  ? Icon(
                      Icons.music_note,
                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Track info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track['name'] ?? 'Unknown Track',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    artistNames,
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
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistCard(Map<String, dynamic> artist, bool isDark) {
    final imageUrl = (artist['images'] as List?)?.isNotEmpty == true
        ? artist['images'][0]['url']
        : null;
    final followers = artist['followers']?['total'] ?? 0;

    return GestureDetector(
      onTap: () => context.push('/artist-profile', extra: artist),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: isDark
          ? ModernDesignSystem.darkGlassmorphism
          : BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
              boxShadow: ModernDesignSystem.subtleShadow,
            ),
      child: Row(
        children: [
          // Artist image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              shape: BoxShape.circle,
              image: imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageUrl == null
                ? Icon(
                    Icons.person,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                    size: 32,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Artist info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artist['name'] ?? 'Unknown Artist',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatNumber(followers)} takipçi',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
        ],
      ),
      ),
    );
  }

  List<Map<String, dynamic>> _searchUsers(String query) {
    final allUsers = FirebaseBypassAuthService.allUsers;
    final queryLower = query.toLowerCase();
    
    return allUsers.values
        .where((user) =>
            user.username.toLowerCase().contains(queryLower) ||
            user.displayName.toLowerCase().contains(queryLower) ||
            user.email.toLowerCase().contains(queryLower))
        .map((user) => {
              'userId': user.userId,
              'username': user.username,
              'name': user.displayName,
              'email': user.email,
            })
        .toList();
  }

  Widget _buildUserCard(Map<String, dynamic> user, bool isDark) {
    return GestureDetector(
      onTap: () {
        context.push(
          '/user-profile/${user['userId']}?username=${user['username']}',
        );
      },
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: isDark
          ? ModernDesignSystem.darkGlassmorphism
          : BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
              boxShadow: ModernDesignSystem.subtleShadow,
            ),
      child: Row(
        children: [
          // User avatar
          CircleAvatar(
            radius: 30,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
            child: Text(
              user['name']?.substring(0, 1).toUpperCase() ?? 'U',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'] ?? 'Unknown User',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '@${user['username'] ?? 'unknown'}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildEmptyState(
    IconData icon,
    String title,
    String subtitle,
    bool isDark,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumGridCard(Map<String, dynamic> album, bool isDark) {
    final imageUrl = (album['images'] as List?)?.isNotEmpty == true
        ? album['images'][0]['url']
        : null;
    final artistNames = (album['artists'] as List?)
        ?.map((a) => a['name'])
        .join(', ') ?? 'Unknown Artist';

    return GestureDetector(
      onTap: () => context.push('/album-detail', extra: album),
      child: Container(
        decoration: isDark
            ? ModernDesignSystem.darkGlassmorphism
            : BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
                boxShadow: ModernDesignSystem.subtleShadow,
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album cover
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(ModernDesignSystem.radiusM),
                    topRight: Radius.circular(ModernDesignSystem.radiusM),
                  ),
                  image: imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: imageUrl == null
                    ? Center(
                        child: Icon(
                          Icons.album,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                          size: 48,
                        ),
                      )
                    : null,
              ),
            ),
            // Album info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album['name'] ?? 'Unknown Album',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    artistNames,
                    style: TextStyle(
                      fontSize: 12,
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
    );
  }

  Widget _buildRecentSearches(bool isDark) {
    if (_recentSearches.isEmpty) {
      return _buildEmptyState(
        Icons.search_rounded,
        'Search',
        'Search for songs, artists, albums, or users',
        isDark,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Searches',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            TextButton(
              onPressed: _clearSearchHistory,
              child: Text(
                'Clear',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._recentSearches.map((search) => ListTile(
              leading: Icon(
                Icons.history,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              title: Text(
                search,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              onTap: () {
                _searchController.text = search;
                _performSearch(search);
              },
              trailing: IconButton(
                icon: Icon(
                  Icons.close,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                  size: 20,
                ),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final searches = prefs.getStringList('recent_searches') ?? [];
                  searches.remove(search);
                  await prefs.setStringList('recent_searches', searches);
                  setState(() => _recentSearches = searches);
                },
              ),
            )),
      ],
    );
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
