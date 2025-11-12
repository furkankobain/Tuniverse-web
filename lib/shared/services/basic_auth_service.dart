import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/utils/result.dart';

class BasicAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Basic sign up with minimal validation
  static Future<Result<String>> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    try {
      // Minimal validation
      if (email.isEmpty || password.isEmpty || username.isEmpty || displayName.isEmpty) {
        return Result.failure('Tüm alanları doldurunuz');
      }

      if (password.length < 6) {
        return Result.failure('Şifre en az 6 karakter olmalı');
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

      // Update display name
      await user.updateDisplayName(displayName);

      // Firestore disabled for basic auth - only Firebase Auth

      // Send email verification (optional)
      try {
        await user.sendEmailVerification();
      } catch (e) {
        if (kDebugMode) {
          print('Email verification error: $e');
        }
        // Continue even if email verification fails
      }

      return Result.success(user.uid);
    } on FirebaseAuthException catch (e) {
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
      return Result.failure('Beklenmeyen bir hata oluştu');
    }
  }

  // Basic sign in
  static Future<Result<String>> signIn({
    required String emailOrUsername,
    required String password,
  }) async {
    try {
      if (emailOrUsername.isEmpty || password.isEmpty) {
        return Result.failure('E-posta ve şifre gerekli');
      }

      String email = emailOrUsername;
      
      // For basic auth, we'll only support email login
      if (!emailOrUsername.contains('@')) {
        return Result.failure('Lütfen e-posta adresinizi kullanın');
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

      // Firestore disabled for basic auth

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
      return Result.failure('Beklenmeyen bir hata oluştu');
    }
  }

  // Password reset
  static Future<Result<void>> resetPassword(String email) async {
    try {
      if (email.isEmpty) {
        return Result.failure('E-posta adresi gerekli');
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
      return Result.failure('Beklenmeyen bir hata oluştu');
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
}
