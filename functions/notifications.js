// Firebase Cloud Functions - Push Notification Triggers
// Deploy: firebase deploy --only functions

const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize admin if not already done
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const messaging = admin.messaging();

// ============================================
// HELPER FUNCTIONS
// ============================================

/**
 * Send push notification to user
 */
async function sendNotificationToUser(userId, notification) {
  try {
    const userDoc = await db.collection('users').doc(userId).get();
    const fcmToken = userDoc.data()?.fcmToken;

    if (!fcmToken) {
      console.log(`No FCM token for user: ${userId}`);
      return;
    }

    const message = {
      token: fcmToken,
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: notification.data || {},
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          color: '#FF5E5E',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    await messaging.send(message);
    console.log(`✅ Notification sent to user: ${userId}`);

    // Save notification to Firestore
    await db.collection('users').doc(userId).collection('notifications').add({
      ...notification,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      read: false,
    });
  } catch (error) {
    console.error(`❌ Error sending notification: ${error}`);
  }
}

// ============================================
// NOTIFICATION TRIGGERS
// ============================================

/**
 * Trigger: New Follower
 * When someone follows a user, send notification
 */
exports.onNewFollower = functions.firestore
  .document('users/{userId}/followers/{followerId}')
  .onCreate(async (snap, context) => {
    const { userId, followerId } = context.params;

    // Get follower info
    const followerDoc = await db.collection('users').doc(followerId).get();
    const followerName = followerDoc.data()?.displayName || 'Someone';

    // Send notification
    await sendNotificationToUser(userId, {
      title: '👤 Yeni Takipçi',
      body: `${followerName} seni takip etmeye başladı`,
      data: {
        type: 'new_follower',
        followerId: followerId,
        action: 'open_profile',
      },
    });
  });

/**
 * Trigger: New Playlist
 * When someone you follow creates a playlist
 */
exports.onNewPlaylist = functions.firestore
  .document('playlists/{playlistId}')
  .onCreate(async (snap, context) => {
    const { playlistId } = context.params;
    const playlistData = snap.data();
    const creatorId = playlistData.creatorId;

    if (!creatorId) return;

    // Get creator info
    const creatorDoc = await db.collection('users').doc(creatorId).get();
    const creatorName = creatorDoc.data()?.displayName || 'Someone';
    const playlistName = playlistData.name || 'Yeni Playlist';

    // Get all followers
    const followersSnapshot = await db
      .collection('users')
      .doc(creatorId)
      .collection('followers')
      .get();

    // Send to each follower
    const promises = followersSnapshot.docs.map((doc) => {
      return sendNotificationToUser(doc.id, {
        title: '🎵 Yeni Playlist',
        body: `${creatorName} "${playlistName}" adlı playlist oluşturdu`,
        data: {
          type: 'new_playlist',
          playlistId: playlistId,
          creatorId: creatorId,
          action: 'open_playlist',
        },
      });
    });

    await Promise.all(promises);
  });

/**
 * Trigger: New Like on Review
 * When someone likes your review
 */
exports.onReviewLike = functions.firestore
  .document('reviews/{reviewId}/likes/{userId}')
  .onCreate(async (snap, context) => {
    const { reviewId, userId } = context.params;

    // Get review owner
    const reviewDoc = await db.collection('reviews').doc(reviewId).get();
    const reviewOwnerId = reviewDoc.data()?.userId;

    if (!reviewOwnerId || reviewOwnerId === userId) return; // Don't notify self

    // Get liker info
    const likerDoc = await db.collection('users').doc(userId).get();
    const likerName = likerDoc.data()?.displayName || 'Someone';

    // Send notification
    await sendNotificationToUser(reviewOwnerId, {
      title: '❤️ İncelemeniz Beğenildi',
      body: `${likerName} incelemenizi beğendi`,
      data: {
        type: 'review_like',
        reviewId: reviewId,
        likerId: userId,
        action: 'open_review',
      },
    });
  });

/**
 * Trigger: New Comment on Review
 */
exports.onReviewComment = functions.firestore
  .document('reviews/{reviewId}/comments/{commentId}')
  .onCreate(async (snap, context) => {
    const { reviewId, commentId } = context.params;
    const commentData = snap.data();
    const commenterId = commentData.userId;

    // Get review owner
    const reviewDoc = await db.collection('reviews').doc(reviewId).get();
    const reviewOwnerId = reviewDoc.data()?.userId;

    if (!reviewOwnerId || reviewOwnerId === commenterId) return;

    // Get commenter info
    const commenterDoc = await db.collection('users').doc(commenterId).get();
    const commenterName = commenterDoc.data()?.displayName || 'Someone';

    // Send notification
    await sendNotificationToUser(reviewOwnerId, {
      title: '💬 Yeni Yorum',
      body: `${commenterName} incelemenize yorum yaptı`,
      data: {
        type: 'review_comment',
        reviewId: reviewId,
        commentId: commentId,
        commenterId: commenterId,
        action: 'open_review',
      },
    });
  });

/**
 * Trigger: New Message (DM)
 */
exports.onNewMessage = functions.firestore
  .document('conversations/{conversationId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const { conversationId, messageId } = context.params;
    const messageData = snap.data();
    const senderId = messageData.senderId;

    // Get conversation participants
    const conversationDoc = await db
      .collection('conversations')
      .doc(conversationId)
      .get();
    const participants = conversationDoc.data()?.participants || [];

    // Get sender info
    const senderDoc = await db.collection('users').doc(senderId).get();
    const senderName = senderDoc.data()?.displayName || 'Someone';

    // Send to other participant (not sender)
    const recipient = participants.find((id) => id !== senderId);
    if (!recipient) return;

    await sendNotificationToUser(recipient, {
      title: `💬 ${senderName}`,
      body: messageData.text || 'Yeni mesaj',
      data: {
        type: 'new_message',
        conversationId: conversationId,
        senderId: senderId,
        action: 'open_conversation',
      },
    });
  });

