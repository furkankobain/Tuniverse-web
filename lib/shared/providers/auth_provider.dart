import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firebase_service.dart';

// Auth State Provider
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseService.auth.authStateChanges();
});

// Current User Provider
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});

// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Auth Service Class
class AuthService {
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      return await FirebaseService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await FirebaseService.signInWithEmail(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await FirebaseService.signOut();
  }

  Future<void> resetPassword(String email) async {
    await FirebaseService.resetPassword(email);
  }

  Future<DocumentSnapshot> getUserData(String uid) async {
    return await FirebaseService.getUserDocument(uid);
  }
}

// User Data Provider
final userDataProvider = FutureProvider.family<DocumentSnapshot?, String>((ref, uid) async {
  if (uid.isEmpty) return null;
  try {
    return await FirebaseService.getUserDocument(uid);
  } catch (e) {
    return null;
  }
});

// Auth Loading Provider
final authLoadingProvider = StateProvider<bool>((ref) => false);

// Auth Error Provider
final authErrorProvider = StateProvider<String?>((ref) => null);
