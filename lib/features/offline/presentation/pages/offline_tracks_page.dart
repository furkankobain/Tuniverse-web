import 'package:flutter/material.dart';
import 'package:tuniverse/shared/services/offline_service.dart';
import 'package:tuniverse/shared/services/firebase_bypass_auth_service.dart';

class OfflineTracksPage extends StatefulWidget {
  const OfflineTracksPage({super.key});

  @override
  State<OfflineTracksPage> createState() => _OfflineTracksPageState();
}

class _OfflineTracksPageState extends State<OfflineTracksPage> {
  List<Map<String, dynamic>> _tracks = [];
  bool _isLoading = true;
  StorageInfo _storageInfo = StorageInfo(used: 0, available: 0, total: 0);

  @override
  void initState() {
    super.initState();
    _loadTracks();
    _loadStorageInfo();
  }

  Future<void> _loadTracks() async {
    setState(() => _isLoading = true);
    final tracks = await OfflineService.getDownloadedTracks();
    setState(() {
      _tracks = tracks;
      _isLoading = false;
    });
  }

  Future<void> _loadStorageInfo() async {
    final info = await OfflineService.getStorageInfo();
    setState(() => _storageInfo = info);
  }

  Future<void> _deleteTrack(String trackId) async {
    final currentUser = FirebaseBypassAuthService.currentUser;
    if (currentUser == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Track'),
        content: const Text('Remove this track from offline storage?'),
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

    if (confirmed == true) {
      await OfflineService.deleteTrack(trackId, currentUser.userId);
      _loadTracks();
      _loadStorageInfo();
    }
  }

  Future<void> _deleteAllTracks() async {
    final currentUser = FirebaseBypassAuthService.currentUser;
    if (currentUser == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Tracks'),
        content: const Text('Remove all downloaded tracks? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await OfflineService.deleteAllTracks(currentUser.userId);
      _loadTracks();
      _loadStorageInfo();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Tracks'),
        actions: [
          if (_tracks.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Delete All',
              onPressed: _deleteAllTracks,
            ),
        ],
      ),
      body: Column(
        children: [
          _buildStorageCard(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _tracks.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _tracks.length,
                        itemBuilder: (context, index) {
                          final track = _tracks[index];
                          return _TrackTile(
                            track: track,
                            onDelete: () => _deleteTrack(track['trackId']),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storage, color: Color(0xFFFF5E5E)),
                const SizedBox(width: 8),
                const Text(
                  'Storage Used',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _storageInfo.usedPercentage / 100,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF5E5E)),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _storageInfo.usedFormatted,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  '${_storageInfo.usedPercentage.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.download, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No Offline Tracks',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Download tracks for offline listening',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _TrackTile extends StatelessWidget {
  final Map<String, dynamic> track;
  final VoidCallback onDelete;

  const _TrackTile({required this.track, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final trackName = track['trackName'] as String;
    final artistName = track['artistName'] as String;
    final fileSize = track['fileSize'] as int;
    final sizeFormatted = _formatBytes(fileSize);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFFF5E5E).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.music_note, color: Color(0xFFFF5E5E)),
        ),
        title: Text(
          trackName,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(artistName, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              sizeFormatted,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
