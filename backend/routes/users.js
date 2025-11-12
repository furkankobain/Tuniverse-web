const express = require('express');
const router = express.Router();
const admin = require('firebase-admin');
const { verifyAuth, optionalAuth } = require('../middleware/auth');

// Get user profile
router.get('/:userId', optionalAuth, async (req, res) => {
  try {
    const { userId } = req.params;
    const doc = await admin.firestore().collection('users').doc(userId).get();
    if (!doc.exists) return res.status(404).json({ error: 'Not Found', message: 'User not found' });
    return res.json({ id: doc.id, ...doc.data() });
  } catch (e) {
    console.error('GET /users/:userId error', e);
    return res.status(500).json({ error: 'Internal Server Error' });
  }
});

// Update own profile
router.put('/:userId', verifyAuth, async (req, res) => {
  try {
    const { userId } = req.params;
    if (req.user.uid !== userId) return res.status(403).json({ error: 'Forbidden' });
    const data = req.body || {};
    data.updatedAt = admin.firestore.FieldValue.serverTimestamp();
    await admin.firestore().collection('users').doc(userId).set(data, { merge: true });
    return res.json({ success: true });
  } catch (e) {
    console.error('PUT /users/:userId error', e);
    return res.status(500).json({ error: 'Internal Server Error' });
  }
});

module.exports = router;