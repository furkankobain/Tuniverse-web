import 'package:flutter/material.dart';
import '../../shared/services/enhanced_spotify_service.dart';
import '../../shared/services/playlist_sync_service.dart';
import '../../core/theme/app_theme.dart';

class ImportSpotifyPlaylistsPage extends StatefulWidget {
  const ImportSpotifyPlaylistsPage({super.key});

  @override
  State<ImportSpotifyPlaylistsPage> createState() => _ImportSpotifyPlaylistsPageState();
}

class _ImportSpotifyPlaylistsPageState extends State<ImportSpotifyPlaylistsPage> {
  List<Map<String, dynamic>> _playlists = [];
  Set<String> _selectedIds = {};
  bool _isLoading = true;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _loadSpotifyPlaylists();
  }

  Future<void> _loadSpotifyPlaylists() async {
    setState(() => _isLoading = true);
    
    try {
      if (!EnhancedSpotifyService.isConnected) {
        throw Exception('Spotify connection required. Please sign in first.');
      }
      
      final rawPlaylists = await EnhancedSpotifyService.getUserPlaylists();
      
      if (!mounted) return;
      
      // Transform Spotify API data to our format
      final playlists = rawPlaylists.map((playlist) {
        final images = playlist['images'] as List?;
        final tracks = playlist['tracks'] as Map<String, dynamic>?;
        
        return {
          'id': playlist['id'],
          'name': playlist['name'],
          'cover_image': images != null && images.isNotEmpty ? images[0]['url'] : null,
          'tracks_count': tracks?['total'] ?? 0,
        };
      }).toList();
      
      setState(() {
        _playlists = playlists;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
      
      Navigator.pop(context);
    }
  }

  Future<void> _importSelected() async {
    if (_selectedIds.isEmpty) return;

    setState(() => _isImporting = true);

    final imported = await PlaylistSyncService.importSpotifyPlaylists(
      _selectedIds.toList(),
    );

    if (!mounted) return;

    setState(() => _isImporting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${imported.length} playlist(s) imported successfully')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundColor : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        elevation: 0,
        title: Text(
          'Import from Spotify',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_selectedIds.isNotEmpty)
            TextButton(
              onPressed: _isImporting ? null : _importSelected,
              child: Text(
                'Import (${_selectedIds.length})',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _playlists.isEmpty
              ? _buildEmptyState(isDark)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = _playlists[index];
                    final isSelected = _selectedIds.contains(playlist['id']);
                    
                    return _buildPlaylistTile(playlist, isSelected, isDark);
                  },
                ),
    );
  }

  Widget _buildPlaylistTile(Map<String, dynamic> playlist, bool isSelected, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedIds.remove(playlist['id']);
            } else {
              _selectedIds.add(playlist['id']);
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryColor
                  : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Checkbox
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : (isDark ? Colors.grey[600]! : Colors.grey[400]!),
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),

              // Cover
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: playlist['cover_image'] != null
                    ? Image.network(
                        playlist['cover_image'],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(isDark),
                      )
                    : _buildPlaceholder(isDark),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist['name'] ?? 'Unnamed',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${playlist['tracks_count']} tracks',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.music_note,
        color: isDark ? Colors.grey[600] : Colors.grey[400],
        size: 24,
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.queue_music,
            size: 80,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Spotify playlists found',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create playlists in your Spotify account',
            style: TextStyle(
              color: isDark ? Colors.grey[500] : Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
