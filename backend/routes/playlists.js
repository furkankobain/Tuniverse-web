const express = require('express');
const router = express.Router();
const admin = require('firebase-admin');
const { verifyAuth, optionalAuth } = require('../middleware/auth');

// Get playlist
router.get('/:playlistId', optionalAuth, async (req, res) => {
  try {
    const { playlistId } = req.params;
    const doc = await admin.firestore().collection('playlists').doc(playlistId).get();
    if (!doc.exists) return res.status(404).json({ error: 'Not Found', message: 'Playlist not found' });
    return res.json({ id: doc.id, ...doc.data() });
  } catch (e) {
    console.error('GET /playlists/:playlistId error', e);
    return res.status(500).json({ error: 'Internal Server Error' });
  }
});

// Create playlist
router.post('/', verifyAuth, async (req, res) => {
  try {
    const data = req.body || {};
    data.ownerId = req.user.uid;
    data.createdAt = admin.firestore.FieldValue.serverTimestamp();
    data.updatedAt = admin.firestore.FieldValue.serverTimestamp();
    const ref = await admin.firestore().collection('playlists').add(data);
    return res.status(201).json({ id: ref.id });
  } catch (e) {
    console.error('POST /playlists error', e);
    return res.status(500).json({ error: 'Internal Server Error' });
  }
});

module.exports = router;