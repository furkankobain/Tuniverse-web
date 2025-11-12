const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

/**
 * Send notification when a new message is received
 */
exports.sendMessageNotification = functions.firestore
  .document('messages/{messageId}')
  .onCreate(async (snapshot, context) => {
    try {
      const message = snapshot.data();
      const { chatId, senderId, text, type } = message;

      // Get chat participants
      const chatDoc = await db.collection('chats').doc(chatId).get();
      if (!chatDoc.exists) return null;

      const chatData = chatDoc.data();
      const participants = chatData.participants || [];

      // Get sender info
      const senderDoc = await db.collection('users').doc(senderId).get();
      const senderName = senderDoc.data()?.displayName || 'Someone';

      // Send notification to all participants except sender
      const notificationPromises = participants
        .filter(userId => userId !== senderId)
        .map(async userId => {
          // Get user's FCM tokens
          const userDoc = await db.collection('users').doc(userId).get();
          const fcmTokens = userDoc.data()?.fcmTokens || [];

          if (fcmTokens.length === 0) return null;

          // Prepare notification
          const notificationBody = type === 'text' 
            ? text 
            : type === 'gif' 
            ? '🎞️ GIF'
            : type === 'audio'
            ? '🎵 Voice message'
            : '📎 Attachment';

          const payload = {
            notification: {
              title: senderName,
              body: notificationBody,
              sound: 'default',
            },
            data: {
              chatId,
              senderId,
              type: 'message',
            },
          };

          // Send to all user's devices
          return admin.messaging().sendToDevice(fcmTokens, payload);
        });

      await Promise.all(notificationPromises);
      console.log('Message notifications sent successfully');
      return null;
    } catch (error) {
      console.error('Error sending message notification:', error);
      return null;
    }
  });

/**
 * Track user activity (listens, ratings, etc.)
 */
