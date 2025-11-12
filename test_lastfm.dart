import 'lib/shared/services/lastfm_service.dart';

void main() async {
  print('🎵 Testing Last.fm API...\n');

  // Test 1: Get track info
  print('📀 Test 1: Getting track info...');
  final trackInfo = await LastFmService.getTrackInfo(
    artist: 'Daft Punk',
    track: 'Get Lucky',
  );
  
  if (trackInfo != null) {
    print('✅ Track: ${trackInfo['name']}');
    print('✅ Artist: ${trackInfo['artist']}');
    print('✅ Playcount: ${trackInfo['playcount']}');
    print('✅ Listeners: ${trackInfo['listeners']}');
    
    final rating = LastFmService.calculateRating(
      playcount: trackInfo['playcount'],
      listeners: trackInfo['listeners'],
    );
    print('✅ Calculated Rating: ${rating.toStringAsFixed(1)}/10\n');
  } else {
    print('❌ Failed to get track info\n');
  }

  // Test 2: Get similar tracks
  print('🔍 Test 2: Getting similar tracks...');
  final similarTracks = await LastFmService.getSimilarTracks(
    artist: 'The Weeknd',
    track: 'Blinding Lights',
    limit: 5,
  );
  
  if (similarTracks.isNotEmpty) {
    print('✅ Found ${similarTracks.length} similar tracks:');
    for (final track in similarTracks) {
      print('   - ${track['name']} by ${track['artist']}');
    }
    print('');
  } else {
    print('❌ Failed to get similar tracks\n');
  }

  // Test 3: Get top tracks
  print('🔥 Test 3: Getting global top tracks...');
  final topTracks = await LastFmService.getTopTracks(limit: 5);
  
  if (topTracks.isNotEmpty) {
    print('✅ Top ${topTracks.length} tracks:');
    for (final track in topTracks) {
      print('   ${track['name']} - ${track['artist']} (${track['playcount']} plays)');
    }
    print('');
  } else {
    print('❌ Failed to get top tracks\n');
  }

  print('🎉 Last.fm API test completed!');
}
