import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import '../../../../core/theme/modern_design_system.dart';
import '../../../../shared/services/enhanced_spotify_service.dart';
import '../../../../shared/widgets/cards/album_card.dart';
import '../../../../shared/widgets/cards/track_card.dart';
import '../../../../shared/widgets/loading/shimmer_loading.dart';

class DiscoverSearchPage extends ConsumerStatefulWidget {
  const DiscoverSearchPage({super.key});

  @override
  ConsumerState<DiscoverSearchPage> createState() => _DiscoverSearchPageState();
}

class _DiscoverSearchPageState extends ConsumerState<DiscoverSearchPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;
  
  bool _isSearching = false;
  
  // Separate results for each tab
  List<Map<String, dynamic>> _tracks = [];
  List<Map<String, dynamic>> _albums = [];
  List<Map<String, dynamic>> _artists = [];
  List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> _playlists = [];
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _searchFocusNode.requestFocus();
    _tabController.addListener(_onTabChanged);
  }
  
  void _onTabChanged() {
    if (_searchController.text.isNotEmpty) {
      _performSearch(_searchController.text);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    
    setState(() => _isSearching = true);

    try {
      final currentTab = _tabController.index;
      
      switch (currentTab) {
        case 0: // All
          await _searchAll(query);
          break;
        case 1: // Tracks
          await _searchTracks(query);
          break;
        case 2: // Artists
          await _searchArtists(query);
          break;
        case 3: // Albums
          await _searchAlbums(query);
          break;
        case 4: // Users
          await _searchUsers(query);
          break;
      }
      
      if (mounted) {
        setState(() => _isSearching = false);
      }
    } catch (e) {
      print('Search error: $e');
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }
  
  Future<void> _searchAll(String query) async {
    print('🔍 Searching all for: $query');
    final results = await EnhancedSpotifyService.search(
      query: query,
      types: ['track', 'album', 'artist'],
      limit: 10,
    );
    
    print('📦 Search results received: ${results.keys}');
    
    if (mounted) {
      final tracks = (results['tracks']?['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final albums = (results['albums']?['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final artists = (results['artists']?['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      
      print('🎵 Found ${tracks.length} tracks, ${albums.length} albums, ${artists.length} artists');
      
      setState(() {
        _tracks = tracks;
        _albums = albums;
        _artists = artists;
      });
    }
    
    // Also search Firestore for users and playlists
    await Future.wait([
      _searchUsers(query),
      _searchPlaylists(query),
    ]);
  }
  
  Future<void> _searchTracks(String query) async {
    print('🎵 Searching tracks for: $query');
    final results = await EnhancedSpotifyService.search(
      query: query,
      types: ['track'],
      limit: 30,
    );
    
    final tracks = (results['tracks']?['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    print('🎵 Found ${tracks.length} tracks');
    
    if (mounted) {
      setState(() {
        _tracks = tracks;
      });
    }
  }
  
  Future<void> _searchArtists(String query) async {
    final results = await EnhancedSpotifyService.search(
      query: query,
      types: ['artist'],
      limit: 30,
    );
    
    if (mounted) {
      setState(() {
        _artists = (results['artists']?['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      });
    }
  }
  
  Future<void> _searchAlbums(String query) async {
    final results = await EnhancedSpotifyService.search(
      query: query,
      types: ['album'],
      limit: 30,
    );
    
    if (mounted) {
      setState(() {
        _albums = (results['albums']?['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      });
    }
  }
  
  Future<void> _searchUsers(String query) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('username', isLessThan: query.toLowerCase() + 'z')
          .limit(20)
          .get();
      
      if (mounted) {
        setState(() {
          _users = querySnapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();
        });
      }
    } catch (e) {
      print('Error searching users: $e');
    }
  }
  
  Future<void> _searchPlaylists(String query) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('playlists')
          .where('name', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('name', isLessThan: query.toLowerCase() + 'z')
          .limit(20)
          .get();
      
      if (mounted) {
        setState(() {
          _playlists = querySnapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();
        });
      }
    } catch (e) {
      print('Error searching playlists: $e');
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: 'Search music, artists, albums, users...',
            hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[500]),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _tracks.clear();
                        _albums.clear();
                        _artists.clear();
                        _users.clear();
                      });
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            setState(() {});
            // Cancel previous timer
            _debounceTimer?.cancel();
            
            if (value.isNotEmpty) {
              // Start new timer for debounce (500ms)
              _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                _performSearch(value);
              });
            } else {
              // Clear results immediately if search is empty
              setState(() {
                _tracks.clear();
                _albums.clear();
                _artists.clear();
                _users.clear();
              });
            }
          },
          onSubmitted: _performSearch,
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFFF5E5E),
          unselectedLabelColor: isDark ? Colors.grey[500] : Colors.grey[600],
          indicatorColor: const Color(0xFFFF5E5E),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Tracks'),
            Tab(text: 'Artists'),
            Tab(text: 'Albums'),
            Tab(text: 'Users'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllTab(isDark),
          _buildTracksTab(isDark),
          _buildArtistsTab(isDark),
          _buildAlbumsTab(isDark),
          _buildUsersTab(isDark),
        ],
      ),
    );
  }

  Widget _buildAllTab(bool isDark) {
    if (_searchController.text.isEmpty) {
      return _buildEmptyState('Start typing to search...', Icons.search, isDark);
    }

    if (_isSearching) {
      return const ShimmerList(itemCount: 8);
    }

    final hasResults = _tracks.isNotEmpty || _albums.isNotEmpty || _artists.isNotEmpty || _users.isNotEmpty;
    if (!hasResults) {
      return _buildEmptyState('No results found', Icons.search_off, isDark);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_tracks.isNotEmpty) ...[
          _buildSectionHeader('Tracks', isDark),
          ..._tracks.take(5).map((track) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TrackCard(track: track),
          )),
          const SizedBox(height: 16),
        ],
        if (_artists.isNotEmpty) ...[
          _buildSectionHeader('Artists', isDark),
          ..._artists.take(3).map((artist) => _buildArtistTile(artist, isDark)),
          const SizedBox(height: 16),
        ],
        if (_albums.isNotEmpty) ...[
          _buildSectionHeader('Albums', isDark),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _albums.take(10).length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 160,
                  child: AlbumCard(album: _albums[index]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (_users.isNotEmpty) ...[
          _buildSectionHeader('Users', isDark),
          ..._users.take(3).map((user) => _buildUserTile(user, isDark)),
        ],
      ],
    );
  }
  
  Widget _buildTracksTab(bool isDark) {
    if (_searchController.text.isEmpty) {
      return _buildEmptyState('Search for tracks...', Icons.music_note, isDark);
    }

    if (_isSearching) {
      return const ShimmerList(itemCount: 10);
    }

    if (_tracks.isEmpty) {
      return _buildEmptyState('No tracks found', Icons.search_off, isDark);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tracks.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TrackCard(track: _tracks[index]),
      ),
    );
  }
  
  Widget _buildArtistsTab(bool isDark) {
    if (_searchController.text.isEmpty) {
      return _buildEmptyState('Search for artists...', Icons.person, isDark);
    }

    if (_isSearching) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 10,
        itemBuilder: (context, index) => const ShimmerListTile(),
      );
    }

    if (_artists.isEmpty) {
      return _buildEmptyState('No artists found', Icons.search_off, isDark);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _artists.length,
      itemBuilder: (context, index) => _buildArtistTile(_artists[index], isDark),
    );
  }
  
  Widget _buildAlbumsTab(bool isDark) {
    if (_searchController.text.isEmpty) {
      return _buildEmptyState('Search for albums...', Icons.album, isDark);
    }

    if (_isSearching) {
      return const ShimmerGrid(itemCount: 10);
    }

    if (_albums.isEmpty) {
      return _buildEmptyState('No albums found', Icons.search_off, isDark);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: _albums.length,
      itemBuilder: (context, index) => AlbumCard(album: _albums[index]),
    );
  }

  Widget _buildUsersTab(bool isDark) {
    if (_searchController.text.isEmpty) {
      return _buildEmptyState('Search for users...', Icons.people, isDark);
    }

    if (_isSearching) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        itemBuilder: (context, index) => const ShimmerListTile(),
      );
    }

    if (_users.isEmpty) {
      return _buildEmptyState('No users found', Icons.search_off, isDark);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (context, index) => _buildUserTile(_users[index], isDark),
    );
  }
  
  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
    );
  }
  
  Widget _buildArtistTile(Map<String, dynamic> artist, bool isDark) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: CircleAvatar(
        radius: 30,
        backgroundImage: artist['images'] != null && (artist['images'] as List).isNotEmpty
            ? NetworkImage((artist['images'] as List)[0]['url'])
            : null,
        backgroundColor: const Color(0xFFFF5E5E).withOpacity(0.2),
        child: artist['images'] == null || (artist['images'] as List).isEmpty
            ? const Icon(Icons.person, color: Color(0xFFFF5E5E))
            : null,
      ),
      title: Text(
        artist['name'] ?? 'Unknown Artist',
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        'Artist • ${artist['followers']?['total']?.toString() ?? '0'} followers',
        style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFFFF5E5E)),
      onTap: () => context.push('/artist/${artist['id']}'),
    );
  }
  
  Widget _buildUserTile(Map<String, dynamic> user, bool isDark) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: CircleAvatar(
        radius: 30,
        backgroundImage: user['profileImage'] != null
            ? NetworkImage(user['profileImage'])
            : null,
        backgroundColor: const Color(0xFFFF5E5E).withOpacity(0.2),
        child: user['profileImage'] == null
            ? const Icon(Icons.person, color: Color(0xFFFF5E5E))
            : null,
      ),
      title: Text(
        user['username'] ?? 'Unknown User',
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        user['bio'] ?? 'Music lover',
        style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFFFF5E5E)),
      onTap: () => context.push('/profile/${user['id']}'),
    );
  }

  Widget _buildEmptyState(String message, IconData icon, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: isDark ? Colors.grey[700] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: isDark ? Colors.grey[500] : Colors.grey[600],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
