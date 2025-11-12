import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  playlistCollaborator,  // Added to playlist as collaborator
  playlistLike,          // Someone liked your playlist
  playlistComment,       // Someone commented on your playlist
  follow,                // Someone followed you
  message,               // New message
}

extension NotificationTypeExtension on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.playlistCollaborator:
        return 'playlist_collaborator';
      case NotificationType.playlistLike:
        return 'playlist_like';
      case NotificationType.playlistComment:
        return 'playlist_comment';
      case NotificationType.follow:
        return 'follow';
      case NotificationType.message:
        return 'message';
    }
  }

  static NotificationType fromString(String value) {
    switch (value) {
      case 'playlist_collaborator':
        return NotificationType.playlistCollaborator;
      case 'playlist_like':
        return NotificationType.playlistLike;
      case 'playlist_comment':
        return NotificationType.playlistComment;
      case 'follow':
        return NotificationType.follow;
      case 'message':
        return NotificationType.message;
      default:
        return NotificationType.playlistCollaborator;
    }
  }

  String getTitle() {
    switch (this) {
      case NotificationType.playlistCollaborator:
        return 'Playlist İşbirlikçisi';
      case NotificationType.playlistLike:
        return 'Playlist Beğeni';
      case NotificationType.playlistComment:
        return 'Yeni Yorum';
      case NotificationType.follow:
        return 'Yeni Takipçi';
      case NotificationType.message:
        return 'Yeni Mesaj';
    }
  }

  String getIcon() {
    switch (this) {
      case NotificationType.playlistCollaborator:
        return '👥';
      case NotificationType.playlistLike:
        return '❤️';
      case NotificationType.playlistComment:
        return '💬';
      case NotificationType.follow:
        return '👤';
      case NotificationType.message:
        return '✉️';
    }
  }
}

class AppNotification {
  final String id;
  final String userId;           // Notification recipient
  final NotificationType type;
  final String title;
  final String body;
  final String? fromUserId;      // Who triggered the notification
  final String? fromUsername;
  final String? fromPhotoURL;
  final Map<String, dynamic>? data; // Additional data (playlistId, messageId, etc.)
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.fromUserId,
    this.fromUsername,
    this.fromPhotoURL,
    this.data,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.value,
      'title': title,
      'body': body,
      'fromUserId': fromUserId,
      'fromUsername': fromUsername,
      'fromPhotoURL': fromPhotoURL,
      'data': data,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: NotificationTypeExtension.fromString(data['type'] ?? ''),
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      fromUserId: data['fromUserId'],
      fromUsername: data['fromUsername'],
      fromPhotoURL: data['fromPhotoURL'],
      data: data['data'],
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? body,
    String? fromUserId,
    String? fromUsername,
    String? fromPhotoURL,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUsername: fromUsername ?? this.fromUsername,
      fromPhotoURL: fromPhotoURL ?? this.fromPhotoURL,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
