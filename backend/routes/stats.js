const express = require('express');
const router = express.Router();
const admin = require('firebase-admin');

// User stats (simple aggregate)
router.get('/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const ratingsSnap = await admin.firestore().collection('music_ratings').where('userId', '==', userId).get();
    const playlistsSnap = await admin.firestore().collection('playlists').where('ownerId', '==', userId).get();
    return res.json({
      userId,
      totalRatings: ratingsSnap.size,
      totalPlaylists: playlistsSnap.size,
    });
  } catch (e) {
    console.error('GET /stats/user/:userId error', e);
    return res.status(500).json({ error: 'Internal Server Error' });
  }
});

// Global stats (very basic)
router.get('/global', async (_req, res) => {
  try {
    const usersSnap = await admin.firestore().collection('users').limit(1).get();
    return res.json({ ok: true, usersCollectionExists: !usersSnap.empty });
  } catch (e) {
    console.error('GET /stats/global error', e);
    return res.status(500).json({ error: 'Internal Server Error' });
  }
});

module.exports = router;