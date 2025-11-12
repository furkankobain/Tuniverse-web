import 'package:flutter/material.dart';
import 'package:tuniverse/shared/services/group_session_service.dart';
import 'package:tuniverse/shared/services/firebase_bypass_auth_service.dart';
import 'package:go_router/go_router.dart';

class MusicRoomsPage extends StatefulWidget {
  const MusicRoomsPage({super.key});

  @override
  State<MusicRoomsPage> createState() => _MusicRoomsPageState();
}

class _MusicRoomsPageState extends State<MusicRoomsPage> {
  List<Map<String, dynamic>> _rooms = [];
  List<Map<String, dynamic>> _allRooms = [];
  bool _isLoading = true;
  String _filterType = 'all'; // all, public, friends

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() => _isLoading = true);
    final currentUser = FirebaseBypassAuthService.currentUser;
    if (currentUser == null) return;

    final rooms = await GroupSessionService.getActiveSessions();
    setState(() {
      _allRooms = rooms;
      _rooms = _filterRooms(_allRooms);
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _filterRooms(List<Map<String, dynamic>> rooms) {
    if (_filterType == 'public') {
      return rooms.where((r) => r['isPublic'] == true).toList();
    } else if (_filterType == 'friends') {
      return rooms.where((r) => r['isFriendsOnly'] == true).toList();
    }
    return rooms;
  }

  void _showCreateRoomDialog() {
    final nameController = TextEditingController();
    bool isPublic = true;
    String maxParticipants = '10';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Music Room'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Room Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.meeting_room),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Public Room'),
                  subtitle: const Text('Anyone can join'),
                  value: isPublic,
                  onChanged: (value) => setDialogState(() => isPublic = value),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: maxParticipants,
                  decoration: const InputDecoration(
                    labelText: 'Max Participants',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.people),
                  ),
                  items: ['5', '10', '20', '50', '100']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) => setDialogState(() => maxParticipants = value!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a room name')),
                  );
                  return;
                }

                final currentUser = FirebaseBypassAuthService.currentUser;
                if (currentUser == null) return;

                final sessionId = await GroupSessionService.createSession(
                  hostId: currentUser.userId,
                  hostName: currentUser.displayName,
                  sessionName: nameController.text,
                  maxParticipants: int.parse(maxParticipants),
                  isPublic: isPublic,
                );

                if (mounted) {
                  Navigator.pop(context);
                  context.pushNamed(
                    'group-session-detail',
                    extra: sessionId,
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Rooms'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRooms,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _rooms.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadRooms,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _rooms.length,
                          itemBuilder: (context, index) {
                            return _RoomCard(
                              room: _rooms[index],
                              onJoin: () => _joinRoom(_rooms[index]),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateRoomDialog,
        icon: const Icon(Icons.add),
        label: const Text('Create Room'),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip('All Rooms', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('Public', 'public'),
          const SizedBox(width: 8),
          _buildFilterChip('Friends Only', 'friends'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String type) {
    final isSelected = _filterType == type;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterType = type;
          _rooms = _filterRooms(_allRooms);
        });
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_note_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No Active Rooms',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a room to listen with friends',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateRoomDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create First Room'),
          ),
        ],
      ),
    );
  }

  Future<void> _joinRoom(Map<String, dynamic> room) async {
    final currentUser = FirebaseBypassAuthService.currentUser;
    if (currentUser == null) return;

    final sessionId = room['sessionId'] ?? '';
    final success = await GroupSessionService.joinSession(
      sessionId: sessionId,
      userId: currentUser.userId,
      userName: currentUser.displayName,
    );

    if (success && mounted) {
      context.pushNamed(
        'group-session-detail',
        extra: sessionId,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to join room')),
      );
    }
  }
}

class _RoomCard extends StatelessWidget {
  final Map<String, dynamic> room;
  final VoidCallback onJoin;

  const _RoomCard({required this.room, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    final name = room['name'] ?? 'Music Room';
    final hostName = room['hostName'] ?? 'Unknown';
    final participants = room['participants'] as List? ?? [];
    final currentTrack = room['currentTrack'] as Map<String, dynamic>?;
    final isPublic = room['isPublic'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onJoin,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.purple, Colors.deepPurple],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.music_note, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isPublic ? Colors.green : Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isPublic ? 'PUBLIC' : 'PRIVATE',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.person, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              'Hosted by $hostName',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (currentTrack != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.play_circle_filled, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentTrack['title'] ?? 'Unknown Track',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              currentTrack['artist'] ?? 'Unknown Artist',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${participants.length} listening',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: onJoin,
                    icon: const Icon(Icons.login, size: 18),
                    label: const Text('Join'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
