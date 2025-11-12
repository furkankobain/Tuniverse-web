const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Import notification functions
const notifications = require('./notifications');

const db = admin.firestore();

// Use Europe West region for better latency from Turkey
const europeFunctions = functions.region('europe-west1');

/**
 * Send notification when user gets a new follower
 */
exports.onNewFollower = europeFunctions.firestore
  .document('users/{userId}/followers/{followerId}')
  .onCreate(async (snap, context) => {
    const { userId, followerId } = context.params;
    
    try {
      // Get follower info
      const followerDoc = await db.collection('users').doc(followerId).get();
      const followerData = followerDoc.data();
      
      // Get user's FCM token
      const userDoc = await db.collection('users').doc(userId).get();
      const fcmToken = userDoc.data()?.fcmToken;
      
      if (!fcmToken) return null;
      
      // Send notification
      const message = {
        token: fcmToken,
        notification: {
          title: 'Yeni Takipçi 🎉',
          body: `${followerData?.displayName || 'Birisi'} seni takip etmeye başladı!`,
        },
        data: {
          type: 'new_follower',
          followerId: followerId,
        },
      };
      
      return admin.messaging().send(message);
    } catch (error) {
      console.error('Error sending follower notification:', error);
      return null;
    }
  });

/**
 * Send notification when track gets a new like
 */
exports.onTrackLiked = europeFunctions.firestore
  .document('tracks/{trackId}/likes/{userId}')
  .onCreate(async (snap, context) => {
    const { trackId, userId } = context.params;
    
    try {
      // Get track info
      const trackDoc = await db.collection('tracks').doc(trackId).get();
      const trackData = trackDoc.data();
      const ownerId = trackData?.userId;
      
      if (!ownerId || ownerId === userId) return null;
      
      // Get liker info
      const userDoc = await db.collection('users').doc(userId).get();
      const userData = userDoc.data();
      
      // Get owner's FCM token
      const ownerDoc = await db.collection('users').doc(ownerId).get();
      const fcmToken = ownerDoc.data()?.fcmToken;
      
      if (!fcmToken) return null;
      
      // Send notification
      const message = {
        token: fcmToken,
        notification: {
          title: 'Yeni Beğeni ❤️',
          body: `${userData?.displayName || 'Birisi'} "${trackData?.name || 'şarkını'}" beğendi!`,
        },
        data: {
          type: 'track_liked',
          trackId: trackId,
          userId: userId,
        },
      };
      
      return admin.messaging().send(message);
    } catch (error) {
      console.error('Error sending like notification:', error);
      return null;
    }
  });

/**
 * Send daily music recommendations
 * Runs every day at 9 AM
 */
exports.sendDailyRecommendations = europeFunctions.pubsub
  .schedule('0 9 * * *')
  .timeZone('Europe/Istanbul')
  .onRun(async (context) => {
    try {
      // Get all users with FCM tokens and notification enabled
      const usersSnapshot = await db.collection('users')
        .where('fcmToken', '!=', null)
        .where('notificationSettings.musicRecommendations', '==', true)
        .get();
      
      const messages = [];
      
      usersSnapshot.forEach((doc) => {
        const userData = doc.data();
        messages.push({
          token: userData.fcmToken,
          notification: {
            title: '🎵 Bugünün Müzik Önerileri',
            body: 'Dinleme geçmişine göre yeni şarkılar keşfet!',
          },
          data: {
            type: 'daily_recommendations',
          },
        });
      });
      
      if (messages.length > 0) {
        await admin.messaging().sendEach(messages);
        console.log(`Sent ${messages.length} daily recommendation notifications`);
      }
      
      return null;
    } catch (error) {
      console.error('Error sending daily recommendations:', error);
      return null;
    }
  });

/**
 * Send weekly digest
 * Runs every Sunday at 8 PM
 */
