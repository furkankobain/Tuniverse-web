import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../firebase_options.dart';

class FirebaseService {
  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  
  // Auth Methods
  static Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    required String username,
  }) async {
    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        // Create user document immediately
        try {
          await createUserDocument(
            uid: credential.user!.uid,
            email: email,
            displayName: displayName,
            username: username,
          );
        } catch (e) {
          print('⚠️ Error creating user document: $e');
          // Don't throw - user is still created in Auth
        }
      }
      
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      // Firebase serialization bug workaround: user is created despite exception
      if (auth.currentUser != null) {
        print('✅ User created successfully: ${auth.currentUser!.uid}');
        // Create document for the newly created user
        try {
          await createUserDocument(
            uid: auth.currentUser!.uid,
            email: email,
            displayName: displayName,
            username: username,
          );
        } catch (docError) {
          print('⚠️ Failed to create user document: $docError');
        }
        return null; // Return null but user is authenticated
      }
      throw 'An unexpected error occurred. Please try again.';
    }
  }
  
  static void _createUserDocumentInBackground({
    required String uid,
    required String email,
    required String displayName,
    required String username,
  }) {
    // Run in background without waiting
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        await createUserDocument(
          uid: uid,
          email: email,
          displayName: displayName,
          username: username,
        );
        // print( // Debug log removed'User document created successfully in background');
      } catch (e) {
        // print( // Debug log removed'Error creating user document in background: $e');
      }
    });
  }
  
  static Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // Validate inputs
      if (email.trim().isEmpty) {
        throw 'Email or username cannot be empty.';
      }
      if (password.isEmpty) {
        throw 'Password cannot be empty.';
      }
      
      String emailToUse = email.trim();
      
      // Check if input is username (doesn't contain @)
      if (!emailToUse.contains('@')) {
        print('🔍 Looking up email for username: $emailToUse');
        try {
          // Query Firestore to find user by username
          final querySnapshot = await firestore
              .collection('users')
              .where('username', isEqualTo: emailToUse.toLowerCase())
              .limit(1)
              .get();
          
          if (querySnapshot.docs.isEmpty) {
            throw 'No user found with this username.';
          }
          
          // Get the email from the user document
          final userDoc = querySnapshot.docs.first;
          emailToUse = userDoc.data()['email'] as String;
          print('✅ Found email: $emailToUse');
        } catch (e) {
          print('❌ Error looking up username: $e');
          throw 'Username not found or invalid.';
        }
      }
      
      final credential = await auth.signInWithEmailAndPassword(
        email: emailToUse,
        password: password,
      );
      
      if (credential.user != null) {
        print('Sign in successful: ${credential.user!.uid}');
        
        // Ensure user document exists - use set with merge to avoid errors
        try {
          final userDocRef = firestore.collection('users').doc(credential.user!.uid);
          final userDoc = await userDocRef.get();
          
          if (!userDoc.exists) {
            print('User document does not exist, creating...');
            // Create with set instead of update to avoid NOT_FOUND error
            await userDocRef.set({
              'uid': credential.user!.uid,
              'email': email.trim(),
              'displayName': credential.user!.displayName ?? email.split('@')[0],
              'username': _generateUsername(credential.user!.displayName ?? email.split('@')[0]),
              'bio': '',
              'profileImageUrl': '',
              'spotifyConnected': false,
              'totalSongsRated': 0,
              'totalAlbumsRated': 0,
              'totalReviews': 0,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
            print('User document created successfully');
          } else {
            // Update last login
            await userDocRef.update({
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        } catch (e) {
          print('Error checking/creating user document: $e');
          // Don't throw here, sign in is successful
        }
      }
      
      return credential;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Exception: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('Unexpected error in signInWithEmail: $e');
      if (e is String) {
        throw e;
      }
      throw 'An unexpected error occurred during sign in. Please try again.';
    }
  }
  
  static Future<void> signOut() async {
    await auth.signOut();
  }
  
  /// Check if username is available
  static Future<bool> isUsernameAvailable(String username, {String? excludeUserId}) async {
    try {
      final querySnapshot = await firestore
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        return true; // Username is available
      }
      
      // If excludeUserId is provided, check if the found user is the current user
      if (excludeUserId != null && querySnapshot.docs.first.id == excludeUserId) {
        return true; // Current user's own username
      }
      
      return false; // Username is taken
    } catch (e) {
      print('Error checking username availability: $e');
      return false; // Assume not available on error
    }
  }
  
  static Future<void> resetPassword(String email) async {
    try {
      await auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  // Firestore Methods
  static Future<void> createUserDocument({
    required String uid,
    required String email,
    required String displayName,
    required String username,
  }) async {
    try {
      final userDoc = firestore.collection('users').doc(uid);
      
      // Check if document already exists
      final docSnapshot = await userDoc.get();
      if (docSnapshot.exists) {
        print('ℹ️ User document already exists for uid: $uid');
        return;
      }
      
      print('📝 Creating user document with data:');
      print('   - displayName: $displayName');
      print('   - username: ${username.toLowerCase()}');
      print('   - email: $email');
      
      final userData = <String, dynamic>{
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'username': username.toLowerCase(),
        'bio': '',
        'profileImageUrl': '',
        'spotifyConnected': false,
        'totalSongsRated': 0,
        'totalAlbumsRated': 0,
        'totalReviews': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      await userDoc.set(userData);
      print('✅ User document created successfully in Firestore!');
    } catch (e) {
      print('❌ Error in createUserDocument: $e');
      // Rethrow to see what's going wrong
      rethrow;
    }
  }
  
  static Future<DocumentSnapshot> getUserDocument(String uid) async {
    return await firestore.collection('users').doc(uid).get();
  }
  
  static Future<void> updateUserDocument(String uid, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await firestore.collection('users').doc(uid).update(data);
  }
  
  static Future<void> createMusicRating({
    required String userId,
    required String spotifyId,
    required String type, // 'track' or 'album'
    required double rating,
    String? review,
    List<String>? tags,
  }) async {
    final ratingDoc = firestore.collection('music_ratings').doc();
    
    final ratingData = {
      'id': ratingDoc.id,
      'userId': userId,
      'spotifyId': spotifyId,
      'type': type,
      'rating': rating,
      'review': review ?? '',
      'tags': tags ?? [],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    
    await ratingDoc.set(ratingData);
    
    // Update user stats
    await _updateUserStats(userId, type);
  }
  
  static Future<QuerySnapshot> getUserRatings(String userId) async {
    return await firestore
        .collection('music_ratings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
  }
  
  static Future<QuerySnapshot> getRecentActivity(String userId) async {
    return await firestore
        .collection('music_ratings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .get();
  }
  
  // Helper Methods
  static String _generateUsername(String displayName) {
    final base = displayName.toLowerCase().replaceAll(' ', '');
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    return '$base$timestamp';
  }
  
  static Future<void> _updateUserStats(String userId, String type) async {
    final userDoc = firestore.collection('users').doc(userId);
    
    if (type == 'track') {
      await userDoc.update({
        'totalSongsRated': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else if (type == 'album') {
      await userDoc.update({
        'totalAlbumsRated': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }
  
  static String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'invalid-credential':
        return 'The email or password is incorrect.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Signing in with Email and Password is not enabled.';
      case 'network-request-failed':
        return 'Network connection error. Please check your connection.';
      default:
        return 'An error occurred: ${e.message ?? "Unknown error"}';
    }
  }
}
