import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class PresenceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseDatabase _realtimeDb = FirebaseDatabase.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initialize presence system for current user
  static Future<void> initialize() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final userStatusRef = _realtimeDb.ref('status/$userId');
    
    // Set user as online
    await userStatusRef.set({
      'state': 'online',
      'lastSeen': ServerValue.timestamp,
    });

    // When user disconnects, set as offline
    userStatusRef.onDisconnect().set({
      'state': 'offline',
      'lastSeen': ServerValue.timestamp,
    });

    // Also update Firestore for easier querying
    await _updateFirestorePresence(userId, true);
  }

  /// Update user's online status
  static Future<void> setOnline() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final userStatusRef = _realtimeDb.ref('status/$userId');
    await userStatusRef.update({
      'state': 'online',
      'lastSeen': ServerValue.timestamp,
    });

    await _updateFirestorePresence(userId, true);
  }

  /// Set user as offline
  static Future<void> setOffline() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final userStatusRef = _realtimeDb.ref('status/$userId');
    await userStatusRef.update({
      'state': 'offline',
      'lastSeen': ServerValue.timestamp,
    });

    await _updateFirestorePresence(userId, false);
  }

  /// Update Firestore presence
  static Future<void> _updateFirestorePresence(
    String userId,
    bool isOnline,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating Firestore presence: $e');
    }
  }

  /// Get user's online status stream
  static Stream<bool> getUserOnlineStatus(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return false;
      final data = snapshot.data();
      return data?['isOnline'] ?? false;
    });
  }

  /// Get user's last seen time
  static Stream<DateTime?> getUserLastSeen(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      final data = snapshot.data();
      final timestamp = data?['lastSeen'] as Timestamp?;
      return timestamp?.toDate();
    });
  }

  /// Check if user is online (one-time check)
  static Future<bool> isUserOnline(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return false;
      return doc.data()?['isOnline'] ?? false;
    } catch (e) {
      print('Error checking user online status: $e');
      return false;
    }
  }

  /// Format last seen time
  static String formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'bilinmiyor';

    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inSeconds < 60) {
      return 'az önce';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return 'uzun zaman önce';
    }
  }
}
