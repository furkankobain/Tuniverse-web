import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityType {
  rating,
  review,
  listCreated,
  listUpdated,
  diaryEntry,
  follow,
  like,
  comment,
}

class ActivityItem {
  final String id;
  final String userId;
  final String username;
  final String? userAvatar;
  final ActivityType type;
  final String? trackId;
  final String? trackName;
  final String? artists;
  final String? albumImage;
  final int? rating;
  final String? reviewText;
  final String? listId;
  final String? listTitle;
  final String? targetUserId;
  final String? targetUsername;
  final DateTime createdAt;
  final int likeCount;
  final int commentCount;

  ActivityItem({
    required this.id,
    required this.userId,
    required this.username,
    this.userAvatar,
    required this.type,
    this.trackId,
    this.trackName,
    this.artists,
    this.albumImage,
    this.rating,
    this.reviewText,
    this.listId,
    this.listTitle,
    this.targetUserId,
    this.targetUsername,
    required this.createdAt,
    this.likeCount = 0,
    this.commentCount = 0,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'username': username,
      'userAvatar': userAvatar,
      'type': type.name,
      'trackId': trackId,
      'trackName': trackName,
      'artists': artists,
      'albumImage': albumImage,
      'rating': rating,
      'reviewText': reviewText,
      'listId': listId,
      'listTitle': listTitle,
      'targetUserId': targetUserId,
      'targetUsername': targetUsername,
      'createdAt': Timestamp.fromDate(createdAt),
      'likeCount': likeCount,
      'commentCount': commentCount,
    };
  }

  factory ActivityItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ActivityItem(
      id: doc.id,
      userId: data['userId'] ?? '',
      username: data['username'] ?? '',
      userAvatar: data['userAvatar'],
      type: ActivityType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ActivityType.rating,
      ),
      trackId: data['trackId'],
      trackName: data['trackName'],
      artists: data['artists'],
      albumImage: data['albumImage'],
      rating: data['rating'],
      reviewText: data['reviewText'],
      listId: data['listId'],
      listTitle: data['listTitle'],
      targetUserId: data['targetUserId'],
      targetUsername: data['targetUsername'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
    );
  }

  String getActivityText() {
    switch (type) {
      case ActivityType.rating:
        return 'rated $trackName';
      case ActivityType.review:
        return 'reviewed $trackName';
      case ActivityType.listCreated:
        return 'created a list: $listTitle';
      case ActivityType.listUpdated:
        return 'updated a list: $listTitle';
      case ActivityType.diaryEntry:
        return 'listened to $trackName';
      case ActivityType.follow:
        return 'followed $targetUsername';
      case ActivityType.like:
        return 'liked $trackName';
      case ActivityType.comment:
        return 'commented on $trackName';
    }
  }
}
