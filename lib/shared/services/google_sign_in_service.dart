import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class GoogleSignInService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
    serverClientId: '707432048304-8ch4lvc48mine3oem9k7o03fsoua5v55.apps.googleusercontent.com',
  );
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sign in with Google
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // Web uses popup, mobile uses native flow
      if (kIsWeb) {
        // Web: Use Firebase Auth popup
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.setCustomParameters({
          'prompt': 'select_account'
        });
        
        UserCredential userCredential = await _auth.signInWithPopup(googleProvider);
        
        // Save user data to Firestore
        await _saveUserToFirestore(userCredential.user);
        
        return userCredential;
      } else {
        // Mobile: Use google_sign_in package
        // Disconnect any previously signed-in account to force account chooser
        await _googleSignIn.signOut();
        
        // Trigger the Google Sign-In flow (will show account chooser)
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        
        if (googleUser == null) {
          // User cancelled the sign-in
          return null;
        }

        // Obtain the auth details from the request
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        // Create a new credential
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in to Firebase with the Google credential
        UserCredential? userCredential;
        try {
          userCredential = await _auth.signInWithCredential(credential);
        } catch (e) {
          print('Error signing in with credential: $e');
          // Even if credential sign-in has type error, user might be signed in
          // Check current user
          final currentUser = _auth.currentUser;
          if (currentUser != null) {
            print('User is signed in despite error: ${currentUser.uid}');
            // Create a mock UserCredential-like object
            await _saveUserToFirestore(currentUser);
            return null; // Return null but user is signed in
          }
          rethrow;
        }
        
        // Save user data to Firestore
        await _saveUserToFirestore(userCredential.user);

        return userCredential;
      }
    } catch (e) {
      print('Google Sign-In Error: $e');
      return null;
    }
  }

  /// Save user data to Firestore
  static Future<void> _saveUserToFirestore(User? user) async {
    if (user == null) return;

    try {
      final userRef = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await userRef.get();

      if (!docSnapshot.exists) {
        // New user - create profile with onboarding flag
        final displayName = user.displayName ?? user.email?.split('@')[0] ?? 'User';
        
        print('👤 Creating new Google user:');
        print('   - Email: ${user.email}');
        print('   - Display Name: $displayName');
        print('   - Photo URL: ${user.photoURL}');
        
        await userRef.set({
          'uid': user.uid,
          'email': user.email,
          'displayName': displayName,
          'username': _generateUsername(displayName),
          'photoURL': user.photoURL,
          'profileImageUrl': user.photoURL ?? '',
          'bio': '',
          'spotifyConnected': false,
          'totalSongsRated': 0,
          'totalAlbumsRated': 0,
          'totalReviews': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'provider': 'google',
          'emailVerified': user.emailVerified,
          'onboardingCompleted': false,
          'googleProfile': {
            'displayName': user.displayName,
            'email': user.email,
            'photoURL': user.photoURL,
          },
        });
        
        print('✅ Google user created with onboarding: false');
      } else {
        // Existing user - update last login
        await userRef.update({
          'updatedAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'photoURL': user.photoURL,
          'displayName': user.displayName ?? docSnapshot.data()?['displayName'] ?? 'User',
        });
        
        print('🔄 Existing Google user updated');
      }
    } catch (e) {
      print('Error saving user to Firestore: $e');
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      print('Google Sign-Out Error: $e');
    }
  }

  /// Check if user is signed in
  static bool get isSignedIn => _auth.currentUser != null;

  /// Get current user
  static User? get currentUser => _auth.currentUser;

  /// Get user stream
  static Stream<User?> get userChanges => _auth.userChanges();

  /// Generate username from display name
  static String _generateUsername(String displayName) {
    final base = displayName.toLowerCase().replaceAll(' ', '').replaceAll(RegExp(r'[^a-z0-9]'), '');
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    return '$base$timestamp';
  }
}
