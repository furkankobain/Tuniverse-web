import 'package:cloud_firestore/cloud_firestore.dart';

class MusicRating {
  final String id;
  final String userId;
  final String trackId;
  final String trackName;
  final String artists;
  final String albumName;
  final String? albumImage;
  final int rating; // 1-5 stars
  final String? review;
  final bool containsSpoiler;
  final int likeCount;
  final int commentCount;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  MusicRating({
    required this.id,
    required this.userId,
    required this.trackId,
    required this.trackName,
    required this.artists,
    required this.albumName,
    this.albumImage,
    required this.rating,
    this.review,
    this.containsSpoiler = false,
    this.likeCount = 0,
    this.commentCount = 0,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'trackId': trackId,
      'trackName': trackName,
      'artists': artists,
      'albumName': albumName,
      'albumImage': albumImage,
      'rating': rating,
      'review': review,
      'containsSpoiler': containsSpoiler,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create from Firestore document
  factory MusicRating.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MusicRating(
      id: doc.id,
      userId: data['userId'] ?? '',
      trackId: data['trackId'] ?? '',
      trackName: data['trackName'] ?? '',
      artists: data['artists'] ?? '',
      albumName: data['albumName'] ?? '',
      albumImage: data['albumImage'],
      rating: data['rating'] ?? 0,
      review: data['review'],
      containsSpoiler: data['containsSpoiler'] ?? false,
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Copy with method for updates
  MusicRating copyWith({
    String? id,
    String? userId,
    String? trackId,
    String? trackName,
    String? artists,
    String? albumName,
    String? albumImage,
    int? rating,
    String? review,
    bool? containsSpoiler,
    int? likeCount,
    int? commentCount,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MusicRating(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      trackId: trackId ?? this.trackId,
      trackName: trackName ?? this.trackName,
      artists: artists ?? this.artists,
      albumName: albumName ?? this.albumName,
      albumImage: albumImage ?? this.albumImage,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      containsSpoiler: containsSpoiler ?? this.containsSpoiler,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get rating as stars string
  String get ratingStars {
    return '★' * rating + '☆' * (5 - rating);
  }

  // Get rating as percentage
  double get ratingPercentage {
    return (rating / 5.0) * 100;
  }
}
