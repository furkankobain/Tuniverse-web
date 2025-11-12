import 'package:flutter/material.dart';
import 'package:tuniverse/shared/services/analytics_service.dart';
import 'package:tuniverse/shared/services/firebase_bypass_auth_service.dart';

class TasteProfilePage extends StatefulWidget {
  const TasteProfilePage({super.key});

  @override
  State<TasteProfilePage> createState() => _TasteProfilePageState();
}

class _TasteProfilePageState extends State<TasteProfilePage> {
  Map<String, dynamic> _profile = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final currentUser = FirebaseBypassAuthService.currentUser;
    if (currentUser == null) return;

    final profile = await AnalyticsService.getTasteProfile(currentUser.userId);
    setState(() {
      _profile = profile;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Taste Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildPersonalityCard(),
                  const SizedBox(height: 16),
                  _buildGenreDistribution(),
                  const SizedBox(height: 16),
                  _buildTopArtists(),
                ],
              ),
            ),
    );
  }

  Widget _buildPersonalityCard() {
    final personality = _profile['personality'] ?? 'Explorer';
    
    return Card(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple, Colors.deepPurple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Text(
              '🎭 Your Music Personality',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              personality,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenreDistribution() {
    final genres = _profile['topGenres'] as List? ?? [];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Genre Distribution',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...genres.take(5).map((genre) {
              final name = genre['name'] ?? '';
              final count = genre['count'] ?? 0;
              final maxCount = genres.first['count'] ?? 1;
              final percentage = count / maxCount;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('$count', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage.toDouble(),
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF5E5E)),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopArtists() {
    final artists = _profile['topArtists'] as List? ?? [];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Artists',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...artists.take(5).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final artist = entry.value;
              final name = artist['name'] ?? 'Unknown';
              final count = artist['count'] ?? 0;
              
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFFF5E5E),
                  child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: Text('$count plays', style: TextStyle(color: Colors.grey[600])),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
