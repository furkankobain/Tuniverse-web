import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Group listening session service for real-time collaboration
class GroupSessionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Active sessions notifier
  static final ValueNotifier<List<Map<String, dynamic>>> activeSessions = 
      ValueNotifier<List<Map<String, dynamic>>>([]);

  // ==================== CREATE SESSION ====================

  /// Create new group session
  static Future<String?> createSession({
    required String hostId,
    required String hostName,
    required String sessionName,
    int maxParticipants = 50,
    bool isPublic = true,
  }) async {
    try {
      final sessionRef = _firestore.collection('group_sessions').doc();
      
      await sessionRef.set({
        'sessionId': sessionRef.id,
        'hostId': hostId,
        'hostName': hostName,
        'sessionName': sessionName,
        'maxParticipants': maxParticipants,
        'isPublic': isPublic,
        'participants': [hostId],
        'participantNames': {hostId: hostName},
        'currentTrack': null,
        'queue': [],
        'isPlaying': false,
        'currentPosition': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActivity': FieldValue.serverTimestamp(),
        'voteSkipCount': 0,
        'voteSkipVoters': [],
      });

      return sessionRef.id;
    } catch (e) {
      print('Error creating session: $e');
      return null;
    }
  }

  /// Join existing session
  static Future<bool> joinSession({
    required String sessionId,
    required String userId,
    required String userName,
  }) async {
    try {
      final sessionRef = _firestore.collection('group_sessions').doc(sessionId);
      final session = await sessionRef.get();

      if (!session.exists) return false;

      final data = session.data()!;
      final participants = List<String>.from(data['participants'] ?? []);
      final maxParticipants = data['maxParticipants'] as int;

      // Check if session is full
      if (participants.length >= maxParticipants) {
        return false;
      }

      // Add user to session
      await sessionRef.update({
        'participants': FieldValue.arrayUnion([userId]),
        'participantNames.$userId': userName,
        'lastActivity': FieldValue.serverTimestamp(),
      });

      // Notify other participants
      await _notifyParticipants(sessionId, '$userName joined the session', excludeUserId: userId);

      return true;
    } catch (e) {
      print('Error joining session: $e');
      return false;
    }
  }

  /// Leave session
  static Future<bool> leaveSession({
    required String sessionId,
    required String userId,
  }) async {
    try {
      final sessionRef = _firestore.collection('group_sessions').doc(sessionId);
      final session = await sessionRef.get();

      if (!session.exists) return false;

      final data = session.data()!;
      final hostId = data['hostId'] as String;

      // If host is leaving, end the session
      if (hostId == userId) {
        await endSession(sessionId);
        return true;
      }

      // Remove user from session
      await sessionRef.update({
        'participants': FieldValue.arrayRemove([userId]),
        'participantNames.$userId': FieldValue.delete(),
        'lastActivity': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error leaving session: $e');
      return false;
    }
  }

  /// End session (host only)
  static Future<bool> endSession(String sessionId) async {
    try {
      await _firestore.collection('group_sessions').doc(sessionId).delete();
      return true;
    } catch (e) {
      print('Error ending session: $e');
      return false;
    }
  }

  // ==================== PLAYBACK CONTROL ====================

  /// Play track in session (host only)
  static Future<bool> playTrack({
    required String sessionId,
    required String userId,
    required Map<String, dynamic> track,
  }) async {
    try {
      final sessionRef = _firestore.collection('group_sessions').doc(sessionId);
      final session = await sessionRef.get();

      if (!session.exists) return false;

      final data = session.data()!;
      final hostId = data['hostId'] as String;

      // Only host can control playback
      if (hostId != userId) return false;

      await sessionRef.update({
        'currentTrack': track,
        'isPlaying': true,
        'currentPosition': 0,
        'lastActivity': FieldValue.serverTimestamp(),
        'voteSkipCount': 0,
        'voteSkipVoters': [],
      });

      // Notify participants
      await _notifyParticipants(sessionId, 'Now playing: ${track['name']}');

      return true;
    } catch (e) {
      print('Error playing track: $e');
      return false;
    }
  }

  /// Pause playback (host only)
  static Future<bool> pausePlayback({
    required String sessionId,
    required String userId,
  }) async {
    try {
      final sessionRef = _firestore.collection('group_sessions').doc(sessionId);
      final session = await sessionRef.get();

      if (!session.exists) return false;

      final data = session.data()!;
      final hostId = data['hostId'] as String;

      if (hostId != userId) return false;

      await sessionRef.update({
        'isPlaying': false,
        'lastActivity': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error pausing playback: $e');
      return false;
    }
  }

  /// Resume playback (host only)
  static Future<bool> resumePlayback({
    required String sessionId,
    required String userId,
  }) async {
    try {
      final sessionRef = _firestore.collection('group_sessions').doc(sessionId);
      final session = await sessionRef.get();

      if (!session.exists) return false;

      final data = session.data()!;
      final hostId = data['hostId'] as String;

      if (hostId != userId) return false;

      await sessionRef.update({
        'isPlaying': true,
        'lastActivity': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error resuming playback: $e');
      return false;
    }
  }

  /// Sync playback position
  static Future<bool> syncPosition({
    required String sessionId,
    required int position,
  }) async {
    try {
      await _firestore.collection('group_sessions').doc(sessionId).update({
        'currentPosition': position,
        'lastActivity': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error syncing position: $e');
      return false;
    }
  }

  // ==================== QUEUE MANAGEMENT ====================

  /// Add track to session queue
  static Future<bool> addToQueue({
    required String sessionId,
    required String userId,
    required Map<String, dynamic> track,
  }) async {
    try {
      final sessionRef = _firestore.collection('group_sessions').doc(sessionId);
      
      await sessionRef.update({
        'queue': FieldValue.arrayUnion([{
          ...track,
          'addedBy': userId,
          'addedAt': DateTime.now().millisecondsSinceEpoch,
        }]),
        'lastActivity': FieldValue.serverTimestamp(),
      });

      // Notify participants
      await _notifyParticipants(sessionId, 'Track added to queue: ${track['name']}', excludeUserId: userId);

      return true;
    } catch (e) {
      print('Error adding to queue: $e');
      return false;
    }
  }

  /// Remove track from queue (host or track owner)
  static Future<bool> removeFromQueue({
    required String sessionId,
    required String userId,
    required int queueIndex,
  }) async {
    try {
      final sessionRef = _firestore.collection('group_sessions').doc(sessionId);
      final session = await sessionRef.get();

      if (!session.exists) return false;

      final data = session.data()!;
      final hostId = data['hostId'] as String;
      final queue = List<Map<String, dynamic>>.from(data['queue'] ?? []);

      if (queueIndex >= queue.length) return false;

      final track = queue[queueIndex];
      final trackOwnerId = track['addedBy'] as String;

      // Only host or track owner can remove
      if (hostId != userId && trackOwnerId != userId) return false;

      queue.removeAt(queueIndex);

      await sessionRef.update({
        'queue': queue,
        'lastActivity': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error removing from queue: $e');
      return false;
    }
  }

  // ==================== VOTE TO SKIP ====================

  /// Vote to skip current track
  static Future<bool> voteToSkip({
    required String sessionId,
    required String userId,
  }) async {
    try {
      final sessionRef = _firestore.collection('group_sessions').doc(sessionId);
      final session = await sessionRef.get();

      if (!session.exists) return false;

      final data = session.data()!;
      final participants = List<String>.from(data['participants'] ?? []);
      final voteSkipVoters = List<String>.from(data['voteSkipVoters'] ?? []);

      // Check if user already voted
      if (voteSkipVoters.contains(userId)) return false;

      voteSkipVoters.add(userId);
      final voteCount = voteSkipVoters.length;
      final requiredVotes = (participants.length * 0.5).ceil(); // 50% needed

      await sessionRef.update({
        'voteSkipCount': voteCount,
        'voteSkipVoters': voteSkipVoters,
        'lastActivity': FieldValue.serverTimestamp(),
      });

      // If enough votes, skip track
      if (voteCount >= requiredVotes) {
        await _skipTrack(sessionId, data['hostId']);
        await _notifyParticipants(sessionId, 'Track skipped by vote');
      } else {
        await _notifyParticipants(
          sessionId, 
          'Skip vote: $voteCount/$requiredVotes',
          excludeUserId: userId,
        );
      }

      return true;
    } catch (e) {
      print('Error voting to skip: $e');
      return false;
    }
  }

  /// Skip track (internal method)
  static Future<void> _skipTrack(String sessionId, String hostId) async {
    final sessionRef = _firestore.collection('group_sessions').doc(sessionId);
    final session = await sessionRef.get();

    if (!session.exists) return;

    final data = session.data()!;
    final queue = List<Map<String, dynamic>>.from(data['queue'] ?? []);

    if (queue.isEmpty) {
      // No more tracks, stop playing
      await sessionRef.update({
        'currentTrack': null,
        'isPlaying': false,
        'voteSkipCount': 0,
        'voteSkipVoters': [],
      });
    } else {
      // Play next track in queue
      final nextTrack = queue.removeAt(0);
      await sessionRef.update({
        'currentTrack': nextTrack,
        'queue': queue,
        'currentPosition': 0,
        'voteSkipCount': 0,
        'voteSkipVoters': [],
      });
    }
  }

  // ==================== SESSION DISCOVERY ====================

  /// Get public sessions
  static Future<List<Map<String, dynamic>>> getPublicSessions({int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('group_sessions')
          .where('isPublic', isEqualTo: true)
          .orderBy('lastActivity', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'sessionId': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error getting public sessions: $e');
      return [];
    }
  }

  /// Get active sessions (alias for getPublicSessions)
  static Future<List<Map<String, dynamic>>> getActiveSessions({int limit = 20}) async {
    return await getPublicSessions(limit: limit);
  }

  /// Get session details (alias for getSession)
  static Future<Map<String, dynamic>> getSessionDetails(String sessionId) async {
    final session = await getSession(sessionId);
    return session ?? {};
  }

  /// Get session details
  static Future<Map<String, dynamic>?> getSession(String sessionId) async {
    try {
      final doc = await _firestore.collection('group_sessions').doc(sessionId).get();
      
      if (!doc.exists) return null;

      return {
        'sessionId': doc.id,
        ...doc.data()!,
      };
    } catch (e) {
      print('Error getting session: $e');
      return null;
    }
  }

  /// Listen to session updates (real-time)
  static Stream<Map<String, dynamic>?> watchSession(String sessionId) {
    return _firestore
        .collection('group_sessions')
        .doc(sessionId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      
      return {
        'sessionId': snapshot.id,
        ...snapshot.data()!,
      };
    });
  }

  // ==================== HELPER METHODS ====================

  /// Notify participants about session events
  static Future<void> _notifyParticipants(
    String sessionId, 
    String message, 
    {String? excludeUserId}
  ) async {
    try {
      final session = await _firestore.collection('group_sessions').doc(sessionId).get();
      if (!session.exists) return;

      final participants = List<String>.from(session.data()!['participants'] ?? []);
      
      for (final participantId in participants) {
        if (participantId == excludeUserId) continue;

        await _firestore
            .collection('users')
            .doc(participantId)
            .collection('notifications')
            .add({
          'type': 'session_update',
          'sessionId': sessionId,
          'message': message,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
    } catch (e) {
      print('Error notifying participants: $e');
    }
  }

  /// Clean up inactive sessions (call periodically)
  static Future<void> cleanupInactiveSessions() async {
    try {
      final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));
      
      final snapshot = await _firestore
          .collection('group_sessions')
          .where('lastActivity', isLessThan: Timestamp.fromDate(twoHoursAgo))
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error cleaning up sessions: $e');
    }
  }
}
