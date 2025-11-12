import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/spotify_service.dart';

// Spotify Connection State Provider
final spotifyConnectionProvider = StateProvider<bool>((ref) => SpotifyService.isConnected);

// Current Track Provider
final currentTrackProvider = StreamProvider<Map<String, dynamic>?>((ref) async* {
  while (true) {
    if (ref.read(spotifyConnectionProvider)) {
      final track = await SpotifyService.getCurrentTrack();
      yield track;
    } else {
      yield null;
    }
    await Future.delayed(const Duration(seconds: 2));
  }
});

// Spotify Authentication State Provider (legacy)
final spotifyAuthProvider = FutureProvider<bool>((ref) async {
  return await SpotifyService.isAuthenticated();
});

// Recently Played Tracks Provider
final recentlyPlayedProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final isAuth = await ref.watch(spotifyAuthProvider.future);
  if (isAuth) {
    return await SpotifyService.getRecentlyPlayed();
  }
  return [];
});

// Top Tracks Provider
final topTracksProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final isAuth = await ref.watch(spotifyAuthProvider.future);
  if (isAuth) {
    return await SpotifyService.getTopTracks();
  }
  return [];
});

// Saved Albums Provider
final savedAlbumsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final isAuth = await ref.watch(spotifyAuthProvider.future);
  if (isAuth) {
    return await SpotifyService.getSavedAlbums();
  }
  return [];
});

// Track Details Provider
final trackDetailsProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, trackId) async {
  final isAuth = await ref.watch(spotifyAuthProvider.future);
  if (isAuth) {
    return await SpotifyService.getTrackDetails(trackId);
  }
  return null;
});

// Spotify Service Provider
final spotifyServiceProvider = Provider<SpotifyService>((ref) {
  return SpotifyService();
});

// Spotify Loading State Provider
final spotifyLoadingProvider = StateProvider<bool>((ref) => false);

// Spotify Error Provider
final spotifyErrorProvider = StateProvider<String?>((ref) => null);
