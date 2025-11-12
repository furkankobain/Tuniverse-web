const express = require('express');
const router = express.Router();
const admin = require('firebase-admin');
const { optionalAuth } = require('../middleware/auth');

// Get track details (from Firestore cache if present)
router.get('/:trackId', optionalAuth, async (req, res) => {
  try {
    const { trackId } = req.params;
    const doc = await admin.firestore().collection('tracks').doc(trackId).get();
    if (!doc.exists) return res.status(404).json({ error: 'Not Found', message: 'Track not found' });
    return res.json({ id: doc.id, ...doc.data() });
  } catch (e) {
    console.error('GET /tracks/:trackId error', e);
    return res.status(500).json({ error: 'Internal Server Error' });
  }
});

module.exports = router;