import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/music_list.dart';
import '../models/collaborator.dart';
import 'firebase_service.dart';
import 'in_app_notification_service.dart';

class PlaylistService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'playlists';

  /// Create a new playlist
  static Future<String?> createPlaylist({
    required String title,
    String? description,
    String? coverImage,
    bool isPublic = true,
    List<String>? tags,
  }) async {
    try {
      final userId = FirebaseService.auth.currentUser?.uid;
      if (userId == null) return null;

      final now = DateTime.now();
      final playlist = MusicList(
        id: '', // Will be set by Firestore
        userId: userId,
        title: title,
        description: description,
        trackIds: [],
        isPublic: isPublic,
        coverImage: coverImage,
        createdAt: now,
        updatedAt: now,
        tags: tags ?? [],
      );

      final docRef = await _firestore
          .collection(_collection)
          .add(playlist.toFirestore());

      return docRef.id;
    } catch (e) {
      print('Error creating playlist: $e');
      return null;
    }
  }

  /// Get a playlist by ID
  static Future<MusicList?> getPlaylist(String playlistId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(playlistId).get();
      
      if (!doc.exists) return null;
      
      return MusicList.fromFirestore(doc);
    } catch (e) {
      print('Error getting playlist: $e');
      return null;
    }
  }

  /// Get a playlist by ID (alias for deep linking)
  static Future<MusicList?> getPlaylistById(String playlistId) => getPlaylist(playlistId);

  /// Get all playlists for current user
  static Stream<List<MusicList>> getUserPlaylists() {
    final userId = FirebaseService.auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MusicList.fromFirestore(doc))
            .toList());
  }

  /// Get public playlists for a specific user
  static Stream<List<MusicList>> getUserPublicPlaylists(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('isPublic', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MusicList.fromFirestore(doc))
            .toList());
  }

  /// Update playlist details
  static Future<bool> updatePlaylist({
    required String playlistId,
    String? title,
    String? description,
    String? coverImage,
    bool? isPublic,
    List<String>? tags,
  }) async {
    try {
      final userId = FirebaseService.auth.currentUser?.uid;
      if (userId == null) return false;

      // Verify ownership
      final playlist = await getPlaylist(playlistId);
      if (playlist == null || playlist.userId != userId) return false;

      final updates = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (coverImage != null) updates['coverImage'] = coverImage;
      if (isPublic != null) updates['isPublic'] = isPublic;
      if (tags != null) updates['tags'] = tags;

      await _firestore.collection(_collection).doc(playlistId).update(updates);
      return true;
    } catch (e) {
      print('Error updating playlist: $e');
      return false;
    }
  }

  /// Delete a playlist
  static Future<bool> deletePlaylist(String playlistId) async {
    try {
      final userId = FirebaseService.auth.currentUser?.uid;
      if (userId == null) return false;

      // Verify ownership
      final playlist = await getPlaylist(playlistId);
      if (playlist == null || playlist.userId != userId) return false;

      await _firestore.collection(_collection).doc(playlistId).delete();
      return true;
    } catch (e) {
      print('Error deleting playlist: $e');
      return false;
    }
  }

  /// Add a track to playlist
  static Future<bool> addTrack(String playlistId, String trackId) async {
    try {
      final userId = FirebaseService.auth.currentUser?.uid;
      if (userId == null) return false;

      // Verify ownership or edit permission
      final playlist = await getPlaylist(playlistId);
      if (playlist == null || !playlist.canEdit(userId)) return false;

      // Check if track already exists
      if (playlist.trackIds.contains(trackId)) return true;

      await _firestore.collection(_collection).doc(playlistId).update({
        'trackIds': FieldValue.arrayUnion([trackId]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      return true;
    } catch (e) {
      print('Error adding track to playlist: $e');
      return false;
    }
  }

  /// Remove a track from playlist
  static Future<bool> removeTrack(String playlistId, String trackId) async {
    try {
      final userId = FirebaseService.auth.currentUser?.uid;
      if (userId == null) return false;

      // Verify ownership or edit permission
      final playlist = await getPlaylist(playlistId);
      if (playlist == null || !playlist.canEdit(userId)) return false;

      await _firestore.collection(_collection).doc(playlistId).update({
        'trackIds': FieldValue.arrayRemove([trackId]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      return true;
    } catch (e) {
      print('Error removing track from playlist: $e');
      return false;
    }
  }

  /// Reorder tracks in playlist
  static Future<bool> reorderTracks(
    String playlistId,
    List<String> newTrackIds,
  ) async {
    try {
      final userId = FirebaseService.auth.currentUser?.uid;
      if (userId == null) return false;

      // Verify ownership or edit permission
      final playlist = await getPlaylist(playlistId);
      if (playlist == null || !playlist.canEdit(userId)) return false;

      await _firestore.collection(_collection).doc(playlistId).update({
        'trackIds': newTrackIds,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      return true;
    } catch (e) {
      print('Error reordering tracks: $e');
      return false;
    }
  }

  /// Get playlist count for user
  static Future<int> getPlaylistCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting playlist count: $e');
      return 0;
    }
  }

  /// Search playlists by title
  static Future<List<MusicList>> searchPlaylists(String query) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isPublic', isEqualTo: true)
          .get();

      final playlists = snapshot.docs
          .map((doc) => MusicList.fromFirestore(doc))
          .where((playlist) =>
              playlist.title.toLowerCase().contains(query.toLowerCase()))
          .toList();

      return playlists;
    } catch (e) {
      print('Error searching playlists: $e');
      return [];
    }
  }

  // ==================== COLLABORATION METHODS ====================

  /// Add a collaborator to playlist
  static Future<bool> addCollaborator({
    required String playlistId,
    required String userId,
    required String username,
    String? displayName,
    String? photoURL,
    required CollaboratorRole role,
  }) async {
    try {
      final currentUserId = FirebaseService.auth.currentUser?.uid;
      if (currentUserId == null) return false;

      // Verify management permission
      final playlist = await getPlaylist(playlistId);
      if (playlist == null || !playlist.canManage(currentUserId)) return false;

      // Cannot add yourself
      if (userId == currentUserId) return false;

      // Create collaborator
      final collaborator = Collaborator(
        userId: userId,
        username: username,
        displayName: displayName,
        photoURL: photoURL,
        role: role,
        addedAt: DateTime.now(),
        addedBy: currentUserId,
      );

      await _firestore.collection(_collection).doc(playlistId).update({
        'collaborators.$userId': collaborator.toFirestore(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Send notification to the added collaborator
      await InAppNotificationService.sendCollaboratorNotification(
        recipientUserId: userId,
        playlistId: playlistId,
        playlistTitle: playlist.title,
        role: role.displayName,
      );

      return true;
    } catch (e) {
      print('Error adding collaborator: $e');
      return false;
    }
  }

  /// Remove a collaborator from playlist
  static Future<bool> removeCollaborator({
    required String playlistId,
    required String collaboratorUserId,
  }) async {
    try {
      final currentUserId = FirebaseService.auth.currentUser?.uid;
      if (currentUserId == null) return false;

      // Verify management permission
      final playlist = await getPlaylist(playlistId);
      if (playlist == null || !playlist.canManage(currentUserId)) return false;

      // Cannot remove the original owner
      if (collaboratorUserId == playlist.userId) return false;

      await _firestore.collection(_collection).doc(playlistId).update({
        'collaborators.$collaboratorUserId': FieldValue.delete(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      return true;
    } catch (e) {
      print('Error removing collaborator: $e');
      return false;
    }
  }

  /// Update collaborator role
  static Future<bool> updateCollaboratorRole({
    required String playlistId,
    required String collaboratorUserId,
    required CollaboratorRole newRole,
  }) async {
    try {
      final currentUserId = FirebaseService.auth.currentUser?.uid;
      if (currentUserId == null) return false;

      // Verify management permission
      final playlist = await getPlaylist(playlistId);
      if (playlist == null || !playlist.canManage(currentUserId)) return false;

      // Cannot change the original owner's role
      if (collaboratorUserId == playlist.userId) return false;

      final collaborator = playlist.collaborators[collaboratorUserId];
      if (collaborator == null) return false;

      final updatedCollaborator = collaborator.copyWith(role: newRole);

      await _firestore.collection(_collection).doc(playlistId).update({
        'collaborators.$collaboratorUserId': updatedCollaborator.toFirestore(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      return true;
    } catch (e) {
      print('Error updating collaborator role: $e');
      return false;
    }
  }

  /// Get playlists where user is a collaborator
  static Stream<List<MusicList>> getCollaborativePlaylists() {
    final userId = FirebaseService.auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection(_collection)
        .where('collaborators.$userId', isNull: false)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MusicList.fromFirestore(doc))
            .toList());
  }

  /// Get all playlists (owned + collaborative)
  static Stream<List<MusicList>> getAllUserPlaylists() {
    final userId = FirebaseService.auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .asyncMap((ownedSnapshot) async {
      // Get owned playlists
      final ownedPlaylists = ownedSnapshot.docs
          .map((doc) => MusicList.fromFirestore(doc))
          .toList();

      // Get collaborative playlists
      final collabSnapshot = await _firestore
          .collection(_collection)
          .where('collaborators.$userId', isNull: false)
          .get();

      final collabPlaylists = collabSnapshot.docs
          .map((doc) => MusicList.fromFirestore(doc))
          .toList();

      // Combine and sort
      final allPlaylists = [...ownedPlaylists, ...collabPlaylists];
      allPlaylists.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return allPlaylists;
    });
  }
}
