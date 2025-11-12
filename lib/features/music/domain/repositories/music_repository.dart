import '../../../../core/utils/result.dart';
import '../../../../shared/models/music_rating.dart';

abstract class MusicRepository {
  Future<Result<String>> saveRating({
    required String trackId,
    required String trackName,
    required String artists,
    required String albumName,
    String? albumImage,
    required int rating,
    String? review,
    List<String>? tags,
  });
  
  Future<Result<MusicRating?>> getRatingByTrackId(String trackId);
  
  Future<Result<List<MusicRating>>> getUserRatings({
    int limit = 20,
    String? startAfter,
  });
  
  Future<Result<List<MusicRating>>> getRatingsByRating(int rating);
  
  Future<Result<bool>> deleteRating(String ratingId);
  
  Future<Result<Map<String, dynamic>>> getUserRatingStats();
  
  Future<Result<List<MusicRating>>> searchRatings(String query);
  
  Future<Result<List<MusicRating>>> getRecentRatings();
}
