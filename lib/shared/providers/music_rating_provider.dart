import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/music_rating.dart';
import '../services/music_rating_service.dart';

// User ratings stream provider
final userRatingsProvider = StreamProvider<List<MusicRating>>((ref) {
  return Stream.periodic(const Duration(seconds: 30)).asyncMap((_) async {
    return await MusicRatingService.getUserRatings();
  });
});

// Rating for specific track provider
final trackRatingProvider = FutureProvider.family<MusicRating?, String>((ref, trackId) async {
  return await MusicRatingService.getRatingByTrackId(trackId);
});

// User rating statistics provider
final userRatingStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return await MusicRatingService.getUserRatingStats();
});

// Recent ratings provider (last 7 days)
final recentRatingsProvider = FutureProvider<List<MusicRating>>((ref) async {
  return await MusicRatingService.getRecentRatings();
});

// Ratings by rating value provider
final ratingsByRatingProvider = FutureProvider.family<List<MusicRating>, int>((ref, rating) async {
  return await MusicRatingService.getRatingsByRating(rating);
});

// Search ratings provider
final searchRatingsProvider = FutureProvider.family<List<MusicRating>, String>((ref, query) async {
  if (query.isEmpty) return [];
  return await MusicRatingService.searchRatings(query);
});

// Rating service provider
final musicRatingServiceProvider = Provider<MusicRatingService>((ref) {
  return MusicRatingService();
});

// Rating loading state provider
final ratingLoadingProvider = StateProvider<bool>((ref) => false);

// Rating error provider
final ratingErrorProvider = StateProvider<String?>((ref) => null);
