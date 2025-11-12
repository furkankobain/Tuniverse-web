import 'package:cloud_firestore/cloud_firestore.dart';

class MusicReview {
  final String id;
  final String userId;
  final String username;
  final String? userAvatar;
  final String trackId;
  final String trackName;
  final String artists;
  final String? albumImage;
  final int? rating; // 1-5 stars, opsiyonel
  final String reviewText;
  final bool containsSpoiler;
  final List<String> tags;
  final int likeCount;
  final int dislikeCount;
  final List<String> likedBy; // User IDs who liked
  final List<String> dislikedBy; // User IDs who disliked
  final int replyCount; // Changed from commentCount
  final bool isPinned;
  final bool isEdited;
  final DateTime createdAt;
  final DateTime updatedAt;

  MusicReview({
    required this.id,
    required this.userId,
    required this.username,
    this.userAvatar,
    required this.trackId,
    required this.trackName,
    required this.artists,
    this.albumImage,
    this.rating,
    required this.reviewText,
    this.containsSpoiler = false,
    this.tags = const [],
    this.likeCount = 0,
    this.dislikeCount = 0,
    this.likedBy = const [],
    this.dislikedBy = const [],
    this.replyCount = 0,
    this.isPinned = false,
    this.isEdited = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'username': username,
      'userAvatar': userAvatar,
      'trackId': trackId,
      'trackName': trackName,
      'artists': artists,
      'albumImage': albumImage,
      'rating': rating,
      'reviewText': reviewText,
      'containsSpoiler': containsSpoiler,
      'tags': tags,
      'likeCount': likeCount,
      'dislikeCount': dislikeCount,
      'likedBy': likedBy,
      'dislikedBy': dislikedBy,
      'replyCount': replyCount,
      'isPinned': isPinned,
      'isEdited': isEdited,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory MusicReview.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MusicReview(
      id: doc.id,
      userId: data['userId'] ?? '',
      username: data['username'] ?? '',
      userAvatar: data['userAvatar'],
      trackId: data['trackId'] ?? '',
      trackName: data['trackName'] ?? '',
      artists: data['artists'] ?? '',
      albumImage: data['albumImage'],
      rating: data['rating'],
      reviewText: data['reviewText'] ?? data['noteText'] ?? '',
      containsSpoiler: data['containsSpoiler'] ?? false,
      tags: List<String>.from(data['tags'] ?? []),
      likeCount: data['likeCount'] ?? 0,
      dislikeCount: data['dislikeCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      dislikedBy: List<String>.from(data['dislikedBy'] ?? []),
      replyCount: data['replyCount'] ?? data['commentCount'] ?? 0, // Backward compatibility
      isPinned: data['isPinned'] ?? false,
      isEdited: data['isEdited'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  MusicReview copyWith({
    String? id,
    String? userId,
    String? username,
    String? userAvatar,
    String? trackId,
    String? trackName,
    String? artists,
    String? albumImage,
    int? rating,
    String? reviewText,
    bool? containsSpoiler,
    List<String>? tags,
    int? likeCount,
    int? dislikeCount,
    List<String>? likedBy,
    List<String>? dislikedBy,
    int? replyCount,
    bool? isPinned,
    bool? isEdited,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MusicReview(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userAvatar: userAvatar ?? this.userAvatar,
      trackId: trackId ?? this.trackId,
      trackName: trackName ?? this.trackName,
      artists: artists ?? this.artists,
      albumImage: albumImage ?? this.albumImage,
      rating: rating ?? this.rating,
      reviewText: reviewText ?? this.reviewText,
      containsSpoiler: containsSpoiler ?? this.containsSpoiler,
      tags: tags ?? this.tags,
      likeCount: likeCount ?? this.likeCount,
      dislikeCount: dislikeCount ?? this.dislikeCount,
      likedBy: likedBy ?? this.likedBy,
      dislikedBy: dislikedBy ?? this.dislikedBy,
      replyCount: replyCount ?? this.replyCount,
      isPinned: isPinned ?? this.isPinned,
      isEdited: isEdited ?? this.isEdited,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
