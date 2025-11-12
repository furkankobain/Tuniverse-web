import 'package:cloud_firestore/cloud_firestore.dart';
import 'collaborator.dart';

enum PlaylistSource { local, spotify, synced }

class MusicList {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final List<String> trackIds;
  final bool isPublic;
  final Map<String, Collaborator> collaborators; // userId -> Collaborator
  final int likeCount;
  final int commentCount;
  final String? coverImage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final String source; // 'local', 'spotify', 'synced'
  final String? spotifyId; // Spotify playlist ID if synced

  MusicList({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.trackIds,
    this.isPublic = true,
    this.collaborators = const {},
    this.likeCount = 0,
    this.commentCount = 0,
    this.coverImage,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.source = 'local',
    this.spotifyId,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'trackIds': trackIds,
      'isPublic': isPublic,
      'collaborators': collaborators.map((key, value) => MapEntry(key, value.toFirestore())),
      'likeCount': likeCount,
      'commentCount': commentCount,
      'coverImage': coverImage,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'tags': tags,
      'source': source,
      'spotifyId': spotifyId,
    };
  }

  factory MusicList.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MusicList(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      trackIds: List<String>.from(data['trackIds'] ?? []),
      isPublic: data['isPublic'] ?? true,
      collaborators: _parseCollaborators(data['collaborators']),
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      coverImage: data['coverImage'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tags: List<String>.from(data['tags'] ?? []),
      source: data['source'] ?? 'local',
      spotifyId: data['spotifyId'],
    );
  }

  MusicList copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    List<String>? trackIds,
    bool? isPublic,
    Map<String, Collaborator>? collaborators,
    int? likeCount,
    int? commentCount,
    String? coverImage,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    String? source,
    String? spotifyId,
  }) {
    return MusicList(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      trackIds: trackIds ?? this.trackIds,
      isPublic: isPublic ?? this.isPublic,
      collaborators: collaborators ?? this.collaborators,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      coverImage: coverImage ?? this.coverImage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      source: source ?? this.source,
      spotifyId: spotifyId ?? this.spotifyId,
    );
  }

  /// Helper method to parse collaborators from Firestore
  static Map<String, Collaborator> _parseCollaborators(dynamic data) {
    if (data == null) return {};
    
    // Handle legacy format (List<String>)
    if (data is List) {
      return {}; // Return empty map for old data
    }
    
    // Handle new format (Map<String, dynamic>)
    if (data is Map) {
      return Map.fromEntries(
        data.entries.map((entry) {
          try {
            return MapEntry(
              entry.key.toString(),
              Collaborator.fromFirestore(entry.value as Map<String, dynamic>),
            );
          } catch (e) {
            return null;
          }
        }).where((entry) => entry != null).cast<MapEntry<String, Collaborator>>(),
      );
    }
    
    return {};
  }

  /// Check if user has edit permission
  bool canEdit(String userId) {
    if (this.userId == userId) return true; // Owner always can edit
    
    final collaborator = collaborators[userId];
    if (collaborator == null) return false;
    
    return collaborator.role == CollaboratorRole.owner ||
           collaborator.role == CollaboratorRole.editor;
  }

  /// Check if user has manage permission (add/remove collaborators)
  bool canManage(String userId) {
    if (this.userId == userId) return true; // Owner always can manage
    
    final collaborator = collaborators[userId];
    if (collaborator == null) return false;
    
    return collaborator.role == CollaboratorRole.owner;
  }

  /// Check if user can view
  bool canView(String userId) {
    if (isPublic) return true; // Public playlists can be viewed by anyone
    if (this.userId == userId) return true; // Owner can always view
    
    return collaborators.containsKey(userId); // Collaborators can view
  }
}
