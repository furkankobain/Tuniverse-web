import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/models/music_list.dart';
import '../../shared/services/playlist_service.dart';
import '../../shared/services/playlist_sync_service.dart';
import '../../shared/services/enhanced_spotify_service.dart';
import '../../shared/services/firebase_bypass_auth_service.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/add_track_bottom_sheet.dart';
import 'widgets/playlist_share_bottom_sheet.dart';
import 'widgets/manage_collaborators_bottom_sheet.dart';

class PlaylistDetailPage extends StatefulWidget {
  final MusicList playlist;

  const PlaylistDetailPage({super.key, required this.playlist});

  @override
  State<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  late MusicList _playlist;
  Map<String, Map<String, dynamic>> _trackDetails = {};
  bool _isLoadingTracks = false;

  @override
  void initState() {
    super.initState();
    _playlist = widget.playlist;
    _loadTrackDetails();
  }

  Future<void> _loadTrackDetails() async {
    if (_playlist.trackIds.isEmpty) return;

    setState(() => _isLoadingTracks = true);

    try {
      // Filter out tracks that are already loaded
      final tracksToLoad = _playlist.trackIds
          .where((id) => !_trackDetails.containsKey(id))
          .toList();

      if (tracksToLoad.isEmpty) {
        setState(() => _isLoadingTracks = false);
        return;
      }

      // Batch load tracks in groups of 20 for better performance
      const batchSize = 20;
      final batches = <List<String>>[];
      for (var i = 0; i < tracksToLoad.length; i += batchSize) {
        final end = (i + batchSize < tracksToLoad.length) ? i + batchSize : tracksToLoad.length;
        batches.add(tracksToLoad.sublist(i, end));
      }

      // Load batches concurrently
      for (final batch in batches) {
        final futures = batch.map((trackId) async {
          try {
            final response = await EnhancedSpotifyService.getTrackDetails(trackId);
            return MapEntry(trackId, response);
          } catch (e) {
            print('Error loading track $trackId: $e');
            return null;
          }
        });

        final results = await Future.wait(futures);
        
        if (mounted) {
          setState(() {
            for (final entry in results) {
              if (entry != null && entry.value != null) {
                _trackDetails[entry.key] = entry.value!;
              }
            }
          });
        }
      }
    } catch (e) {
      print('Error loading track details: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingTracks = false);
      }
    }
  }

  Future<void> _exportToSpotify() async {
    if (_playlist.source != 'local') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This playlist is already synced with Spotify')),
      );
      return;
    }

    final spotifyId = await PlaylistSyncService.exportToSpotify(_playlist.id);

    if (!mounted) return;

    if (spotifyId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exported to Spotify!')),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to export to Spotify')),
      );
    }
  }

  Future<void> _showAddTrackSheet() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTrackBottomSheet(
        playlistId: _playlist.id,
        onTrackAdded: () {
          // Refresh playlist data
          setState(() {
            // Will be updated via StreamBuilder if we convert to it
          });
        },
      ),
    );
  }

  Future<void> _removeTrack(String trackId) async {
    final success = await PlaylistService.removeTrack(_playlist.id, trackId);

    if (!mounted) return;

    if (success) {
      setState(() {
        _playlist = _playlist.copyWith(
          trackIds: _playlist.trackIds.where((id) => id != trackId).toList(),
        );
        _trackDetails.remove(trackId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Track removed')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to remove track')),
      );
    }
  }

  Future<void> _deletePlaylist() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Playlist'),
        content: const Text('Are you sure you want to delete this playlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await PlaylistService.deletePlaylist(_playlist.id);

    if (!mounted) return;

    if (success) {
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete')),
      );
    }
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
          _playlist.title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => context.pop(),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: isDark ? Colors.white : Colors.black87),
            onSelected: (value) {
              switch (value) {
                case 'manage':
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => ManageCollaboratorsBottomSheet(playlist: _playlist),
                  );
                  break;
                case 'share':
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => PlaylistShareBottomSheet(playlist: _playlist),
                  );
                  break;
                case 'export':
                  _exportToSpotify();
                  break;
                case 'delete':
                  _deletePlaylist();
                  break;
              }
            },
            itemBuilder: (context) => [
              if (_playlist.canManage(FirebaseBypassAuthService.currentUserId ?? ''))
                const PopupMenuItem(
                  value: 'manage',
                  child: Row(
                    children: [
                      Icon(Icons.people, size: 20),
                      SizedBox(width: 12),
                      Text('İşbirlikçileri Yönet'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, size: 20),
                    SizedBox(width: 12),
                    Text('Paylaş'),
                  ],
                ),
              ),
              if (_playlist.source == 'local')
                const PopupMenuItem(
                  value: 'export',
                  child: Text('Spotify\'a Gönder'),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Cover
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _playlist.coverImage != null
                  ? Image.network(
                      _playlist.coverImage!,
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(isDark),
                    )
                  : _buildPlaceholder(isDark),
            ),
          ),
          const SizedBox(height: 24),

          // Info
          Text(
            _playlist.title,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (_playlist.description != null && _playlist.description!.isNotEmpty)
            Text(
              _playlist.description!,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 12),

          // Tags
          if (_playlist.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: _playlist.tags.map((tag) {
                  return Chip(
                    label: Text(
                      tag,
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                    labelStyle: TextStyle(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 16),

          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getSourceIcon(_playlist.source),
                size: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                '${_playlist.trackIds.length} songs',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                _playlist.isPublic ? Icons.public : Icons.lock,
                size: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                _playlist.isPublic ? 'Public' : 'Private',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Add Track Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _showAddTrackSheet,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Add Song',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Tracks
          if (_isLoadingTracks)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_playlist.trackIds.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.music_note,
                    size: 60,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No songs added yet',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          else
            ...List.generate(
              _playlist.trackIds.length,
              (index) {
                final trackId = _playlist.trackIds[index];
                final trackData = _trackDetails[trackId];

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[850] : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    leading: trackData != null && trackData['album']?['images'] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              trackData['album']['images'][0]['url'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 50,
                                height: 50,
                                color: isDark ? Colors.grey[800] : Colors.grey[200],
                                child: const Icon(Icons.music_note),
                              ),
                            ),
                          )
                        : Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[800] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                    title: Text(
                      trackData?['name'] ?? 'Loading...',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      trackData?['artists']?[0]?['name'] ?? trackId,
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      onSelected: (value) {
                        if (value == 'remove') {
                          _removeTrack(trackId);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'remove',
                          child: Text('Kaldır', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.music_note,
        color: isDark ? Colors.grey[600] : Colors.grey[400],
        size: 80,
      ),
    );
  }

  IconData _getSourceIcon(String source) {
    switch (source) {
      case 'spotify':
        return Icons.album;
      case 'synced':
        return Icons.sync;
      default:
        return Icons.folder;
    }
  }
}
