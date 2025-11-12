const express = require('express');
const router = express.Router();
const admin = require('firebase-admin');
const { verifyAuth } = require('../middleware/auth');

// Follow a user
router.post('/follow/:userId', verifyAuth, async (req, res) => {
  try {
    const toUserId = req.params.userId;
    await admin.firestore().collection('followers').add({
      followerId: req.user.uid,
      followingId: toUserId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return res.json({ success: true });
  } catch (e) {
    console.error('POST /social/follow/:userId error', e);
    return res.status(500).json({ error: 'Internal Server Error' });
  }
});

// Unfollow a user (soft)
router.post('/unfollow/:userId', verifyAuth, async (req, res) => {
  try {
    const toUserId = req.params.userId;
    const snap = await admin
      .firestore()
      .collection('followers')
      .where('followerId', '==', req.user.uid)
      .where('followingId', '==', toUserId)
      .get();
    const batch = admin.firestore().batch();
    snap.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();
    return res.json({ success: true });
  } catch (e) {
    console.error('POST /social/unfollow/:userId error', e);
    return res.status(500).json({ error: 'Internal Server Error' });
  }
});

module.exports = router;