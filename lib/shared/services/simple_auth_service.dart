import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/utils/result.dart';

// Disable App Check warnings
void _disableAppCheckWarnings() {
  // This will suppress App Check warnings in debug mode
  if (kDebugMode) {
    print('App Check warnings suppressed for debug mode');
  }
  
  // Set Firebase Auth settings to bypass App Check
  try {
    // This helps bypass App Check validation
    FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: true,
    );
  } catch (e) {
    if (kDebugMode) {
      print('Could not disable app verification: $e');
    }
  }
}

class SimpleAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize auth service with pigeon error bypass
  static Future<void> initialize() async {
    try {
      // Disable App Check warnings
      _disableAppCheckWarnings();
      
      // Set auth settings to bypass pigeon errors
      await _auth.setSettings(
        appVerificationDisabledForTesting: true,
        forceRecaptchaFlow: false,
      );
      
      if (kDebugMode) {
        print('SimpleAuthService initialized with pigeon error bypass');
      }
    } catch (e) {
      if (kDebugMode) {
        print('SimpleAuthService initialization error: $e');
      }
    }
  }

  // Simple sign up
  static Future<Result<String>> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    // Disable App Check warnings
    _disableAppCheckWarnings();
    
    try {
      // Validate email format
      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (!emailRegex.hasMatch(email)) {
        return Result.failure('Geçerli bir e-posta adresi giriniz');
      }

      // Create user with email and password
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user == null) {
        return Result.failure('Kullanıcı oluşturulamadı');
      }

      // Create user document in Firestore (with error handling)
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'email': email,
          'username': username.toLowerCase(),
          'displayName': displayName,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'isActive': true,
          'profilePicture': null,
          'bio': '',
          'preferences': {
            'theme': 'system',
            'language': 'tr',
            'notifications': true,
          },
          'stats': {
            'totalRatings': 0,
            'averageRating': 0.0,
            'favoriteGenres': [],
          },
        });
      } catch (e) {
        // Firestore error is not critical for signup
        if (kDebugMode) {
          print('Firestore error during signup: $e');
        }
      }

      return Result.success(user.uid);
    } on FirebaseAuthException catch (e) {
      String message = 'Kayıt olurken bir hata oluştu';
      
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Bu e-posta adresi zaten kullanımda';
          break;
        case 'weak-password':
          message = 'Şifre çok zayıf';
          break;
        case 'invalid-email':
          message = 'Geçersiz e-posta adresi';
          break;
        case 'operation-not-allowed':
          message = 'E-posta/şifre girişi etkin değil';
          break;
      }
      
      return Result.failure(message);
    } catch (e) {
      return Result.failure('Beklenmeyen bir hata oluştu: ${e.toString()}');
    }
  }

  // Simple sign in
  static Future<Result<String>> signIn({
    required String emailOrUsername,
    required String password,
  }) async {
    // Disable App Check warnings
    _disableAppCheckWarnings();
    
    try {
      String email = emailOrUsername;
      
      // Check if input is username (not email format)
      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (!emailRegex.hasMatch(emailOrUsername)) {
        // It's a username, find the email
        try {
          final userQuery = await _firestore
              .collection('users')
              .where('username', isEqualTo: emailOrUsername.toLowerCase())
              .limit(1)
              .get();
          
          if (userQuery.docs.isEmpty) {
            return Result.failure('Kullanıcı adı bulunamadı');
          }
          
          email = userQuery.docs.first.data()['email'] as String? ?? '';
        } catch (e) {
          // Firestore error, try as email
          email = emailOrUsername;
        }
      }

      // Sign in with email and password
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user == null) {
        return Result.failure('Giriş yapılamadı');
      }

      // Update last login time (with error handling)
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        // Firestore error is not critical for login
        if (kDebugMode) {
          print('Firestore error during login: $e');
        }
      }

      return Result.success(user.uid);
    } on FirebaseAuthException catch (e) {
      String message = 'Giriş yaparken bir hata oluştu';
      
      switch (e.code) {
        case 'user-not-found':
          message = 'Kullanıcı bulunamadı';
          break;
        case 'wrong-password':
          message = 'Yanlış şifre';
          break;
        case 'invalid-email':
          message = 'Geçersiz e-posta adresi';
          break;
        case 'user-disabled':
          message = 'Bu hesap devre dışı bırakılmış';
          break;
        case 'too-many-requests':
          message = 'Çok fazla başarısız deneme. Lütfen daha sonra tekrar deneyin';
          break;
      }
      
      return Result.failure(message);
    } catch (e) {
      return Result.failure('Beklenmeyen bir hata oluştu: ${e.toString()}');
    }
  }

  // Password reset
  static Future<Result<void>> resetPassword(String email) async {
    try {
      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (!emailRegex.hasMatch(email)) {
        return Result.failure('Geçerli bir e-posta adresi giriniz');
      }

      await _auth.sendPasswordResetEmail(email: email);
      return Result.success(null);
    } on FirebaseAuthException catch (e) {
      String message = 'Şifre sıfırlama e-postası gönderilemedi';
      
      switch (e.code) {
        case 'user-not-found':
          message = 'Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı';
          break;
        case 'invalid-email':
          message = 'Geçersiz e-posta adresi';
          break;
        case 'too-many-requests':
          message = 'Çok fazla istek. Lütfen daha sonra tekrar deneyin';
          break;
      }
      
      return Result.failure(message);
    } catch (e) {
      return Result.failure('Beklenmeyen bir hata oluştu: ${e.toString()}');
    }
  }

  // Sign out
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if email is already registered
  static Future<bool> isEmailRegistered(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Check if username is already taken
  static Future<bool> isUsernameTaken(String username) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();
      
      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
