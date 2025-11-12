import 'package:flutter/material.dart';
import 'package:tuniverse/shared/services/analytics_service.dart';
import 'package:tuniverse/shared/services/firebase_bypass_auth_service.dart';

class FriendsComparisonPage extends StatefulWidget {
  const FriendsComparisonPage({super.key});

  @override
  State<FriendsComparisonPage> createState() => _FriendsComparisonPageState();
}

class _FriendsComparisonPageState extends State<FriendsComparisonPage> {
  List<Map<String, dynamic>> _comparisons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComparisons();
  }

  Future<void> _loadComparisons() async {
    setState(() => _isLoading = true);
    final currentUser = FirebaseBypassAuthService.currentUser;
    if (currentUser == null) return;

    final comparisons = await AnalyticsService.compareTasteWithFriends(currentUser.userId);
    setState(() {
      _comparisons = comparisons;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Friends Comparison')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _comparisons.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadComparisons,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _comparisons.length,
                    itemBuilder: (context, index) {
                      return _ComparisonCard(comparison: _comparisons[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No Friends to Compare',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Follow friends to see your music taste comparison',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  final Map<String, dynamic> comparison;

  const _ComparisonCard({required this.comparison});

  @override
  Widget build(BuildContext context) {
    final friendName = comparison['friendName'] ?? 'Friend';
    final similarity = comparison['similarity'] ?? 0.0;
    final commonArtists = comparison['commonArtists'] as List? ?? [];
    final commonGenres = comparison['commonGenres'] as List? ?? [];

    final similarityPercent = (similarity * 100).toInt();
    final color = _getSimilarityColor(similarityPercent);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: color.withOpacity(0.2),
                  child: Text(
                    friendName[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friendName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Music taste match',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '$similarityPercent%',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      _getSimilarityLabel(similarityPercent),
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: similarity,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 20),
            if (commonArtists.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.people, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Common Artists',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: commonArtists.take(5).map((artist) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      artist['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            if (commonGenres.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.music_note, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Common Genres',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: commonGenres.take(5).map((genre) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      genre,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.purple,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getSimilarityColor(int percent) {
    if (percent >= 80) return Colors.green;
    if (percent >= 60) return Colors.lightGreen;
    if (percent >= 40) return Colors.orange;
    return Colors.red;
  }

  String _getSimilarityLabel(int percent) {
    if (percent >= 80) return 'Soul Twin';
    if (percent >= 60) return 'Very Similar';
    if (percent >= 40) return 'Similar';
    return 'Different';
  }
}
