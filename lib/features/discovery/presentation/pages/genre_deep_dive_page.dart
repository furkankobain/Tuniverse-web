import 'package:flutter/material.dart';
import 'package:tuniverse/shared/services/music_exploration_service.dart';
import 'package:tuniverse/shared/services/firebase_bypass_auth_service.dart';

class GenreDeepDivePage extends StatefulWidget {
  const GenreDeepDivePage({super.key});

  @override
  State<GenreDeepDivePage> createState() => _GenreDeepDivePageState();
}

class _GenreDeepDivePageState extends State<GenreDeepDivePage> {
  String _selectedGenre = 'Rock';
  List<Map<String, dynamic>> _tracks = [];
  bool _isLoading = false;

  final genres = ['Rock', 'Pop', 'Hip Hop', 'Electronic', 'Jazz', 'Classical', 'R&B', 'Country', 'Metal', 'Indie'];

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    setState(() => _isLoading = true);
    final currentUser = FirebaseBypassAuthService.currentUser;
    if (currentUser == null) return;

        final data = await MusicExplorationService.exploreByGenre(_selectedGenre);
        final tracks = data['topTracks'] as List? ?? [];
        setState(() {
          _tracks = tracks.cast<Map<String, dynamic>>();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Genre Deep Dive')),
      body: Column(
        children: [
          _buildGenreGrid(),
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

  Widget _buildGenreGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2,
        ),
        itemCount: genres.length,
        itemBuilder: (context, index) {
          final genre = genres[index];
          final isSelected = genre == _selectedGenre;

          return InkWell(
            onTap: () {
              setState(() => _selectedGenre = genre);
              _loadTracks();
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [const Color(0xFFFF5E5E), const Color(0xFFFF5E5E).withOpacity(0.7)],
                      )
                    : null,
                color: isSelected ? null : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFFFF5E5E) : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  genre,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
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
            'No $_selectedGenre tracks found',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different genre',
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
    final genre = track['genre'] ?? '';

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
        subtitle: Text(artist),
        trailing: genre.isNotEmpty
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  genre,
                  style: const TextStyle(fontSize: 11, color: Colors.purple, fontWeight: FontWeight.w600),
                ),
              )
            : const Icon(Icons.chevron_right),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Playing $name...')),
          );
        },
      ),
    );
  }
}
