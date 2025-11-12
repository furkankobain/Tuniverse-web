import 'package:flutter/material.dart';
import 'package:tuniverse/shared/services/music_exploration_service.dart';
import 'package:tuniverse/shared/services/firebase_bypass_auth_service.dart';

class DecadeExplorerPage extends StatefulWidget {
  const DecadeExplorerPage({super.key});

  @override
  State<DecadeExplorerPage> createState() => _DecadeExplorerPageState();
}

class _DecadeExplorerPageState extends State<DecadeExplorerPage> {
  String _selectedDecade = '2020s';
  List<Map<String, dynamic>> _tracks = [];
  bool _isLoading = false;

  final decades = ['1960s', '1970s', '1980s', '1990s', '2000s', '2010s', '2020s'];

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    setState(() => _isLoading = true);
    final currentUser = FirebaseBypassAuthService.currentUser;
    if (currentUser == null) return;

        final data = await MusicExplorationService.exploreByDecade(_selectedDecade);
        final tracks = data['tracks'] as List? ?? [];
        setState(() {
          _tracks = tracks.cast<Map<String, dynamic>>();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Decade Explorer')),
      body: Column(
        children: [
          _buildDecadeSelector(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _tracks.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _tracks.length,
                        itemBuilder: (context, index) {
                          return _TrackTile(track: _tracks[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecadeSelector() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: decades.length,
        itemBuilder: (context, index) {
          final decade = decades[index];
          final isSelected = decade == _selectedDecade;
          
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () {
                setState(() => _selectedDecade = decade);
                _loadTracks();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [const Color(0xFFFF5E5E), const Color(0xFFFF5E5E).withOpacity(0.7)],
                        )
                      : null,
                  color: isSelected ? null : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      decade,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 4),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_note, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No tracks found for $_selectedDecade',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different decade',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _TrackTile extends StatelessWidget {
  final Map<String, dynamic> track;

  const _TrackTile({required this.track});

  @override
  Widget build(BuildContext context) {
    final name = track['name'] ?? 'Unknown Track';
    final artist = track['artist'] ?? 'Unknown Artist';
    final year = track['year'] ?? '';

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
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('$artist${year.isNotEmpty ? ' • $year' : ''}'),
        trailing: IconButton(
          icon: const Icon(Icons.play_arrow),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Playing $name...')),
            );
          },
        ),
      ),
    );
  }
}
