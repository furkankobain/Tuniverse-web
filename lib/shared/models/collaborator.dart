import 'package:cloud_firestore/cloud_firestore.dart';

/// Collaboration roles for playlist management
enum CollaboratorRole {
  owner,   // Full control - can delete, manage collaborators
  editor,  // Can add/remove/reorder tracks
  viewer,  // Read-only access
}

/// Extension for role conversion
extension CollaboratorRoleExtension on CollaboratorRole {
  String get value {
    switch (this) {
      case CollaboratorRole.owner:
        return 'owner';
      case CollaboratorRole.editor:
        return 'editor';
      case CollaboratorRole.viewer:
        return 'viewer';
    }
  }

  static CollaboratorRole fromString(String value) {
    switch (value) {
      case 'owner':
        return CollaboratorRole.owner;
      case 'editor':
        return CollaboratorRole.editor;
      case 'viewer':
        return CollaboratorRole.viewer;
      default:
        return CollaboratorRole.viewer;
    }
  }

  String get displayName {
    switch (this) {
      case CollaboratorRole.owner:
        return 'Sahip';
      case CollaboratorRole.editor:
        return 'Düzenleyici';
      case CollaboratorRole.viewer:
        return 'İzleyici';
    }
  }

  String get description {
    switch (this) {
      case CollaboratorRole.owner:
        return 'Tüm yetkiler - silebilir, kişi ekleyebilir';
      case CollaboratorRole.editor:
        return 'Şarkı ekleyebilir/çıkarabilir';
      case CollaboratorRole.viewer:
        return 'Sadece görüntüleyebilir';
    }
  }
}

/// Model for playlist collaborators
class Collaborator {
  final String userId;
  final String username;
  final String? displayName;
  final String? photoURL;
  final CollaboratorRole role;
  final DateTime addedAt;
  final String addedBy; // UserId of who added this collaborator

  Collaborator({
    required this.userId,
    required this.username,
    this.displayName,
    this.photoURL,
    required this.role,
    required this.addedAt,
    required this.addedBy,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'username': username,
      'displayName': displayName,
      'photoURL': photoURL,
      'role': role.value,
      'addedAt': Timestamp.fromDate(addedAt),
      'addedBy': addedBy,
    };
  }

  factory Collaborator.fromFirestore(Map<String, dynamic> data) {
    return Collaborator(
      userId: data['userId'] ?? '',
      username: data['username'] ?? '',
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      role: CollaboratorRoleExtension.fromString(data['role'] ?? 'viewer'),
      addedAt: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      addedBy: data['addedBy'] ?? '',
    );
  }

  Collaborator copyWith({
    String? userId,
    String? username,
    String? displayName,
    String? photoURL,
    CollaboratorRole? role,
    DateTime? addedAt,
    String? addedBy,
  }) {
    return Collaborator(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      role: role ?? this.role,
      addedAt: addedAt ?? this.addedAt,
      addedBy: addedBy ?? this.addedBy,
    );
  }
}
