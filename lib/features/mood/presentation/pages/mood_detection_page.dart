import 'package:flutter/material.dart';
import '../../../../shared/services/ai_mood_detection_service.dart';
import '../../../../shared/services/firebase_bypass_auth_service.dart';
import '../../../../core/animations/app_animations.dart';

/// Mood Detection Page
/// Analyzes user mood and generates personalized playlists
class MoodDetectionPage extends StatefulWidget {
  const MoodDetectionPage({super.key});

  @override
  State<MoodDetectionPage> createState() => _MoodDetectionPageState();
}

class _MoodDetectionPageState extends State<MoodDetectionPage> {
  MoodAnalysis? _currentMood;
  List<Map<String, dynamic>> _generatedPlaylist = [];
  bool _isAnalyzing = false;
  bool _isGeneratingPlaylist = false;

  @override
  void initState() {
    super.initState();
    _analyzeMood();
  }

  Future<void> _analyzeMood() async {
    setState(() => _isAnalyzing = true);

    final userId = FirebaseBypassAuthService.currentUserId;
    if (userId == null) return;

    try {
      final mood = await AIMoodDetectionService.detectMood(userId);
      setState(() {
        _currentMood = mood;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _generatePlaylist() async {
    if (_currentMood == null) return;

    setState(() => _isGeneratingPlaylist = true);

    final userId = FirebaseBypassAuthService.currentUserId;
    if (userId == null) return;

    try {
      final playlist = await AIMoodDetectionService.generateMoodPlaylist(
        mood: _currentMood!.mood,
        userId: userId,
      );

      setState(() {
        _generatedPlaylist = playlist;
        _isGeneratingPlaylist = false;
      });
    } catch (e) {
      setState(() => _isGeneratingPlaylist = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ruh Hali Analizi'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _analyzeMood,
            tooltip: 'Yeniden Analiz Et',
          ),
        ],
      ),
      body: _isAnalyzing
          ? const Center(child: CircularProgressIndicator())
          : _currentMood == null
              ? _buildErrorState()
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildMoodCard(),
                      _buildAudioFeaturesCard(),
                      _buildMoodSelectionGrid(),
                      if (_generatedPlaylist.isNotEmpty)
                        _buildGeneratedPlaylist(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sentiment_neutral, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Ruh halin analiz edilemedi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Daha fazla şarkı dinleyerek başla!',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodCard() {
    final moodColor = Color(AIMoodDetectionService.getMoodColor(_currentMood!.mood));
    final moodEmoji = AIMoodDetectionService.getMoodEmoji(_currentMood!.mood);
    final moodName = AIMoodDetectionService.getMoodName(_currentMood!.mood);
    final moodDesc = AIMoodDetectionService.getMoodDescription(_currentMood!.mood);

    return AnimatedListItem(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              moodColor,
              moodColor.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: moodColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Emoji
            Text(
              moodEmoji,
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),

            // Mood Name
            Text(
              moodName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              moodDesc,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Confidence
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.psychology, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Güven: ${(_currentMood!.confidence * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Generate Playlist Button
            ElevatedButton.icon(
              onPressed: _isGeneratingPlaylist ? null : _generatePlaylist,
              icon: _isGeneratingPlaylist
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.playlist_add),
              label: Text(_isGeneratingPlaylist
                  ? 'Oluşturuluyor...'
                  : 'Bu Ruh Haline Göre Playlist Oluştur'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: moodColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioFeaturesCard() {
    return AnimatedListItem(
      index: 1,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ses Özellikleri',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFeatureBar(
              'Enerji',
              _currentMood!.energy,
              Icons.bolt,
              const Color(0xFFFF5E5E),
            ),
            _buildFeatureBar(
              'Pozitiflik',
              _currentMood!.valence,
              Icons.sentiment_satisfied,
              const Color(0xFF4CAF50),
            ),
            _buildFeatureBar(
              'Dans Edilebilirlik',
              _currentMood!.danceability,
              Icons.directions_run,
              const Color(0xFFFF9800),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    'Tempo',
                    '${_currentMood!.tempo.toInt()} BPM',
                    Icons.speed,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoChip(
                    'Analiz',
                    'Son 24 saat',
                    Icons.access_time,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureBar(
    String label,
    double value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${(value * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF5E5E).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFFFF5E5E)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSelectionGrid() {
    return AnimatedListItem(
      index: 2,
      child: Container(
        margin: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Diğer Ruh Halleri',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: MoodType.values.map((mood) {
                final isSelected = mood == _currentMood!.mood;
                final color = Color(AIMoodDetectionService.getMoodColor(mood));
                final emoji = AIMoodDetectionService.getMoodEmoji(mood);
                final name = AIMoodDetectionService.getMoodName(mood);

                return InkWell(
                  onTap: () {
                    setState(() {
                      _currentMood = MoodAnalysis(
                        mood: mood,
                        confidence: 0.8,
                        energy: _currentMood!.energy,
                        valence: _currentMood!.valence,
                        tempo: _currentMood!.tempo,
                        danceability: _currentMood!.danceability,
                        timestamp: DateTime.now(),
                      );
                      _generatedPlaylist.clear();
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? color : color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? color : color.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          emoji,
                          style: TextStyle(
                            fontSize: isSelected ? 36 : 32,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : color,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratedPlaylist() {
    return AnimatedListItem(
      index: 3,
      child: Container(
        margin: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Oluşturulan Playlist',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_generatedPlaylist.length} şarkı',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _generatedPlaylist.take(10).length,
              itemBuilder: (context, index) {
                final track = _generatedPlaylist[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFFF5E5E),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    track['name'] ?? 'Unknown',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    track['artist'] ?? 'Unknown Artist',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () {
                      // Play track
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
