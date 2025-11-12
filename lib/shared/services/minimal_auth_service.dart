import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/utils/result.dart';

class MinimalAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Minimal sign up - sadece Firebase Auth
  static Future<Result<String>> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    try {
      if (kDebugMode) {
        print('MinimalAuthService: Starting sign up for $email');
      }

      // Create user with email and password
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user == null) {
        if (kDebugMode) {
          print('MinimalAuthService: User is null');
        }
        return Result.failure('Kullanıcı oluşturulamadı');
      }

      if (kDebugMode) {
        print('MinimalAuthService: User created successfully: ${user.uid}');
      }

      // Update display name
      await user.updateDisplayName(displayName);

      return Result.success(user.uid);
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('MinimalAuthService: FirebaseAuthException: ${e.code} - ${e.message}');
      }
      
      String message = 'Kayıt olurken bir hata oluştu';
      switch (e.code) {
        case 'weak-password':
          message = 'Şifre çok zayıf';
          break;
        case 'email-already-in-use':
          message = 'Bu e-posta adresi zaten kayıtlı';
          break;
        case 'invalid-email':
          message = 'Geçersiz e-posta adresi';
          break;
      }
      return Result.failure(message);
    } catch (e) {
      if (kDebugMode) {
        print('MinimalAuthService: Unexpected error: $e');
      }
      return Result.failure('Beklenmeyen bir hata oluştu');
    }
  }

  // Minimal sign in - sadece Firebase Auth
  static Future<Result<String>> signIn({
    required String emailOrUsername,
    required String password,
  }) async {
    try {
      if (kDebugMode) {
        print('MinimalAuthService: Starting sign in for $emailOrUsername');
      }

      String email = emailOrUsername;
      
      // Check if input is username (not email format)
      if (!emailOrUsername.contains('@')) {
        if (kDebugMode) {
          print('MinimalAuthService: Username detected, but Firestore disabled - treating as email');
        }
        // For minimal service, we'll treat it as email
        email = emailOrUsername;
      }

      // Sign in with email and password
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user == null) {
        if (kDebugMode) {
          print('MinimalAuthService: User is null after sign in');
        }
        return Result.failure('Giriş yapılamadı');
      }

      if (kDebugMode) {
        print('MinimalAuthService: Sign in successful: ${user.uid}');
      }

      return Result.success(user.uid);
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('MinimalAuthService: FirebaseAuthException: ${e.code} - ${e.message}');
      }
      
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
      if (kDebugMode) {
        print('MinimalAuthService: Unexpected error: $e');
      }
      return Result.failure('Beklenmeyen bir hata oluştu');
    }
  }

  // Password reset
  static Future<Result<void>> resetPassword(String email) async {
    try {
      if (kDebugMode) {
        print('MinimalAuthService: Starting password reset for $email');
      }

      await _auth.sendPasswordResetEmail(email: email);
      
      if (kDebugMode) {
        print('MinimalAuthService: Password reset email sent');
      }
      
      return Result.success(null);
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('MinimalAuthService: FirebaseAuthException: ${e.code} - ${e.message}');
      }
      
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
      if (kDebugMode) {
        print('MinimalAuthService: Unexpected error: $e');
      }
      return Result.failure('Beklenmeyen bir hata oluştu');
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      if (kDebugMode) {
        print('MinimalAuthService: Signing out');
      }
      await _auth.signOut();
      if (kDebugMode) {
        print('MinimalAuthService: Sign out successful');
      }
    } catch (e) {
      if (kDebugMode) {
        print('MinimalAuthService: Sign out error: $e');
      }
    }
  }

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  static Stream<User?> get authStateChanges => _auth.authStateChanges();
}
