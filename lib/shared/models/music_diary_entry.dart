import 'package:cloud_firestore/cloud_firestore.dart';

class MusicDiaryEntry {
  final String id;
  final String userId;
  final String trackId;
  final String trackName;
  final String artists;
  final String? albumImage;
  final DateTime listenedAt;
  final int? rating;
  final String? review;
  final bool isRelistened; // Tekrar dinleme
  final List<String> tags;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;

  MusicDiaryEntry({
    required this.id,
    required this.userId,
    required this.trackId,
    required this.trackName,
    required this.artists,
    this.albumImage,
    required this.listenedAt,
    this.rating,
    this.review,
    this.isRelistened = false,
    this.tags = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'trackId': trackId,
      'trackName': trackName,
      'artists': artists,
      'albumImage': albumImage,
      'listenedAt': Timestamp.fromDate(listenedAt),
      'rating': rating,
      'review': review,
      'isRelistened': isRelistened,
      'tags': tags,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory MusicDiaryEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MusicDiaryEntry(
      id: doc.id,
      userId: data['userId'] ?? '',
      trackId: data['trackId'] ?? '',
      trackName: data['trackName'] ?? '',
      artists: data['artists'] ?? '',
      albumImage: data['albumImage'],
      listenedAt: (data['listenedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rating: data['rating'],
      review: data['review'],
      isRelistened: data['isRelistened'] ?? false,
      tags: List<String>.from(data['tags'] ?? []),
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  MusicDiaryEntry copyWith({
    String? id,
    String? userId,
    String? trackId,
    String? trackName,
    String? artists,
    String? albumImage,
    DateTime? listenedAt,
    int? rating,
    String? review,
    bool? isRelistened,
    List<String>? tags,
    int? likeCount,
    int? commentCount,
    DateTime? createdAt,
  }) {
    return MusicDiaryEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      trackId: trackId ?? this.trackId,
      trackName: trackName ?? this.trackName,
      artists: artists ?? this.artists,
      albumImage: albumImage ?? this.albumImage,
      listenedAt: listenedAt ?? this.listenedAt,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      isRelistened: isRelistened ?? this.isRelistened,
      tags: tags ?? this.tags,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
