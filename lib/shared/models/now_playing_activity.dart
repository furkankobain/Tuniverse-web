class NowPlayingActivity {
  final String userId;
  final String username;
  final String? profileImageUrl;
  final String trackName;
  final String artistName;
  final String? albumImageUrl;
  final DateTime startedAt;
  final bool isPlaying;

  NowPlayingActivity({
    required this.userId,
    required this.username,
    this.profileImageUrl,
    required this.trackName,
    required this.artistName,
    this.albumImageUrl,
    required this.startedAt,
    this.isPlaying = true,
  });

  factory NowPlayingActivity.fromMap(Map<String, dynamic> map) {
    return NowPlayingActivity(
      userId: map['userId'] ?? '',
      username: map['username'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      trackName: map['trackName'] ?? '',
      artistName: map['artistName'] ?? '',
      albumImageUrl: map['albumImageUrl'],
      startedAt: DateTime.parse(map['startedAt'] ?? DateTime.now().toIso8601String()),
      isPlaying: map['isPlaying'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'profileImageUrl': profileImageUrl,
      'trackName': trackName,
      'artistName': artistName,
      'albumImageUrl': albumImageUrl,
      'startedAt': startedAt.toIso8601String(),
      'isPlaying': isPlaying,
    };
  }

  String get timeAgo {
    final diff = DateTime.now().difference(startedAt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
