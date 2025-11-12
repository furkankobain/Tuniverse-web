class PlayHistory {
  final String id;
  final String trackId;
  final String trackName;
  final String artistName;
  final String albumName;
  final String? albumImageUrl;
  final DateTime playedAt;
  final int durationMs;
  final int? popularity;

  PlayHistory({
    required this.id,
    required this.trackId,
    required this.trackName,
    required this.artistName,
    required this.albumName,
    this.albumImageUrl,
    required this.playedAt,
    required this.durationMs,
    this.popularity,
  });

  factory PlayHistory.fromSpotify(Map<String, dynamic> json) {
    return PlayHistory(
      id: json['id'] ?? '',
      trackId: json['id'] ?? '',
      trackName: json['name'] ?? 'Unknown Track',
      artistName: json['artists'] ?? 'Unknown Artist',
      albumName: json['album'] ?? 'Unknown Album',
      albumImageUrl: json['album_image'],
      playedAt: json['played_at'] != null 
          ? DateTime.parse(json['played_at']) 
          : DateTime.now(),
      durationMs: json['duration_ms'] ?? 0,
      popularity: json['popularity'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trackId': trackId,
      'trackName': trackName,
      'artistName': artistName,
      'albumName': albumName,
      'albumImageUrl': albumImageUrl,
      'playedAt': playedAt.toIso8601String(),
      'durationMs': durationMs,
      'popularity': popularity,
    };
  }

  String get formattedDuration {
    final minutes = durationMs ~/ 60000;
    final seconds = (durationMs % 60000) ~/ 1000;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(playedAt);

    if (difference.inMinutes < 1) {
      return 'Az önce';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${playedAt.day}/${playedAt.month}/${playedAt.year}';
    }
  }
}
