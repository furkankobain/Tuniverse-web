import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification.dart';
import 'firebase_bypass_auth_service.dart';

class InAppNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'notifications';

  /// Create a notification
  static Future<bool> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    String? fromUserId,
    String? fromUsername,
    String? fromPhotoURL,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notification = AppNotification(
        id: '',
        userId: userId,
        type: type,
        title: title,
        body: body,
        fromUserId: fromUserId,
        fromUsername: fromUsername,
        fromPhotoURL: fromPhotoURL,
        data: data,
        isRead: false,
        createdAt: DateTime.now(),
      );

      await _firestore.collection(_collection).add(notification.toFirestore());
      return true;
    } catch (e) {
      print('Error creating notification: $e');
      return false;
    }
  }

  /// Send playlist collaborator notification
  static Future<bool> sendCollaboratorNotification({
    required String recipientUserId,
    required String playlistId,
    required String playlistTitle,
    required String role,
  }) async {
    final currentUserId = FirebaseBypassAuthService.currentUserId;
    final currentUser = FirebaseBypassAuthService.currentUser;

    if (currentUserId == null || currentUser == null) return false;

    return await createNotification(
      userId: recipientUserId,
      type: NotificationType.playlistCollaborator,
      title: 'Playlist\'e Eklendiniz',
      body: '${currentUser.username}, sizi "${playlistTitle}" playlist\'ine $role olarak ekledi',
      fromUserId: currentUserId,
      fromUsername: currentUser.username,
      fromPhotoURL: null,
      data: {
        'playlistId': playlistId,
        'playlistTitle': playlistTitle,
        'role': role,
      },
    );
  }

  /// Get notifications for current user
  static Stream<List<AppNotification>> getUserNotifications() {
    final userId = FirebaseBypassAuthService.currentUserId;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromFirestore(doc))
            .toList());
  }

  /// Get unread notification count
  static Stream<int> getUnreadCount() {
    final userId = FirebaseBypassAuthService.currentUserId;
    if (userId == null) return Stream.value(0);

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark notification as read
  static Future<bool> markAsRead(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).update({
        'isRead': true,
      });
      return true;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read
  static Future<bool> markAllAsRead() async {
    try {
      final userId = FirebaseBypassAuthService.currentUserId;
      if (userId == null) return false;

      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }

  /// Delete notification
  static Future<bool> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).delete();
      return true;
    } catch (e) {
      print('Error deleting notification: $e');
      return false;
    }
  }

  /// Delete all read notifications
  static Future<bool> deleteAllRead() async {
    try {
      final userId = FirebaseBypassAuthService.currentUserId;
      if (userId == null) return false;

      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('Error deleting read notifications: $e');
      return false;
    }
  }
}
