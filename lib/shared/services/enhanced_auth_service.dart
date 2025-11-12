import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/utils/result.dart';
import 'smart_notification_service.dart';

class EnhancedAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  // Enhanced sign up with validation
  static Future<Result<String>> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    try {
      // Validate email format
      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (!emailRegex.hasMatch(email)) {
        return Result.failure('Geçerli bir e-posta adresi giriniz');
      }

      // Check if email is already registered
      if (await isEmailRegistered(email)) {
        return Result.failure('Bu e-posta adresi zaten kayıtlı');
      }

      // Check if username is already taken
      if (await isUsernameTaken(username)) {
        return Result.failure('Bu kullanıcı adı zaten alınmış');
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

      // Create user document in Firestore (displayName will be stored here)
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

      // Send email verification
      await user.sendEmailVerification();

      return Result.success(user.uid);
    } on FirebaseAuthException catch (e) {
      String message = 'Kayıt olurken bir hata oluştu';
      
      switch (e.code) {
        case 'weak-password':
          message = 'Şifre çok zayıf. Lütfen daha güçlü bir şifre seçin';
          break;
        case 'email-already-in-use':
          message = 'Bu e-posta adresi zaten kullanımda';
          break;
        case 'invalid-email':
          message = 'Geçersiz e-posta adresi';
          break;
        case 'operation-not-allowed':
          message = 'Bu işlem şu anda izin verilmiyor';
          break;
      }
      
      return Result.failure(message);
    } catch (e) {
      return Result.failure('Beklenmeyen bir hata oluştu: ${e.toString()}');
    }
  }

  // Enhanced sign in with email or username
  static Future<Result<String>> signIn({
    required String emailOrUsername,
    required String password,
  }) async {
    try {
      String email = emailOrUsername;
      
      // Check if input is username (not email format)
      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (!emailRegex.hasMatch(emailOrUsername)) {
        // It's a username, find the email
        final userQuery = await _firestore
            .collection('users')
            .where('username', isEqualTo: emailOrUsername.toLowerCase())
            .limit(1)
            .get();
        
        if (userQuery.docs.isEmpty) {
          return Result.failure('Kullanıcı adı bulunamadı');
        }
        
        email = userQuery.docs.first.data()['email'];
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
        // Ignore Firestore update errors for login
        if (kDebugMode) {
          print('Firestore update error during login: $e');
        }
      }

      // Start smart notifications after successful login
      try {
        await SmartNotificationService.startForAuthenticatedUser(user.uid);
      } catch (e) {
        // Ignore notification service errors for login
        if (kDebugMode) {
          print('Notification service error during login: $e');
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

  // Google Sign In method completely removed

  // Spotify Sign In (if needed)
  static Future<Result<String>> signInWithSpotify() async {
    try {
      // This would integrate with Spotify OAuth
      // For now, return a placeholder
      return Result.failure('Spotify girişi henüz desteklenmiyor');
    } catch (e) {
      return Result.failure('Spotify girişi sırasında hata: ${e.toString()}');
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

  // Change password
  static Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Result.failure('Kullanıcı giriş yapmamış');
      }

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      
      await user.reauthenticateWithCredential(credential);
      
      // Update password
      await user.updatePassword(newPassword);
      
      return Result.success(null);
    } on FirebaseAuthException catch (e) {
      String message = 'Şifre değiştirilemedi';
      
      switch (e.code) {
        case 'wrong-password':
          message = 'Mevcut şifre yanlış';
          break;
        case 'weak-password':
          message = 'Yeni şifre çok zayıf';
          break;
        case 'requires-recent-login':
          message = 'Bu işlem için tekrar giriş yapmanız gerekiyor';
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

  // Helper function to generate username from email
  static String _generateUsernameFromEmail(String email) {
    final username = email.split('@')[0];
    final cleanUsername = username.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    return cleanUsername.toLowerCase();
  }

  // Check if user exists by email or username
  static Future<bool> userExists(String emailOrUsername) async {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    
    if (emailRegex.hasMatch(emailOrUsername)) {
      return await isEmailRegistered(emailOrUsername);
    } else {
      return await isUsernameTaken(emailOrUsername);
    }
  }
}
