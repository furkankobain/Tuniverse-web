import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/network_service.dart';
import '../../features/auth/domain/usecases/sign_in_usecase.dart';
import '../../features/auth/domain/usecases/sign_up_usecase.dart';
import '../../features/music/data/repositories/music_repository_impl.dart';
import '../../features/music/domain/repositories/music_repository.dart';
import '../../shared/services/firebase_service.dart';
import '../../shared/services/spotify_service.dart';

// Core Services
final networkServiceProvider = Provider<NetworkService>((ref) {
  return NetworkService();
});

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

final spotifyServiceProvider = Provider<SpotifyService>((ref) {
  return SpotifyService();
});

// Firebase Instances
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// Repositories
final musicRepositoryProvider = Provider<MusicRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  return MusicRepositoryImpl(firestore, auth);
});

// Use Cases
final signInUseCaseProvider = Provider<SignInUseCase>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return SignInUseCase(firebaseService);
});

final signUpUseCaseProvider = Provider<SignUpUseCase>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return SignUpUseCase(firebaseService);
});