exports.trackUserActivity = functions.firestore
  .document('listens/{listenId}')
  .onCreate(async (snapshot, context) => {
    try {
      const listen = snapshot.data();
      const { userId, trackId, trackName, artistName, timestamp } = listen;

      // Create activity record
      await db.collection('activities').add({
        userId,
        type: 'listen',
        data: {
          trackId,
          trackName,
          artistName,
        },
        timestamp: timestamp || admin.firestore.FieldValue.serverTimestamp(),
      });

      // Update user stats
      const userStatsRef = db.collection('users').doc(userId).collection('stats').doc('summary');
      await userStatsRef.set({
        totalListens: admin.firestore.FieldValue.increment(1),
        lastActivity: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      console.log('Activity tracked successfully');
      return null;
    } catch (error) {
      console.error('Error tracking activity:', error);
      return null;
    }
  });

/**
 * Update user stats when rating is added
 */
exports.updateStatsOnRating = functions.firestore
  .document('ratings/{ratingId}')
  .onCreate(async (snapshot, context) => {
    try {
      const rating = snapshot.data();
      const { userId, trackId, rating: ratingValue } = rating;

      // Create activity record
      await db.collection('activities').add({
        userId,
        type: 'rating',
        data: {
          trackId,
          rating: ratingValue,
        },
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Update user stats
      const userStatsRef = db.collection('users').doc(userId).collection('stats').doc('summary');
      await userStatsRef.set({
        totalRatings: admin.firestore.FieldValue.increment(1),
      }, { merge: true });

      console.log('Rating stats updated');
      return null;
    } catch (error) {
      console.error('Error updating stats on rating:', error);
      return null;
    }
  });

/**
 * Handle follow requests and notifications
 */
exports.handleFollowRequest = functions.firestore
  .document('follow_requests/{requestId}')
  .onCreate(async (snapshot, context) => {
    try {
      const request = snapshot.data();
      const { fromUserId, toUserId, status } = request;

      if (status === 'pending') {
        // Get sender info
        const fromUserDoc = await db.collection('users').doc(fromUserId).get();
        const fromUserName = fromUserDoc.data()?.displayName || 'Someone';

        // Get recipient's FCM tokens
        const toUserDoc = await db.collection('users').doc(toUserId).get();
        const fcmTokens = toUserDoc.data()?.fcmTokens || [];

        if (fcmTokens.length > 0) {
          const payload = {
            notification: {
              title: 'New Follow Request',
              body: `${fromUserName} wants to follow you`,
              sound: 'default',
            },
            data: {
              type: 'follow_request',
              fromUserId,
            },
          };

          await admin.messaging().sendToDevice(fcmTokens, payload);
        }

        // Create notification record
        await db.collection('notifications').add({
          userId: toUserId,
          type: 'follow_request',
          fromUserId,
          fromUserName,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          read: false,
        });
      }

      console.log('Follow request handled');
      return null;
    } catch (error) {
      console.error('Error handling follow request:', error);
      return null;
    }
  });

/**
 * Clean up old activities (run daily)
 */
exports.cleanupOldActivities = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    try {
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

      const oldActivitiesSnapshot = await db
        .collection('activities')
        .where('timestamp', '<', admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
        .limit(500)
        .get();

      if (oldActivitiesSnapshot.empty) {
        console.log('No old activities to clean up');
        return null;
      }

      const batch = db.batch();
      oldActivitiesSnapshot.docs.forEach(doc => {
        batch.delete(doc.ref);
      });

      await batch.commit();
      console.log(`Deleted ${oldActivitiesSnapshot.size} old activities`);
      return null;
    } catch (error) {
      console.error('Error cleaning up old activities:', error);
      return null;
    }
  });

/**
 * Update trending tracks (run every hour)
 */
exports.updateTrendingTracks = functions.pubsub
  .schedule('every 1 hours')
  .onRun(async (context) => {
    try {
      const oneDayAgo = new Date();
      oneDayAgo.setDate(oneDayAgo.getDate() - 1);

      // Get recent listens
      const recentListensSnapshot = await db
        .collection('listens')
        .where('timestamp', '>', admin.firestore.Timestamp.fromDate(oneDayAgo))
        .limit(1000)
        .get();

      // Count track listens
      const trackCounts = {};
      recentListensSnapshot.docs.forEach(doc => {
        const listen = doc.data();
        const trackId = listen.trackId;
        if (trackId) {
          trackCounts[trackId] = (trackCounts[trackId] || 0) + 1;
        }
      });

      // Sort and get top 50
      const trending = Object.entries(trackCounts)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 50)
        .map(([trackId, count]) => ({ trackId, count }));

      // Save to Firestore
      await db.collection('trending').doc('tracks').set({
        tracks: trending,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log('Trending tracks updated');
      return null;
    } catch (error) {
      console.error('Error updating trending tracks:', error);
      return null;
    }
  });

/**
 * Calculate and cache user statistics (run daily)
 */
exports.calculateUserStats = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    try {
      // Get all users
      const usersSnapshot = await db.collection('users').limit(100).get();

      const promises = usersSnapshot.docs.map(async userDoc => {
        const userId = userDoc.id;

        // Get user's listens
        const listensSnapshot = await db
          .collection('listens')
          .where('userId', '==', userId)
          .get();

        // Calculate stats
        const genreCounts = {};
        const artistCounts = {};
        let totalMinutes = 0;

        listensSnapshot.docs.forEach(doc => {
          const listen = doc.data();
          
          // Count genres
          if (listen.genres) {
            listen.genres.forEach(genre => {
              genreCounts[genre] = (genreCounts[genre] || 0) + 1;
            });
          }

          // Count artists
          if (listen.artistName) {
            artistCounts[listen.artistName] = (artistCounts[listen.artistName] || 0) + 1;
          }

          // Add duration (assuming 3 minutes per track)
          totalMinutes += 3;
        });

        // Get top genres and artists
        const topGenres = Object.entries(genreCounts)
          .sort((a, b) => b[1] - a[1])
          .slice(0, 5)
          .map(([genre, count]) => ({ genre, count }));

        const topArtists = Object.entries(artistCounts)
          .sort((a, b) => b[1] - a[1])
          .slice(0, 10)
          .map(([artist, count]) => ({ artist, count }));

        // Save stats
        await db.collection('users').doc(userId).collection('stats').doc('summary').set({
          totalListens: listensSnapshot.size,
          listeningTimeMinutes: totalMinutes,
          topGenres,
          topArtists,
          lastCalculated: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      await Promise.all(promises);
      console.log('User stats calculated');
      return null;
    } catch (error) {
      console.error('Error calculating user stats:', error);
      return null;
    }
  });

/**
 * Security: Validate message content
 */
exports.validateMessage = functions.firestore
  .document('messages/{messageId}')
  .onCreate(async (snapshot, context) => {
    try {
      const message = snapshot.data();
      const { text, type } = message;

      // Check for inappropriate content (basic check)
      if (type === 'text' && text) {
        const inappropriateWords = ['spam', 'scam']; // Add more as needed
        const lowerText = text.toLowerCase();
        
        const containsInappropriate = inappropriateWords.some(word => 
          lowerText.includes(word)
        );

        if (containsInappropriate) {
          // Flag the message
          await snapshot.ref.update({
            flagged: true,
            flagReason: 'inappropriate_content',
          });
          
          console.log('Message flagged for inappropriate content');
        }
      }

      return null;
    } catch (error) {
      console.error('Error validating message:', error);
      return null;
    }
  });
