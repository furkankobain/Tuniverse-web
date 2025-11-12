import 'package:flutter/material.dart';
import 'package:tuniverse/shared/services/group_session_service.dart';
import 'package:tuniverse/shared/services/firebase_bypass_auth_service.dart';
import 'dart:async';

class GroupSessionDetailPage extends StatefulWidget {
  final String sessionId;

  const GroupSessionDetailPage({super.key, required this.sessionId});

  @override
  State<GroupSessionDetailPage> createState() => _GroupSessionDetailPageState();
}

class _GroupSessionDetailPageState extends State<GroupSessionDetailPage> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _session;
  bool _isLoading = true;
  bool _isHost = false;
  Timer? _syncTimer;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSession();
    _startSync();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _startSync() {
    _syncTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _loadSession(silent: true);
    });
  }

  Future<void> _loadSession({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    
    final currentUser = FirebaseBypassAuthService.currentUser;
    if (currentUser == null) return;

    final session = await GroupSessionService.getSessionDetails(widget.sessionId);
    
    if (mounted) {
      setState(() {
        _session = session;
        _isHost = session['hostId'] == currentUser.userId;
        _isLoading = false;
      });
    }
  }

  Future<void> _addTrackToQueue() async {
    // In a real app, this would open a track picker
    final currentUser = FirebaseBypassAuthService.currentUser;
    if (currentUser == null) return;

    final trackId = 'track_${DateTime.now().millisecondsSinceEpoch}';
    final trackData = {
      'id': trackId,
      'title': 'Sample Track',
      'artist': 'Sample Artist',
    };
    await GroupSessionService.addToQueue(
      sessionId: widget.sessionId,
      userId: currentUser.userId,
      track: trackData,
    );
    _loadSession(silent: true);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Track added to queue')),
      );
    }
  }

  Future<void> _voteToSkip() async {
    final currentUser = FirebaseBypassAuthService.currentUser;
    if (currentUser == null) return;

    await GroupSessionService.voteToSkip(
      sessionId: widget.sessionId,
      userId: currentUser.userId,
    );
    _loadSession(silent: true);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vote registered')),
      );
    }
  }

  Future<void> _leaveSession() async {
    final currentUser = FirebaseBypassAuthService.currentUser;
    if (currentUser == null) return;

    await GroupSessionService.leaveSession(
      sessionId: widget.sessionId,
      userId: currentUser.userId,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_session!['name'] ?? 'Group Session'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadSession(),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Leave Session', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'leave') _leaveSession();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.music_note), text: 'Now Playing'),
            Tab(icon: Icon(Icons.queue_music), text: 'Queue'),
            Tab(icon: Icon(Icons.people), text: 'Participants'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNowPlayingTab(),
          _buildQueueTab(),
          _buildParticipantsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTrackToQueue,
        icon: const Icon(Icons.add),
        label: const Text('Add Track'),
      ),
    );
  }

  Widget _buildNowPlayingTab() {
    final currentTrack = _session!['currentTrack'] as Map<String, dynamic>?;
    final participants = _session!['participants'] as List? ?? [];
    final skipVotes = _session!['skipVotes'] as List? ?? [];
    final requiredVotes = (participants.length * 0.5).ceil();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Album art placeholder
          Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade400, Colors.deepPurple.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: currentTrack == null
                ? const Icon(Icons.music_note, size: 120, color: Colors.white)
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.album, size: 100, color: Colors.white),
                        const SizedBox(height: 16),
                        Text(
                          currentTrack['title'] ?? 'Unknown Track',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 30),
          
          // Track info
          if (currentTrack != null) ...[
            Text(
              currentTrack['title'] ?? 'Unknown Track',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              currentTrack['artist'] ?? 'Unknown Artist',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            
            // Playback controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isHost) ...[
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    iconSize: 40,
                    onPressed: () {},
                  ),
                  const SizedBox(width: 20),
                ],
                Container(
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.pause),
                    iconSize: 50,
                    color: Colors.white,
                    onPressed: _isHost ? () {} : null,
                  ),
                ),
                if (_isHost) ...[
                  const SizedBox(width: 20),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    iconSize: 40,
                    onPressed: () {},
                  ),
                ],
              ],
            ),
            const SizedBox(height: 30),
            
            // Vote to skip
            if (!_isHost) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.how_to_vote, color: Colors.orange[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Vote to Skip',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${skipVotes.length}/$requiredVotes votes needed',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _voteToSkip,
                            icon: const Icon(Icons.thumb_up, size: 18),
                            label: const Text('Vote'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: skipVotes.length / requiredVotes,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ] else ...[
            Icon(Icons.music_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No track playing',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Add tracks to the queue to start',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQueueTab() {
    final queue = _session!['queue'] as List? ?? [];

    if (queue.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.queue_music, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Queue is Empty',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Add tracks to get started',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: queue.length,
      onReorder: _isHost ? (oldIndex, newIndex) {} : (_, __) {},
      itemBuilder: (context, index) {
        final track = queue[index] as Map<String, dynamic>;
        final addedBy = track['addedBy'] ?? 'Unknown';
        
        return Card(
          key: ValueKey(track['id'] ?? index),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.purple,
                  ),
                ),
              ),
            ),
            title: Text(
              track['title'] ?? 'Unknown Track',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(track['artist'] ?? 'Unknown Artist'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Added by $addedBy',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            trailing: _isHost
                ? IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {},
                  )
                : const Icon(Icons.drag_handle),
          ),
        );
      },
    );
  }

  Widget _buildParticipantsTab() {
    final participants = _session!['participants'] as List? ?? [];
    final hostId = _session!['hostId'];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: participants.length,
      itemBuilder: (context, index) {
        final participant = participants[index] as Map<String, dynamic>;
        final userId = participant['id'] ?? '';
        final userName = participant['name'] ?? 'User ${index + 1}';
        final isHost = userId == hostId;
        final isOnline = participant['isOnline'] ?? false;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Stack(
              children: [
                CircleAvatar(
                  backgroundColor: isHost ? Colors.amber : Colors.blue,
                  child: Text(
                    userName[0].toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            title: Row(
              children: [
                Text(
                  userName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (isHost) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'HOST',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Row(
              children: [
                Icon(
                  isOnline ? Icons.circle : Icons.circle_outlined,
                  size: 12,
                  color: isOnline ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  isOnline ? 'Active' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: isOnline ? Colors.green : Colors.grey[600],
                  ),
                ),
              ],
            ),
            trailing: _isHost && !isHost
                ? IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    onPressed: () {},
                  )
                : null,
          ),
        );
      },
    );
  }
}
