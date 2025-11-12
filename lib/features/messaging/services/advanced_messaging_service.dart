import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Advanced messaging features service
class AdvancedMessagingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Chat themes
  static const Map<String, ChatTheme> chatThemes = {
    'default': ChatTheme(
      name: 'Varsayılan',
      primaryColor: Color(0xFF1DB954),
      backgroundColor: Color(0xFF121212),
      bubbleColor: Color(0xFF282828),
    ),
    'ocean': ChatTheme(
      name: 'Okyanus',
      primaryColor: Color(0xFF00A8E8),
      backgroundColor: Color(0xFF003459),
      bubbleColor: Color(0xFF007EA7),
    ),
    'sunset': ChatTheme(
      name: 'Gün Batımı',
      primaryColor: Color(0xFFFF6B6B),
      backgroundColor: Color(0xFF4A1C40),
      bubbleColor: Color(0xFFEE4540),
    ),
    'forest': ChatTheme(
      name: 'Orman',
      primaryColor: Color(0xFF2D6A4F),
      backgroundColor: Color(0xFF1B4332),
      bubbleColor: Color(0xFF40916C),
    ),
    'lavender': ChatTheme(
      name: 'Lavanta',
      primaryColor: Color(0xFFB19CD9),
      backgroundColor: Color(0xFF6A4C93),
      bubbleColor: Color(0xFF8672B0),
    ),
  };

  /// Set chat theme
  static Future<void> setChatTheme(String chatId, String themeId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'theme': themeId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error setting chat theme: $e');
      rethrow;
    }
  }

  /// Get chat theme
  static Future<String> getChatTheme(String chatId) async {
    try {
      final doc = await _firestore.collection('chats').doc(chatId).get();
      return doc.data()?['theme'] ?? 'default';
    } catch (e) {
      print('Error getting chat theme: $e');
      return 'default';
    }
  }

  /// Create Spotify Blend playlist for chat
  static Future<Map<String, dynamic>?> createSpotifyBlend({
    required String chatId,
    required List<String> userIds,
  }) async {
    try {
      // Create a blend playlist combining users' music tastes
      final blendPlaylist = {
        'id': 'blend_${chatId}_${DateTime.now().millisecondsSinceEpoch}',
        'chatId': chatId,
        'userIds': userIds,
        'name': 'Blend - ${userIds.length} kişi',
        'description': 'Ortak müzik zevkiniz',
        'tracks': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Get users' top tracks
      final allTopTracks = <Map<String, dynamic>>[];
      
      for (final userId in userIds) {
        final userTopTracksSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('top_tracks')
            .limit(20)
            .get();

        for (final doc in userTopTracksSnapshot.docs) {
          allTopTracks.add(doc.data());
        }
      }

      // Mix tracks and remove duplicates
      allTopTracks.shuffle();
      final uniqueTracks = <String, Map<String, dynamic>>{};
      
      for (final track in allTopTracks) {
        final trackId = track['trackId'] as String?;
        if (trackId != null && !uniqueTracks.containsKey(trackId)) {
          uniqueTracks[trackId] = track;
        }
      }

      blendPlaylist['tracks'] = uniqueTracks.keys.take(50).toList();

      // Save to Firestore
      await _firestore
          .collection('spotify_blends')
          .doc(blendPlaylist['id'] as String)
          .set(blendPlaylist);

      // Add to chat
      await _firestore.collection('chats').doc(chatId).update({
        'blendPlaylistId': blendPlaylist['id'],
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return blendPlaylist;
    } catch (e) {
      print('Error creating Spotify Blend: $e');
      return null;
    }
  }

  /// Create group chat
  static Future<String?> createGroupChat({
    required String name,
    required List<String> memberIds,
    required String creatorId,
    String? description,
    String? imageUrl,
  }) async {
    try {
      final groupChatDoc = _firestore.collection('group_chats').doc();
      
      final groupChat = {
        'id': groupChatDoc.id,
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'memberIds': memberIds,
        'creatorId': creatorId,
        'admins': [creatorId],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'theme': 'default',
        'messageCount': 0,
      };

      await groupChatDoc.set(groupChat);

      // Add to each member's chat list
      for (final memberId in memberIds) {
        await _firestore
            .collection('users')
            .doc(memberId)
            .collection('chats')
            .doc(groupChatDoc.id)
            .set({
          'chatId': groupChatDoc.id,
          'type': 'group',
          'addedAt': FieldValue.serverTimestamp(),
        });
      }

      return groupChatDoc.id;
    } catch (e) {
      print('Error creating group chat: $e');
      return null;
    }
  }

  /// Add member to group chat
  static Future<void> addMemberToGroup(String groupId, String userId) async {
    try {
      await _firestore.collection('group_chats').doc(groupId).update({
        'memberIds': FieldValue.arrayUnion([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Add to user's chat list
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('chats')
          .doc(groupId)
          .set({
        'chatId': groupId,
        'type': 'group',
        'addedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding member to group: $e');
      rethrow;
    }
  }

  /// Remove member from group chat
  static Future<void> removeMemberFromGroup(String groupId, String userId) async {
    try {
      await _firestore.collection('group_chats').doc(groupId).update({
        'memberIds': FieldValue.arrayRemove([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Remove from user's chat list
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('chats')
          .doc(groupId)
          .delete();
    } catch (e) {
      print('Error removing member from group: $e');
      rethrow;
    }
  }

  /// Send GIF message (Giphy API)
  static Future<void> sendGif({
    required String chatId,
    required String senderId,
    required String gifUrl,
    required String gifId,
  }) async {
    try {
      await _firestore.collection('messages').add({
        'chatId': chatId,
        'senderId': senderId,
        'type': 'gif',
        'gifUrl': gifUrl,
        'gifId': gifId,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Update chat's last message
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': '🎞️ GIF',
        'lastMessageType': 'gif',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': senderId,
      });
    } catch (e) {
      print('Error sending GIF: $e');
      rethrow;
    }
  }

  /// Search GIFs from Giphy (mock implementation)
  static Future<List<Map<String, dynamic>>> searchGifs(String query) async {
    // In production, use Giphy API
    // For now, return mock data
    return [
      {
        'id': 'gif1',
        'url': 'https://media.giphy.com/media/3o7btPCcdNniyf0ArS/giphy.gif',
        'previewUrl': 'https://media.giphy.com/media/3o7btPCcdNniyf0ArS/200w.gif',
        'title': 'Music GIF',
      },
      {
        'id': 'gif2',
        'url': 'https://media.giphy.com/media/l0HlBO7eyXzSZkJri/giphy.gif',
        'previewUrl': 'https://media.giphy.com/media/l0HlBO7eyXzSZkJri/200w.gif',
        'title': 'Dancing GIF',
      },
      {
        'id': 'gif3',
        'url': 'https://media.giphy.com/media/xUPGcm0fR3RcxRqE4U/giphy.gif',
        'previewUrl': 'https://media.giphy.com/media/xUPGcm0fR3RcxRqE4U/200w.gif',
        'title': 'Party GIF',
      },
    ];
  }

  /// Setup Firebase Cloud Messaging for notifications
  static Future<void> setupMessageNotifications(String userId) async {
    try {
      // This would integrate with FCM in production
      // For now, just log setup
      print('Setting up FCM for user: $userId');
      
      // In production:
      // 1. Get FCM token
      // 2. Save to Firestore
      // 3. Subscribe to topics
      // 4. Handle background/foreground messages
    } catch (e) {
      print('Error setting up notifications: $e');
    }
  }

  /// Send notification for new message
  static Future<void> sendMessageNotification({
    required String recipientId,
    required String senderName,
    required String messageText,
    required String chatId,
  }) async {
    try {
      // Save notification to Firestore
      await _firestore.collection('notifications').add({
        'userId': recipientId,
        'type': 'message',
        'title': senderName,
        'body': messageText,
        'chatId': chatId,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      // In production, trigger FCM notification via Cloud Function
      print('Notification sent to $recipientId');
    } catch (e) {
      print('Error sending notification: $e');
    }
  }
}

/// Chat theme data class
class ChatTheme {
  final String name;
  final Color primaryColor;
  final Color backgroundColor;
  final Color bubbleColor;

  const ChatTheme({
    required this.name,
    required this.primaryColor,
    required this.backgroundColor,
    required this.bubbleColor,
  });
}
