const admin = require('firebase-admin');

/**
 * Middleware to verify Firebase authentication token
 */
const verifyAuth = async (req, res, next) => {
  try {
    const token = req.headers.authorization?.split('Bearer ')[1];
    
    if (!token) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'No authentication token provided',
      });
    }

    // Verify Firebase ID token
    const decodedToken = await admin.auth().verifyIdToken(token);
    
    // Attach user info to request
    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email,
      emailVerified: decodedToken.email_verified,
      displayName: decodedToken.name,
      photoURL: decodedToken.picture,
    };
    
    next();
  } catch (error) {
    console.error('Auth error:', error);
    
    if (error.code === 'auth/id-token-expired') {
      return res.status(401).json({
        error: 'Token Expired',
        message: 'Authentication token has expired',
      });
    }
    
    if (error.code === 'auth/argument-error') {
      return res.status(401).json({
        error: 'Invalid Token',
        message: 'Authentication token is invalid',
      });
    }
    
    return res.status(401).json({
      error: 'Authentication Failed',
      message: 'Failed to verify authentication token',
    });
  }
};

/**
 * Middleware to verify admin privileges
 */
const verifyAdmin = async (req, res, next) => {
  try {
    if (!req.user) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Authentication required',
      });
    }

    // Get user's custom claims
    const userRecord = await admin.auth().getUser(req.user.uid);
    
    if (userRecord.customClaims?.admin !== true) {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'Admin privileges required',
      });
    }
    
    next();
  } catch (error) {
    console.error('Admin verification error:', error);
    return res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to verify admin status',
    });
  }
};

/**
 * Optional authentication - doesn't fail if no token provided
 */
const optionalAuth = async (req, res, next) => {
  try {
    const token = req.headers.authorization?.split('Bearer ')[1];
    
    if (token) {
      const decodedToken = await admin.auth().verifyIdToken(token);
      req.user = {
        uid: decodedToken.uid,
        email: decodedToken.email,
        emailVerified: decodedToken.email_verified,
        displayName: decodedToken.name,
        photoURL: decodedToken.picture,
      };
    }
    
    next();
  } catch (error) {
    // Continue without user if token is invalid
    console.warn('Optional auth failed, continuing without user:', error.message);
    next();
  }
};

module.exports = {
  verifyAuth,
  verifyAdmin,
  optionalAuth,
};
