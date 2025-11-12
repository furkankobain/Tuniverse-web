import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/modern_design_system.dart';
import '../../../../shared/services/firebase_bypass_auth_service.dart';

class PlaylistDetailPage extends StatefulWidget {
  final String playlistId;

  const PlaylistDetailPage({
    super.key,
    required this.playlistId,
  });

  @override
  State<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _playlistData;
  List<Map<String, dynamic>> _tracks = [];
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _loadPlaylist();
  }

  Future<void> _loadPlaylist() async {
    setState(() => _isLoading = true);

    try {
      final currentUserId = FirebaseBypassAuthService.currentUserId;
      
      // Load playlist data
      final playlistDoc = await FirebaseFirestore.instance
          .collection('playlists')
          .doc(widget.playlistId)
          .get();

      if (playlistDoc.exists) {
        _playlistData = playlistDoc.data();
        _isOwner = _playlistData?['userId'] == currentUserId;

        // Load tracks
        final tracksSnapshot = await FirebaseFirestore.instance
            .collection('playlists')
            .doc(widget.playlistId)
            .collection('tracks')
            .orderBy('addedAt', descending: false)
            .get();

        _tracks = tracksSnapshot.docs
            .map((doc) => {...doc.data(), 'id': doc.id})
            .toList();
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading playlist: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sharePlaylist() async {
    if (_playlistData == null) return;

    final playlistName = _playlistData!['name'] ?? 'Playlist';
    final trackCount = _tracks.length;
    
    await Share.share(
      'Check out my playlist "$playlistName" with $trackCount tracks!\n\nCreated on Tuniverse 🎵',
      subject: playlistName,
    );
  }

  Future<void> _deletePlaylist() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Playlist\'i Sil'),
        content: const Text('Bu playlist\'i silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await FirebaseFirestore.instance
            .collection('playlists')
            .doc(widget.playlistId)
            .delete();
        
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Playlist silindi'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('Error deleting playlist: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Silme işlemi başarısız'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _removeTrack(String trackId) async {
    try {
      await FirebaseFirestore.instance
          .collection('playlists')
          .doc(widget.playlistId)
          .collection('tracks')
          .doc(trackId)
          .delete();

      await _loadPlaylist();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şarkı kaldırıldı'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error removing track: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: isDark
              ? ModernDesignSystem.darkBackground
              : ModernDesignSystem.lightBackground,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_playlistData == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: isDark
              ? ModernDesignSystem.darkBackground
              : ModernDesignSystem.lightBackground,
        ),
        body: const Center(
          child: Text('Playlist bulunamadı'),
        ),
      );
    }

    final playlistName = _playlistData!['name'] ?? 'Untitled Playlist';
    final description = _playlistData!['description'] ?? '';
    final coverUrl = _playlistData!['coverUrl'];

    return Scaffold(
      backgroundColor: isDark
          ? ModernDesignSystem.darkBackground
          : ModernDesignSystem.lightBackground,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: isDark
                ? ModernDesignSystem.darkSurface
                : ModernDesignSystem.lightSurface,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (coverUrl != null)
                    CachedNetworkImage(
                      imageUrl: coverUrl,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: ModernDesignSystem.primaryGradient,
                      ),
                      child: const Icon(
                        Icons.queue_music,
                        size: 100,
                        color: Colors.white54,
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          isDark ? Colors.black : Colors.white,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playlistName,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          '${_tracks.length} şarkı',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _sharePlaylist,
              ),
              if (_isOwner)
                PopupMenuButton(
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
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deletePlaylist();
                    } else if (value == 'edit') {
                      // TODO: Navigate to edit page
                    }
                  },
                ),
            ],
          ),

          // Tracks list
          if (_tracks.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.music_note, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Henüz şarkı eklenmemiş',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final track = _tracks[index];
                  return _buildTrackItem(track, isDark);
                },
                childCount: _tracks.length,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrackItem(Map<String, dynamic> track, bool isDark) {
    final trackName = track['name'] ?? 'Unknown';
    final artistName = track['artist'] ?? 'Unknown Artist';
    final imageUrl = track['imageUrl'];

    return Dismissible(
      key: Key(track['id']),
      direction: _isOwner ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (_isOwner) {
          await _removeTrack(track['id']);
          return true;
        }
        return false;
      },
      child: ListTile(
        leading: imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              )
            : Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.music_note, color: Colors.grey),
              ),
        title: Text(
          trackName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          artistName,
          style: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: _isOwner
            ? IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  // Show track options
                },
              )
            : null,
      ),
    );
  }
}
