import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewReply {
  final String id;
  final String reviewId;
  final String userId;
  final String username;
  final String? userAvatar;
  final String replyText;
  final int likeCount;
  final List<String> likedBy; // User IDs who liked
  final String? replyToUserId; // If replying to another reply
  final String? replyToUsername;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isEdited;

  ReviewReply({
    required this.id,
    required this.reviewId,
    required this.userId,
    required this.username,
    this.userAvatar,
    required this.replyText,
    this.likeCount = 0,
    this.likedBy = const [],
    this.replyToUserId,
    this.replyToUsername,
    required this.createdAt,
    required this.updatedAt,
    this.isEdited = false,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'reviewId': reviewId,
      'userId': userId,
      'username': username,
      'userAvatar': userAvatar,
      'replyText': replyText,
      'likeCount': likeCount,
      'likedBy': likedBy,
      'replyToUserId': replyToUserId,
      'replyToUsername': replyToUsername,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isEdited': isEdited,
    };
  }

  factory ReviewReply.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewReply(
      id: doc.id,
      reviewId: data['reviewId'] ?? '',
      userId: data['userId'] ?? '',
      username: data['username'] ?? '',
      userAvatar: data['userAvatar'],
      replyText: data['replyText'] ?? '',
      likeCount: data['likeCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      replyToUserId: data['replyToUserId'],
      replyToUsername: data['replyToUsername'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isEdited: data['isEdited'] ?? false,
    );
  }

  ReviewReply copyWith({
    String? id,
    String? reviewId,
    String? userId,
    String? username,
    String? userAvatar,
    String? replyText,
    int? likeCount,
    List<String>? likedBy,
    String? replyToUserId,
    String? replyToUsername,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEdited,
  }) {
    return ReviewReply(
      id: id ?? this.id,
      reviewId: reviewId ?? this.reviewId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userAvatar: userAvatar ?? this.userAvatar,
      replyText: replyText ?? this.replyText,
      likeCount: likeCount ?? this.likeCount,
      likedBy: likedBy ?? this.likedBy,
      replyToUserId: replyToUserId ?? this.replyToUserId,
      replyToUsername: replyToUsername ?? this.replyToUsername,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEdited: isEdited ?? this.isEdited,
    );
  }
}
