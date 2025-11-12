const express = require('express');
const router = express.Router();

// Placeholder routes (the app handles OAuth via client + redirect URI)
router.get('/auth', (_req, res) => {
  return res.status(501).json({ error: 'Not Implemented', message: 'Use client-side OAuth flow (PKCE)' });
});

router.get('/callback', (_req, res) => {
  return res.status(501).json({ error: 'Not Implemented' });
});

module.exports = router;