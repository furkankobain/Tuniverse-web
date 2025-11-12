import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for user's Spotify listening activity
class SpotifyActivity {
  final String userId;
  final String trackId;
  final String trackName;
  final String artistName;
  final String albumName;
  final String? albumImageUrl;
  final DateTime timestamp;
  final bool isPlaying;

  SpotifyActivity({
    required this.userId,
    required this.trackId,
    required this.trackName,
    required this.artistName,
    required this.albumName,
    this.albumImageUrl,
    required this.timestamp,
    this.isPlaying = false,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'trackId': trackId,
      'trackName': trackName,
      'artistName': artistName,
      'albumName': albumName,
      'albumImageUrl': albumImageUrl,
      'timestamp': Timestamp.fromDate(timestamp),
      'isPlaying': isPlaying,
    };
  }

  factory SpotifyActivity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return SpotifyActivity(
      userId: data['userId'] ?? '',
      trackId: data['trackId'] ?? '',
      trackName: data['trackName'] ?? 'Unknown Track',
      artistName: data['artistName'] ?? 'Unknown Artist',
      albumName: data['albumName'] ?? '',
      albumImageUrl: data['albumImageUrl'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPlaying: data['isPlaying'] ?? false,
    );
  }

  /// Get a human-readable status text
  String get statusText {
    if (!isPlaying) return 'Not playing';
    
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inMinutes < 1) {
      return 'Listening now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    }
  }

  /// Check if this activity is currently active (< 1 minute old)
  bool get isCurrentlyListening {
    if (!isPlaying) return false;
    
    final diff = DateTime.now().difference(timestamp);
    return diff.inMinutes < 1;
  }

  SpotifyActivity copyWith({
    String? userId,
    String? trackId,
    String? trackName,
    String? artistName,
    String? albumName,
    String? albumImageUrl,
    DateTime? timestamp,
    bool? isPlaying,
  }) {
    return SpotifyActivity(
      userId: userId ?? this.userId,
      trackId: trackId ?? this.trackId,
      trackName: trackName ?? this.trackName,
      artistName: artistName ?? this.artistName,
      albumName: albumName ?? this.albumName,
      albumImageUrl: albumImageUrl ?? this.albumImageUrl,
      timestamp: timestamp ?? this.timestamp,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }
}
