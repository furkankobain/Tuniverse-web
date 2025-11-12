import 'lib/shared/services/rating_aggregation_service.dart';
import 'lib/shared/services/lastfm_service.dart';

void main() async {
  print('🎵 Testing Rating Aggregation System\n');

  // Test track: Daft Punk - Get Lucky
  final testTrack = {
    'id': '69kOkLUCkxIZYexIgSG8rq',
    'name': 'Get Lucky (feat. Pharrell Williams)',
    'artist': 'Daft Punk',
    'popularity': 82, // Spotify popularity (0-100)
  };

  print('📀 Track: ${testTrack['name']}');
  print('🎤 Artist: ${testTrack['artist']}');
  print('📊 Spotify Popularity: ${testTrack['popularity']}/100\n');

  // 1. Last.fm Data
  print('═══ Last.fm Data ═══');
  final lastFmData = await LastFmService.getTrackInfo(
    artist: testTrack['artist']!,
    track: testTrack['name']!,
  );

  if (lastFmData != null) {
    final playcount = lastFmData['playcount'] as int;
    final listeners = lastFmData['listeners'] as int;
    
    print('▶ Playcount: ${_formatNumber(playcount)}');
    print('👥 Listeners: ${_formatNumber(listeners)}');
    
    final lastFmRating = LastFmService.calculateRating(
      playcount: playcount,
      listeners: listeners,
    );
    print('⭐ Last.fm Score: ${lastFmRating.toStringAsFixed(2)}/10\n');
  } else {
    print('❌ Last.fm data not available\n');
  }

  // 2. Aggregated Rating
  print('═══ Aggregated Rating ═══');
  final aggregatedRating = await RatingAggregationService.getAggregatedRating(
    trackId: testTrack['id']!,
    trackName: testTrack['name']!,
    artistName: testTrack['artist']!,
    spotifyPopularity: testTrack['popularity'] as int,
  );

  if (aggregatedRating != null) {
    print('🎯 Overall Score: ${aggregatedRating.displayRating}/10');
    print('📊 Sources: ${aggregatedRating.sources.join(", ")}');
    print('🔍 Confidence: ${aggregatedRating.confidenceLevel}');
    print('');
    print('Breakdown:');
    if (aggregatedRating.spotifyScore != null) {
      print('  • Spotify: ${aggregatedRating.spotifyScore!.toStringAsFixed(1)}/10');
    }
    if (aggregatedRating.lastFmScore != null) {
      print('  • Last.fm: ${aggregatedRating.lastFmScore!.toStringAsFixed(1)}/10');
    }
    if (aggregatedRating.appScore != null) {
      print('  • Community: ${aggregatedRating.appScore!.toStringAsFixed(1)}/10 (${aggregatedRating.appRatingCount} ratings)');
    }
    print('');
  } else {
    print('❌ Aggregated rating not available\n');
  }

  // 3. Algorithm Explanation
  print('═══ Rating Algorithm ═══');
  print('Weights:');
  print('  • Spotify Popularity: 30%');
  print('  • Last.fm (playcount + listeners): 40%');
  print('  • App User Ratings: 30-70% (dynamic based on count)');
  print('');
  print('Last.fm Calculation:');
  print('  • Uses logarithmic scale for playcount and listeners');
  print('  • Considers engagement (avg plays per listener)');
  print('  • Formula: 40% playcount + 40% listeners + 20% engagement');
  print('');

  print('✅ Test completed!');
}

String _formatNumber(int number) {
  if (number >= 1000000) {
    return '${(number / 1000000).toStringAsFixed(1)}M';
  } else if (number >= 1000) {
    return '${(number / 1000).toStringAsFixed(1)}K';
  }
  return number.toString();
}
