const express = require('express');
const router = express.Router();
const admin = require('firebase-admin');
const { verifyAuth, optionalAuth } = require('../middleware/auth');
const NodeCache = require('node-cache');

const db = admin.firestore();
const cache = new NodeCache({ stdTTL: 3600 }); // 1 hour cache

/**
 * GET /api/recommendations/personalized
 * Get personalized recommendations for the authenticated user
 */
router.get('/personalized', verifyAuth, async (req, res) => {
  try {
    const userId = req.user.uid;
    const limit = parseInt(req.query.limit) || 20;
    
    // Check cache
    const cacheKey = `recommendations:${userId}:${limit}`;
    const cached = cache.get(cacheKey);
    if (cached) {
      return res.json(cached);
    }

    // Get user profile and listening history
    const userDoc = await db.collection('users').doc(userId).get();
    const userData = userDoc.data() || {};

    // Get user's recent listens
    const listensSnapshot = await db
      .collection('listens')
      .where('userId', '==', userId)
      .orderBy('timestamp', 'desc')
      .limit(50)
      .get();

    const recentListens = listensSnapshot.docs.map(doc => doc.data());

    // Get user's ratings
    const ratingsSnapshot = await db
      .collection('ratings')
      .where('userId', '==', userId)
      .where('rating', '>=', 4)
      .limit(30)
      .get();

    const highRatedTracks = ratingsSnapshot.docs.map(doc => doc.data());

    // Extract favorite genres and artists
    const genreCounts = {};
    const artistCounts = {};

    recentListens.forEach(listen => {
      if (listen.genres) {
        listen.genres.forEach(genre => {
          genreCounts[genre] = (genreCounts[genre] || 0) + 1;
        });
      }
      if (listen.artistName) {
        artistCounts[listen.artistName] = (artistCounts[listen.artistName] || 0) + 1;
      }
    });

    const favoriteGenres = Object.entries(genreCounts)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 3)
      .map(e => e[0]);

    const favoriteArtists = Object.entries(artistCounts)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 5)
      .map(e => e[0]);

    // Find tracks matching user's preferences
    const recommendations = [];
    const seenTrackIds = new Set(recentListens.map(l => l.trackId));

    // Get tracks from favorite genres
    if (favoriteGenres.length > 0) {
      const genreTracksSnapshot = await db
        .collection('tracks')
        .where('genres', 'array-contains-any', favoriteGenres)
        .limit(30)
        .get();

      genreTracksSnapshot.docs.forEach(doc => {
        const trackData = doc.data();
        if (!seenTrackIds.has(doc.id)) {
          recommendations.push({
            ...trackData,
            trackId: doc.id,
            recommendationType: 'genre_match',
            reason: `Based on your love for ${favoriteGenres[0]}`,
          });
          seenTrackIds.add(doc.id);
        }
      });
    }

    // Get tracks from similar users (collaborative filtering)
    const similarUsers = await findSimilarUsers(userId, favoriteArtists);
    
    for (const similarUserId of similarUsers.slice(0, 3)) {
      const theirRatingsSnapshot = await db
        .collection('ratings')
        .where('userId', '==', similarUserId)
        .where('rating', '>=', 4)
        .limit(10)
        .get();

      theirRatingsSnapshot.docs.forEach(doc => {
        const trackData = doc.data();
        if (!seenTrackIds.has(trackData.trackId)) {
          recommendations.push({
            ...trackData,
            recommendationType: 'collaborative',
            reason: 'Users with similar taste loved this',
          });
          seenTrackIds.add(trackData.trackId);
        }
      });
    }

    // Shuffle and limit recommendations
    const shuffled = recommendations
      .sort(() => Math.random() - 0.5)
      .slice(0, limit);

    const result = {
      recommendations: shuffled,
      userProfile: {
        favoriteGenres,
        favoriteArtists,
        totalListens: recentListens.length,
      },
    };

    // Cache the result
    cache.set(cacheKey, result);

    res.json(result);
  } catch (error) {
    console.error('Error getting personalized recommendations:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to get recommendations',
    });
  }
});

/**
 * GET /api/recommendations/trending
 * Get trending tracks
 */
router.get('/trending', optionalAuth, async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 20;
    const timeframe = req.query.timeframe || 'week'; // week, month, all_time
    
    // Check cache
    const cacheKey = `trending:${timeframe}:${limit}`;
    const cached = cache.get(cacheKey);
    if (cached) {
      return res.json(cached);
    }

    // Calculate time threshold
    const now = new Date();
    let startDate;
    
    switch (timeframe) {
      case 'day':
        startDate = new Date(now.getTime() - 24 * 60 * 60 * 1000);
        break;
      case 'week':
        startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
        break;
      case 'month':
        startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
        break;
      default:
        startDate = new Date(0); // All time
    }

    // Get recent listens
    const listensSnapshot = await db
      .collection('listens')
      .where('timestamp', '>', admin.firestore.Timestamp.fromDate(startDate))
      .limit(1000)
      .get();

    // Count track listens
    const trackCounts = {};
    const trackData = {};

    listensSnapshot.docs.forEach(doc => {
      const listen = doc.data();
      const trackId = listen.trackId;
      
      if (trackId) {
        trackCounts[trackId] = (trackCounts[trackId] || 0) + 1;
        if (!trackData[trackId]) {
          trackData[trackId] = listen;
        }
      }
    });

    // Sort by popularity
    const trending = Object.entries(trackCounts)
      .sort((a, b) => b[1] - a[1])
      .slice(0, limit)
      .map(([trackId, count]) => ({
        ...trackData[trackId],
        trackId,
        listenCount: count,
        recommendationType: 'trending',
        reason: `${count} listens in the past ${timeframe}`,
      }));

    const result = { trending, timeframe };
    
    // Cache the result
    cache.set(cacheKey, result);

    res.json(result);
  } catch (error) {
    console.error('Error getting trending tracks:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to get trending tracks',
    });
  }
});

