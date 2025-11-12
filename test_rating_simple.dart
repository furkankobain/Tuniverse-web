import 'dart:math' as math;

void main() {
  print('🎵 Testing Rating Aggregation System\n');

  // Test track: Daft Punk - Get Lucky
  final testTrack = {
    'name': 'Get Lucky (feat. Pharrell Williams)',
    'artist': 'Daft Punk',
    'spotifyPopularity': 82, // 0-100
    'lastFmPlaycount': 157000000,
    'lastFmListeners': 2500000,
  };

  print('📀 Track: ${testTrack['name']}');
  print('🎤 Artist: ${testTrack['artist']}\n');

  // 1. Spotify Score
  print('═══ Spotify Score ═══');
  final spotifyScore = (testTrack['spotifyPopularity']! as int) / 10.0;
  print('📊 Popularity: ${testTrack['spotifyPopularity']}/100');
  print('⭐ Score: ${spotifyScore.toStringAsFixed(1)}/10\n');

  // 2. Last.fm Score
  print('═══ Last.fm Score ═══');
  final playcount = testTrack['lastFmPlaycount']! as int;
  final listeners = testTrack['lastFmListeners']! as int;
  
  print('▶ Playcount: ${_formatNumber(playcount)}');
  print('👥 Listeners: ${_formatNumber(listeners)}');
  
  final lastFmScore = _calculateLastFmRating(playcount, listeners);
  print('⭐ Score: ${lastFmScore.toStringAsFixed(1)}/10');
  print('📈 Calculation: Logarithmic scale with engagement factor\n');

  // 3. Mock App Score
  print('═══ App Score (Simulated) ═══');
  final appRatings = [5, 4, 5, 5, 4, 5, 4, 5]; // Mock ratings (0-5 scale)
  final appScore = (appRatings.reduce((a, b) => a + b) / appRatings.length) * 2.0;
  print('📊 User Ratings: ${appRatings.length}');
  print('⭐ Average: ${(appScore / 2).toStringAsFixed(2)}/5');
  print('⭐ Score: ${appScore.toStringAsFixed(1)}/10\n');

  // 4. Aggregated Rating
  print('═══ Aggregated Rating ═══');
  final overall = _calculateWeightedAverage(
    spotifyScore: spotifyScore,
    lastFmScore: lastFmScore,
    appScore: appScore,
    appRatingCount: appRatings.length,
  );
  
  print('🎯 Overall Score: ${overall.toStringAsFixed(1)}/10');
  print('📊 Sources: Spotify, Last.fm, Community');
  print('🔍 Confidence: High (3 sources)\n');
  
  print('Breakdown:');
  print('  • Spotify: ${spotifyScore.toStringAsFixed(1)}/10 (weight: 30%)');
  print('  • Last.fm: ${lastFmScore.toStringAsFixed(1)}/10 (weight: 40%)');
  print('  • Community: ${appScore.toStringAsFixed(1)}/10 (weight: 50% - ${appRatings.length} ratings)\n');

  // 5. Algorithm Explanation
  print('═══ Rating Algorithm ═══');
  print('Weights:');
  print('  • Spotify Popularity: 30%');
  print('  • Last.fm (playcount + listeners): 40%');
  print('  • App User Ratings: 30-70% (dynamic based on count)');
  print('    - 10+ ratings = 70% weight');
  print('    - 5-9 ratings = 50% weight');
  print('    - 1-4 ratings = 30% weight');
  print('');
  print('Last.fm Calculation:');
  print('  • Uses logarithmic scale for playcount and listeners');
  print('  • Considers engagement (avg plays per listener)');
  print('  • Formula: 40% playcount + 40% listeners + 20% engagement');
  print('  • Max values: 1B playcount, 100M listeners for scaling');
  print('');

  print('✅ Test completed!');
}

/// Calculate Last.fm rating (0-10 scale)
double _calculateLastFmRating(int playcount, int listeners) {
  // Use logarithmic scale since playcount/listeners can be very large
  const maxPlaycount = 1000000000; // 1 billion
  const maxListeners = 100000000;  // 100 million
  
  // Logarithmic scores (0-10 scale)
  final playcountScore = playcount > 0
      ? (math.log(playcount) / math.log(maxPlaycount)) * 10
      : 0.0;
  
  final listenersScore = listeners > 0
      ? (math.log(listeners) / math.log(maxListeners)) * 10
      : 0.0;
  
  // Calculate engagement (average plays per listener)
  final avgPlaysPerListener = listeners > 0 
      ? (playcount / listeners).clamp(1.0, 100.0)
      : 1.0;
  
  // Engagement score (1-100 plays normalized to 0-10)
  final engagementScore = (math.log(avgPlaysPerListener) / math.log(100)) * 10;
  
  // Weighted combination: 40% playcount, 40% listeners, 20% engagement
  final rating = (playcountScore * 0.4) + 
                 (listenersScore * 0.4) + 
                 (engagementScore * 0.2);
  
  return rating.clamp(0, 10);
}

/// Calculate weighted average of all scores
double _calculateWeightedAverage({
  required double spotifyScore,
  required double lastFmScore,
  required double appScore,
  required int appRatingCount,
}) {
  double totalWeight = 0.0;
  double weightedSum = 0.0;

  // Spotify weight: 30%
  const spotifyWeight = 0.3;
  weightedSum += spotifyScore * spotifyWeight;
  totalWeight += spotifyWeight;

  // Last.fm weight: 40%
  const lastFmWeight = 0.4;
  weightedSum += lastFmScore * lastFmWeight;
  totalWeight += lastFmWeight;

  // App score weight: dynamic (30-70% based on rating count)
  double appWeight;
  if (appRatingCount >= 10) {
    appWeight = 0.7;
  } else if (appRatingCount >= 5) {
    appWeight = 0.5;
  } else {
    appWeight = 0.3;
  }
  
  weightedSum += appScore * appWeight;
  totalWeight += appWeight;

  // Normalize
  final normalized = weightedSum / totalWeight;
  return normalized.clamp(0, 10);
}

String _formatNumber(int number) {
  if (number >= 1000000) {
    return '${(number / 1000000).toStringAsFixed(1)}M';
  } else if (number >= 1000) {
    return '${(number / 1000).toStringAsFixed(1)}K';
  }
  return number.toString();
}