exports.sendWeeklyDigest = europeFunctions.pubsub
  .schedule('0 20 * * 0')
  .timeZone('Europe/Istanbul')
  .onRun(async (context) => {
    try {
      const usersSnapshot = await db.collection('users')
        .where('fcmToken', '!=', null)
        .where('notificationSettings.weeklyDigest', '==', true)
        .get();
      
      const messages = [];
      
      usersSnapshot.forEach((doc) => {
        const userData = doc.data();
        messages.push({
          token: userData.fcmToken,
          notification: {
            title: '📊 Haftalık Özet',
            body: 'Bu hafta dinlediğin şarkıları ve istatistikleri gör!',
          },
          data: {
            type: 'weekly_digest',
          },
        });
      });
      
      if (messages.length > 0) {
        await admin.messaging().sendEach(messages);
        console.log(`Sent ${messages.length} weekly digest notifications`);
      }
      
      return null;
    } catch (error) {
      console.error('Error sending weekly digest:', error);
      return null;
    }
  });

/**
 * Analyze mood and send notification
 * Runs every day at 6 PM
 */
exports.analyzeDailyMood = europeFunctions.pubsub
  .schedule('0 18 * * *')
  .timeZone('Europe/Istanbul')
  .onRun(async (context) => {
    try {
      const usersSnapshot = await db.collection('users')
        .where('fcmToken', '!=', null)
        .get();
      
      const messages = [];
      
      for (const doc of usersSnapshot.docs) {
        const userData = doc.data();
        const userId = doc.id;
        
        // Get user's recent tracks (last 24 hours)
        const yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000);
        const recentTracksSnapshot = await db.collection('listeningHistory')
          .where('userId', '==', userId)
          .where('timestamp', '>=', yesterday)
          .limit(20)
          .get();
        
        if (recentTracksSnapshot.size >= 5) {
          messages.push({
            token: userData.fcmToken,
            notification: {
              title: '🎨 Ruh Halini Keşfet',
              body: 'Bugünkü dinleme alışkanlığın analiz edildi! Ruh haline özel playlist seni bekliyor.',
            },
            data: {
              type: 'mood_analysis',
            },
          });
        }
      }
      
      if (messages.length > 0) {
        await admin.messaging().sendEach(messages);
        console.log(`Sent ${messages.length} mood analysis notifications`);
      }
      
      return null;
    } catch (error) {
      console.error('Error analyzing mood:', error);
      return null;
    }
  });

/**
 * Clean up old listening history
 * Runs every day at 3 AM
 */
exports.cleanupOldHistory = europeFunctions.pubsub
  .schedule('0 3 * * *')
  .timeZone('Europe/Istanbul')
  .onRun(async (context) => {
    try {
      // Delete listening history older than 90 days
      const ninetyDaysAgo = new Date(Date.now() - 90 * 24 * 60 * 60 * 1000);
      
      const oldHistorySnapshot = await db.collection('listeningHistory')
        .where('timestamp', '<', ninetyDaysAgo)
        .limit(500)
        .get();
      
      const batch = db.batch();
      let deleteCount = 0;
      
      oldHistorySnapshot.forEach((doc) => {
        batch.delete(doc.ref);
        deleteCount++;
      });
      
      if (deleteCount > 0) {
        await batch.commit();
        console.log(`Deleted ${deleteCount} old listening history records`);
      }
      
      return null;
    } catch (error) {
      console.error('Error cleaning up old history:', error);
      return null;
    }
  });

/**
 * Update user statistics
 * Triggered when listening history is added
 */
exports.updateUserStats = europeFunctions.firestore
  .document('listeningHistory/{historyId}')
  .onCreate(async (snap, context) => {
    const historyData = snap.data();
    const userId = historyData.userId;
    
    try {
      const userStatsRef = db.collection('users').doc(userId).collection('stats').doc('listening');
      
      await db.runTransaction(async (transaction) => {
        const statsDoc = await transaction.get(userStatsRef);
        
        if (!statsDoc.exists) {
          transaction.set(userStatsRef, {
            totalTracks: 1,
            totalListeningTime: historyData.duration || 0,
            lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
          });
        } else {
          transaction.update(userStatsRef, {
            totalTracks: admin.firestore.FieldValue.increment(1),
            totalListeningTime: admin.firestore.FieldValue.increment(historyData.duration || 0),
            lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      });
      
      return null;
    } catch (error) {
      console.error('Error updating user stats:', error);
      return null;
    }
  });

// Export additional notification functions
exports.onReviewLike = notifications.onReviewLike;
exports.onReviewComment = notifications.onReviewComment;
exports.onNewMessage = notifications.onNewMessage;
exports.onPlaylistInvite = notifications.onPlaylistInvite;
exports.dailyRecommendation = notifications.dailyRecommendation;
