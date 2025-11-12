import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:async/async.dart';
// import 'package:spotify_sdk/spotify_sdk.dart'; // Disabled for now
import '../models/spotify_activity.dart';
import 'firebase_service.dart';
import 'dart:async';

/// Service for tracking user Spotify activity
/// - Currently playing tracks
/// - Recently played tracks  
/// - Real-time activity updates
class SpotifyActivityService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Polling interval for Spotify activity (every 30 seconds)
  static const Duration _pollingInterval = Duration(seconds: 30);
  
  static Timer? _activityPollingTimer;
  
  /// Start tracking current user's Spotify activity
  static void startActivityTracking() {
    _activityPollingTimer?.cancel();
    
    _activityPollingTimer = Timer.periodic(_pollingInterval, (timer) async {
      await _updateCurrentActivity();
    });
    
    // Initial update
    _updateCurrentActivity();
  }
  
  /// Stop tracking activity
  static void stopActivityTracking() {
    _activityPollingTimer?.cancel();
    _activityPollingTimer = null;
  }
  
  /// Update current user's Spotify activity
  static Future<void> _updateCurrentActivity() async {
    try {
      final userId = FirebaseService.auth.currentUser?.uid;
      if (userId == null) return;
      
      // Get currently playing track from Spotify SDK
      // final playerState = await SpotifySdk.getPlayerState();
      // TODO: Implement real Spotify SDK integration
      final playerState = null; // Mock
      
      if (playerState != null && playerState.track != null) {
        final track = playerState.track!;
        final isPaused = playerState.isPaused;
        
        final activity = SpotifyActivity(
          userId: userId,
          trackId: track.uri.split(':').last,
          trackName: track.name,
          artistName: track.artist.name ?? 'Unknown Artist',
          albumName: track.album.name ?? '',
          albumImageUrl: track.imageUri.raw,
          timestamp: DateTime.now(),
          isPlaying: !isPaused,
        );
        
        // Save to Firestore
        await _saveActivity(activity);
        
        // Also add to listening history if playing
        if (!isPaused) {
          await _addToListeningHistory(activity);
        }
      } else {
        // No track playing, mark user as not playing
        await _markAsNotPlaying(userId);
      }
    } catch (e) {
      print('Error updating Spotify activity: $e');
    }
  }
  
  /// Save activity to Firestore
  static Future<void> _saveActivity(SpotifyActivity activity) async {
    try {
      await _firestore
          .collection('spotify_activities')
          .doc(activity.userId)
          .set(activity.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      print('Error saving activity: $e');
    }
  }
  
  /// Add to listening history
  static Future<void> _addToListeningHistory(SpotifyActivity activity) async {
    try {
      // Check if this track was already added recently (within last 5 minutes)
      final recentQuery = await _firestore
          .collection('users')
          .doc(activity.userId)
          .collection('listening_history')
          .where('trackId', isEqualTo: activity.trackId)
          .where('timestamp', isGreaterThan: DateTime.now().subtract(const Duration(minutes: 5)))
          .limit(1)
          .get();
      
      // Only add if not already in recent history
      if (recentQuery.docs.isEmpty) {
        await _firestore
            .collection('users')
            .doc(activity.userId)
            .collection('listening_history')
            .add(activity.toFirestore());
      }
    } catch (e) {
      print('Error adding to listening history: $e');
    }
  }
  
  /// Mark user as not currently playing anything
  static Future<void> _markAsNotPlaying(String userId) async {
    try {
      await _firestore
          .collection('spotify_activities')
          .doc(userId)
          .set({
        'userId': userId,
        'isPlaying': false,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error marking as not playing: $e');
    }
  }
  
  /// Get a user's current Spotify activity
  static Stream<SpotifyActivity?> getUserActivity(String userId) {
    return _firestore
        .collection('spotify_activities')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      
      try {
        return SpotifyActivity.fromFirestore(snapshot);
      } catch (e) {
        print('Error parsing activity: $e');
        return null;
      }
    });
  }
  
  /// Get multiple users' activities (for following feed)
  static Stream<List<SpotifyActivity>> getFollowingActivities(List<String> userIds) {
    if (userIds.isEmpty) {
      return Stream.value([]);
    }
    
    // Firestore 'in' query limit is 10, so we need to batch
    final batches = <List<String>>[];
    for (var i = 0; i < userIds.length; i += 10) {
      batches.add(
        userIds.sublist(i, i + 10 > userIds.length ? userIds.length : i + 10),
      );
    }
    
    // Combine all batch streams
    final streams = batches.map((batch) {
      return _firestore
          .collection('spotify_activities')
          .where(FieldPath.documentId, whereIn: batch)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) {
              try {
                return SpotifyActivity.fromFirestore(doc);
              } catch (e) {
                print('Error parsing activity: $e');
                return null;
              }
            })
            .whereType<SpotifyActivity>()
            .toList();
      });
    });
    
    // Combine all streams into one
    if (streams.isEmpty) {
      return Stream.value([]);
    }
    
    return StreamGroup.merge(streams).asyncMap((allActivities) async {
      // allActivities is already a List<SpotifyActivity> from the batch
      final combined = List<SpotifyActivity>.from(allActivities);
      combined.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return combined;
    });
  }
  
  /// Get user's recently played tracks (from listening history)
  static Future<List<SpotifyActivity>> getRecentlyPlayed(String userId, {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('listening_history')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) {
            try {
              return SpotifyActivity.fromFirestore(doc);
            } catch (e) {
              print('Error parsing recently played: $e');
              return null;
            }
          })
          .whereType<SpotifyActivity>()
          .toList();
    } catch (e) {
      print('Error getting recently played: $e');
      return [];
    }
  }
  
  /// Get listening time summary for a user
  static Future<Map<String, dynamic>> getListeningSummary(String userId, {DateTime? since}) async {
    try {
      var query = _firestore
          .collection('users')
          .doc(userId)
          .collection('listening_history')
          .orderBy('timestamp', descending: true);
      
      if (since != null) {
        query = query.where('timestamp', isGreaterThan: since);
      }
      
      final snapshot = await query.get();
      
      // Calculate stats
      final trackIds = <String>{};
      final artistNames = <String>{};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['trackId'] != null) trackIds.add(data['trackId']);
        if (data['artistName'] != null) artistNames.add(data['artistName']);
      }
      
      return {
        'totalListens': snapshot.docs.length,
        'uniqueTracks': trackIds.length,
        'uniqueArtists': artistNames.length,
        'estimatedMinutes': (snapshot.docs.length * 3.5).round(), // Average track ~3.5 min
      };
    } catch (e) {
      print('Error getting listening summary: $e');
      return {
        'totalListens': 0,
        'uniqueTracks': 0,
        'uniqueArtists': 0,
        'estimatedMinutes': 0,
      };
    }
  }
  
  /// Clear old listening history (keep last 90 days)
  static Future<void> cleanupOldHistory(String userId) async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 90));
      
      final oldDocs = await _firestore
          .collection('users')
          .doc(userId)
          .collection('listening_history')
          .where('timestamp', isLessThan: cutoffDate)
          .get();
      
      final batch = _firestore.batch();
      for (var doc in oldDocs.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      print('Cleaned up ${oldDocs.docs.length} old history entries');
    } catch (e) {
      print('Error cleaning up history: $e');
    }
  }
}

/// Helper class for combining streams
class StreamGroup<T> {
  static Stream<T> merge<T>(Iterable<Stream<T>> streams) {
    final controller = StreamController<T>();
    
    for (var stream in streams) {
      stream.listen(
        controller.add,
        onError: controller.addError,
      );
    }
    
    return controller.stream;
  }
}
