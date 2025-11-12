const express = require('express');
const router = express.Router();
const { verifyAuth, optionalAuth } = require('../middleware/auth');

// Login placeholder (use Firebase client SDK on frontend; backend verifies tokens)
router.post('/login', (req, res) => {
  return res.status(501).json({ error: 'Not Implemented', message: 'Use Firebase client SDK for login' });
});

// Logout placeholder
router.post('/logout', verifyAuth, (req, res) => {
  return res.json({ success: true });
});

// Current user info (from verified token)
router.get('/me', verifyAuth, (req, res) => {
  return res.json({ user: req.user });
});

module.exports = router;