/**
 * GET /api/recommendations/genre/:genre
 * Get recommendations by genre
 */
router.get('/genre/:genre', optionalAuth, async (req, res) => {
  try {
    const genre = req.params.genre;
    const limit = parseInt(req.query.limit) || 20;
    
    const tracksSnapshot = await db
      .collection('tracks')
      .where('genres', 'array-contains', genre)
      .limit(limit * 2)
      .get();

    if (tracksSnapshot.empty) {
      return res.json({ recommendations: [] });
    }

    // Get popularity data
    const recommendations = await Promise.all(
      tracksSnapshot.docs.map(async (doc) => {
        const trackData = doc.data();
        
        // Get listen count
        const listensSnapshot = await db
          .collection('listens')
          .where('trackId', '==', doc.id)
          .limit(1)
          .get();

        return {
          ...trackData,
          trackId: doc.id,
          listenCount: listensSnapshot.size,
          recommendationType: 'genre',
          reason: `Popular in ${genre}`,
        };
      })
    );

    // Sort by popularity
    const sorted = recommendations
      .sort((a, b) => b.listenCount - a.listenCount)
      .slice(0, limit);

    res.json({ recommendations: sorted, genre });
  } catch (error) {
    console.error('Error getting genre recommendations:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to get genre recommendations',
    });
  }
});

/**
 * GET /api/recommendations/mood/:mood
 * Get recommendations by mood
 */
router.get('/mood/:mood', optionalAuth, async (req, res) => {
  try {
    const mood = req.params.mood;
    const limit = parseInt(req.query.limit) || 20;
    
    // Check cache
    const cacheKey = `mood:${mood}:${limit}`;
    const cached = cache.get(cacheKey);
    if (cached) {
      return res.json(cached);
    }

    // Get mood-specific audio feature ranges
    const moodFeatures = getMoodFeatures(mood);
    
    if (!moodFeatures) {
      return res.status(400).json({
        error: 'Invalid Mood',
        message: 'Mood not recognized',
      });
    }

    // Get audio features
    const featuresSnapshot = await db
      .collection('audio_features')
      .limit(100)
      .get();

    const recommendations = [];

    featuresSnapshot.docs.forEach(doc => {
      const features = doc.data();
      const matchScore = calculateMoodMatch(features, moodFeatures);
      
      if (matchScore > 0.6) {
        recommendations.push({
          ...features,
          trackId: doc.id,
          moodScore: matchScore,
          recommendationType: 'mood',
          reason: `Perfect for ${mood} mood`,
        });
      }
    });

    // Sort by mood match
    const sorted = recommendations
      .sort((a, b) => b.moodScore - a.moodScore)
      .slice(0, limit);

    const result = { recommendations: sorted, mood };
    
    // Cache the result
    cache.set(cacheKey, result);

    res.json(result);
  } catch (error) {
    console.error('Error getting mood recommendations:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to get mood recommendations',
    });
  }
});

/**
 * POST /api/recommendations/feedback
 * Record user feedback on recommendations
 */
router.post('/feedback', verifyAuth, async (req, res) => {
  try {
    const userId = req.user.uid;
    const { trackId, action, recommendationType } = req.body;

    if (!trackId || !action) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'trackId and action are required',
      });
    }

    await db.collection('recommendation_feedback').add({
      userId,
      trackId,
      action, // 'like', 'dislike', 'skip', 'listen'
      recommendationType,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Invalidate cache for this user
    cache.del(`recommendations:${userId}:20`);

    res.json({ success: true });
  } catch (error) {
    console.error('Error recording feedback:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to record feedback',
    });
  }
});

// Helper function to find similar users
async function findSimilarUsers(userId, favoriteArtists) {
  if (favoriteArtists.length === 0) return [];

  const listensSnapshot = await db
    .collection('listens')
    .where('artistName', 'in', favoriteArtists.slice(0, 5))
    .limit(100)
    .get();

  const userScores = {};

  listensSnapshot.docs.forEach(doc => {
    const listen = doc.data();
    const otherUserId = listen.userId;
    
    if (otherUserId !== userId) {
      userScores[otherUserId] = (userScores[otherUserId] || 0) + 1;
    }
  });

  return Object.entries(userScores)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5)
    .map(e => e[0]);
}

// Helper function to get mood-specific audio features
function getMoodFeatures(mood) {
  const moodMap = {
    happy: { valence: [0.6, 1.0], energy: [0.5, 1.0] },
    sad: { valence: [0.0, 0.4], energy: [0.0, 0.5] },
    energetic: { energy: [0.7, 1.0], tempo: [120, 200] },
    calm: { energy: [0.0, 0.4], acousticness: [0.5, 1.0] },
    party: { danceability: [0.7, 1.0], energy: [0.6, 1.0] },
    focused: { instrumentalness: [0.5, 1.0], energy: [0.3, 0.7] },
  };

  return moodMap[mood.toLowerCase()];
}

// Helper function to calculate mood match score
function calculateMoodMatch(features, moodFeatures) {
  let totalScore = 0;
  let featureCount = 0;

  for (const [featureName, [min, max]] of Object.entries(moodFeatures)) {
    const value = features[featureName] || 0.5;
    
    if (value >= min && value <= max) {
      const center = (min + max) / 2;
      const distance = Math.abs(value - center);
      const rangeSize = (max - min) / 2;
      const score = 1 - (distance / rangeSize);
      totalScore += score;
    }
    
    featureCount++;
  }

  return featureCount > 0 ? totalScore / featureCount : 0;
}

module.exports = router;
