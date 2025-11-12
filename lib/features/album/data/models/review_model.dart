class Review {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String albumId;
  final String albumName;
  final double rating;
  final String reviewText;
  final int likes;
  final int dislikes;
  final String? userReaction; // 'like', 'dislike', or null
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isEdited;

  Review({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.albumId,
    required this.albumName,
    required this.rating,
    required this.reviewText,
    this.likes = 0,
    this.dislikes = 0,
    this.userReaction,
    required this.createdAt,
    this.updatedAt,
    this.isEdited = false,
  });

  factory Review.fromMap(Map<String, dynamic> map, String id) {
    return Review(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Anonymous',
      userPhotoUrl: map['userPhotoUrl'],
      albumId: map['albumId'] ?? '',
      albumName: map['albumName'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      reviewText: map['reviewText'] ?? '',
      likes: map['likes'] ?? 0,
      dislikes: map['dislikes'] ?? 0,
      userReaction: map['userReaction'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
      isEdited: map['isEdited'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'albumId': albumId,
      'albumName': albumName,
      'rating': rating,
      'reviewText': reviewText,
      'likes': likes,
      'dislikes': dislikes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isEdited': isEdited,
    };
  }

  Review copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    String? albumId,
    String? albumName,
    double? rating,
    String? reviewText,
    int? likes,
    int? dislikes,
    String? userReaction,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEdited,
  }) {
    return Review(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      albumId: albumId ?? this.albumId,
      albumName: albumName ?? this.albumName,
      rating: rating ?? this.rating,
      reviewText: reviewText ?? this.reviewText,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
      userReaction: userReaction ?? this.userReaction,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEdited: isEdited ?? this.isEdited,
    );
  }
}
