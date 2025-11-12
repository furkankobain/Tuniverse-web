import 'package:cloud_firestore/cloud_firestore.dart';

class UserFollow {
  final String id;
  final String followerId; // Takip eden
  final String followingId; // Takip edilen
  final DateTime createdAt;

  UserFollow({
    required this.id,
    required this.followerId,
    required this.followingId,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'followerId': followerId,
      'followingId': followingId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory UserFollow.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserFollow(
      id: doc.id,
      followerId: data['followerId'] ?? '',
      followingId: data['followingId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class UserProfile {
  final String id;
  final String username;
  final String? displayName;
  final String? bio;
  final String? avatar;
  final String? coverImage;
  final int followerCount;
  final int followingCount;
  final int ratingCount;
  final int listCount;
  final int diaryCount;
  final List<String> favoriteGenres;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.username,
    this.displayName,
    this.bio,
    this.avatar,
    this.coverImage,
    this.followerCount = 0,
    this.followingCount = 0,
    this.ratingCount = 0,
    this.listCount = 0,
    this.diaryCount = 0,
    this.favoriteGenres = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'displayName': displayName,
      'bio': bio,
      'avatar': avatar,
      'coverImage': coverImage,
      'followerCount': followerCount,
      'followingCount': followingCount,
      'ratingCount': ratingCount,
      'listCount': listCount,
      'diaryCount': diaryCount,
      'favoriteGenres': favoriteGenres,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      id: doc.id,
      username: data['username'] ?? '',
      displayName: data['displayName'],
      bio: data['bio'],
      avatar: data['avatar'],
      coverImage: data['coverImage'],
      followerCount: data['followerCount'] ?? 0,
      followingCount: data['followingCount'] ?? 0,
      ratingCount: data['ratingCount'] ?? 0,
      listCount: data['listCount'] ?? 0,
      diaryCount: data['diaryCount'] ?? 0,
      favoriteGenres: List<String>.from(data['favoriteGenres'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  UserProfile copyWith({
    String? id,
    String? username,
    String? displayName,
    String? bio,
    String? avatar,
    String? coverImage,
    int? followerCount,
    int? followingCount,
    int? ratingCount,
    int? listCount,
    int? diaryCount,
    List<String>? favoriteGenres,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatar: avatar ?? this.avatar,
      coverImage: coverImage ?? this.coverImage,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      ratingCount: ratingCount ?? this.ratingCount,
      listCount: listCount ?? this.listCount,
      diaryCount: diaryCount ?? this.diaryCount,
      favoriteGenres: favoriteGenres ?? this.favoriteGenres,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
