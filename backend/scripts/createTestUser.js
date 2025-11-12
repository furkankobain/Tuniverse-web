require('dotenv').config({ path: __dirname + '/../.env' });
const admin = require('firebase-admin');
const path = require('path');

const serviceAccountPath = path.join(__dirname, '..', 'config', 'serviceAccountKey.json');
const serviceAccount = require(serviceAccountPath);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: process.env.FIREBASE_DATABASE_URL,
});

(async () => {
  const email = process.env.TEST_USER_EMAIL || 'test+qa@tuniverse.app';
  const password = process.env.TEST_USER_PASSWORD || 'Tuniverse!123';
  const displayName = 'QA Tester';

  try {
    let userRecord;
    try {
      userRecord = await admin.auth().getUserByEmail(email);
      await admin.auth().updateUser(userRecord.uid, { password, displayName });
    } catch (e) {
      if (e.code === 'auth/user-not-found') {
        userRecord = await admin.auth().createUser({ email, password, displayName, emailVerified: true });
      } else {
        throw e;
      }
    }

    const uid = userRecord.uid;
    const firestore = admin.firestore();
    const userDoc = firestore.collection('users').doc(uid);
    const now = admin.firestore.FieldValue.serverTimestamp();

    await userDoc.set({
      uid,
      email,
      displayName,
      username: 'qa_' + Math.floor(Date.now() / 1000),
      bio: 'Test account',
      profileImageUrl: '',
      spotifyConnected: false,
      totalSongsRated: 0,
      totalAlbumsRated: 0,
      totalReviews: 0,
      createdAt: now,
      updatedAt: now,
    }, { merge: true });

    console.log('✅ Test user ready');
    console.log('EMAIL=' + email);
    console.log('PASSWORD=' + password);
    process.exit(0);
  } catch (err) {
    console.error('❌ Failed to create/update test user:', err);
    process.exit(1);
  }
})();