/**
 * Trigger: Playlist Collaborative Invite
 */
exports.onPlaylistInvite = functions.firestore
  .document('playlists/{playlistId}/collaborators/{userId}')
  .onCreate(async (snap, context) => {
    const { playlistId, userId } = context.params;

    // Get playlist info
    const playlistDoc = await db.collection('playlists').doc(playlistId).get();
    const playlistName = playlistDoc.data()?.name || 'Bir playlist';
    const inviterId = playlistDoc.data()?.creatorId;

    // Get inviter info
    const inviterDoc = await db.collection('users').doc(inviterId).get();
    const inviterName = inviterDoc.data()?.displayName || 'Someone';

    // Send notification
    await sendNotificationToUser(userId, {
      title: '🎶 Playlist Daveti',
      body: `${inviterName} sizi "${playlistName}" playlist'ine ekledi`,
      data: {
        type: 'playlist_invite',
        playlistId: playlistId,
        inviterId: inviterId,
        action: 'open_playlist',
      },
    });
  });

// ============================================
// SCHEDULED NOTIFICATIONS (Optional)
// ============================================

/**
 * Daily Recommendation Notification
 * Sends at 10:00 AM every day
 */
exports.dailyRecommendation = functions.pubsub
  .schedule('0 10 * * *') // 10:00 AM daily
  .timeZone('Europe/Istanbul')
  .onRun(async (context) => {
    // Get all users with FCM tokens
    const usersSnapshot = await db
      .collection('users')
      .where('fcmToken', '!=', null)
      .limit(1000)
      .get();

    const promises = usersSnapshot.docs.map((doc) => {
      return sendNotificationToUser(doc.id, {
        title: '🎵 Günün Önerileri Hazır!',
        body: 'Senin için özel seçtiğimiz şarkıları keşfet',
        data: {
          type: 'daily_recommendation',
          action: 'open_discover',
        },
      });
    });

    await Promise.all(promises);
    console.log(`✅ Daily recommendations sent to ${usersSnapshot.size} users`);
  });
