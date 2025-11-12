import 'enhanced_spotify_service.dart';

/// Music exploration service - Decade Explorer, Genre Deep Dive
class MusicExplorationService {
  // ==================== DECADE EXPLORER ====================
  
  /// Explore music by decade
  static Future<Map<String, dynamic>> exploreByDecade(String decade) async {
    final tracks = await getDecadeTracks(decade);
    final info = getDecadeInfo(decade);
    
    return {
      'decade': decade,
      'info': info,
      'tracks': tracks,
    };
  }

  /// Get tracks from a specific decade
  static Future<List<Map<String, dynamic>>> getDecadeTracks(String decade, {int limit = 50}) async {
    try {
      int startYear, endYear;
      
      switch (decade) {
        case '60s':
          startYear = 1960;
          endYear = 1969;
          break;
        case '70s':
          startYear = 1970;
          endYear = 1979;
          break;
        case '80s':
          startYear = 1980;
          endYear = 1989;
          break;
        case '90s':
          startYear = 1990;
          endYear = 1999;
          break;
        case '2000s':
          startYear = 2000;
          endYear = 2009;
          break;
        case '2010s':
          startYear = 2010;
          endYear = 2019;
          break;
        case '2020s':
          startYear = 2020;
          endYear = 2029;
          break;
        default:
          return [];
      }
      
      // Search for popular tracks from that decade
      final query = 'year:$startYear-$endYear';
      final tracks = await EnhancedSpotifyService.searchTracks(query, limit: limit);
      
      return tracks;
    } catch (e) {
      print('Error getting decade tracks: $e');
      return [];
    }
  }

  /// Get decade statistics and highlights
  static Map<String, dynamic> getDecadeInfo(String decade) {
    final info = <String, dynamic>{};
    
    switch (decade) {
      case '60s':
        info['title'] = 'The Swinging Sixties';
        info['description'] = 'Rock \'n\' roll, Motown, British Invasion';
        info['genres'] = ['Rock', 'Soul', 'Pop', 'Folk'];
        info['iconicArtists'] = ['The Beatles', 'The Rolling Stones', 'Bob Dylan', 'The Beach Boys'];
        break;
      case '70s':
        info['title'] = 'The Groovy Seventies';
        info['description'] = 'Disco, punk rock, funk, and classic rock';
        info['genres'] = ['Disco', 'Punk', 'Funk', 'Rock'];
        info['iconicArtists'] = ['Led Zeppelin', 'Pink Floyd', 'Queen', 'David Bowie'];
        break;
      case '80s':
        info['title'] = 'The Radical Eighties';
        info['description'] = 'MTV era, synth-pop, new wave, and hip-hop birth';
        info['genres'] = ['Synth-pop', 'New Wave', 'Hair Metal', 'Hip Hop'];
        info['iconicArtists'] = ['Michael Jackson', 'Madonna', 'Prince', 'U2'];
        break;
      case '90s':
        info['title'] = 'The Alternative Nineties';
        info['description'] = 'Grunge, hip-hop golden age, Britpop, and R&B';
        info['genres'] = ['Grunge', 'Hip Hop', 'Britpop', 'R&B'];
        info['iconicArtists'] = ['Nirvana', 'Tupac', 'Oasis', 'Mariah Carey'];
        break;
      case '2000s':
        info['title'] = 'The Digital 2000s';
        info['description'] = 'Pop-punk, emo, crunk, and indie rock';
        info['genres'] = ['Pop Punk', 'Emo', 'Indie Rock', 'Crunk'];
        info['iconicArtists'] = ['Eminem', 'Beyoncé', 'Green Day', 'The Strokes'];
        break;
      case '2010s':
        info['title'] = 'The Streaming 2010s';
        info['description'] = 'EDM, trap, indie pop, and streaming dominance';
        info['genres'] = ['EDM', 'Trap', 'Indie Pop', 'K-Pop'];
        info['iconicArtists'] = ['Drake', 'Taylor Swift', 'Adele', 'The Weeknd'];
        break;
      case '2020s':
        info['title'] = 'The Modern 2020s';
        info['description'] = 'TikTok virality, hyperpop, and genre-blending';
        info['genres'] = ['Hyperpop', 'Drill', 'Alt-Pop', 'Afrobeats'];
        info['iconicArtists'] = ['Billie Eilish', 'Olivia Rodrigo', 'Bad Bunny', 'Doja Cat'];
        break;
      default:
        info['title'] = 'Unknown Decade';
        info['description'] = '';
        info['genres'] = [];
        info['iconicArtists'] = [];
    }
    
    return info;
  }

  /// Get all decades
  static List<String> getAllDecades() {
    return ['60s', '70s', '80s', '90s', '2000s', '2010s', '2020s'];
  }

  // ==================== GENRE DEEP DIVE ====================
  
  /// Explore music by genre
  static Future<Map<String, dynamic>> exploreByGenre(String genre) async {
    return await getGenreDeepDive(genre);
  }

  /// Get detailed genre exploration data
  static Future<Map<String, dynamic>> getGenreDeepDive(String genre) async {
    try {
      final data = <String, dynamic>{};
      
      // Get genre info
      data['info'] = _getGenreInfo(genre);
      
      // Get top tracks in genre
      data['topTracks'] = await EnhancedSpotifyService.searchTracks(
        'genre:$genre',
        limit: 30,
      );
      
      // Get top artists in genre
      data['topArtists'] = await EnhancedSpotifyService.searchArtists(
        'genre:$genre',
        limit: 20,
      );
      
      // Get related genres
      data['relatedGenres'] = _getRelatedGenres(genre);
      
      // Get genre characteristics
      data['characteristics'] = _getGenreCharacteristics(genre);
      
      return data;
    } catch (e) {
      print('Error getting genre deep dive: $e');
      return {};
    }
  }

  /// Get genre information
  static Map<String, String> _getGenreInfo(String genre) {
    final genreInfo = <String, String>{};
    
    switch (genre.toLowerCase()) {
      case 'rock':
        genreInfo['description'] = 'Characterized by electric guitars, drums, and strong beats';
        genreInfo['origin'] = '1950s, United States';
        genreInfo['subgenres'] = 'Alternative, Punk, Metal, Indie, Progressive';
        break;
      case 'pop':
        genreInfo['description'] = 'Popular music with catchy melodies and mainstream appeal';
        genreInfo['origin'] = '1950s, United Kingdom & United States';
        genreInfo['subgenres'] = 'Synth-pop, Dance-pop, Teen pop, Electropop';
        break;
      case 'hip hop':
      case 'rap':
        genreInfo['description'] = 'Rhythmic music with rapping, DJing, and sampling';
        genreInfo['origin'] = '1970s, Bronx, New York City';
        genreInfo['subgenres'] = 'Trap, Drill, Conscious, Gangsta, Alternative';
        break;
      case 'electronic':
      case 'edm':
        genreInfo['description'] = 'Music produced with electronic instruments and technology';
        genreInfo['origin'] = '1970s-1980s, Various';
        genreInfo['subgenres'] = 'House, Techno, Trance, Dubstep, Drum and Bass';
        break;
      case 'jazz':
        genreInfo['description'] = 'Improvisational music with swing and blue notes';
        genreInfo['origin'] = 'Late 1800s-early 1900s, New Orleans';
        genreInfo['subgenres'] = 'Bebop, Cool Jazz, Free Jazz, Fusion, Smooth';
        break;
      case 'classical':
        genreInfo['description'] = 'Art music tradition of Western culture';
        genreInfo['origin'] = 'Medieval period onwards, Europe';
        genreInfo['subgenres'] = 'Baroque, Romantic, Contemporary, Chamber';
        break;
      case 'r&b':
      case 'soul':
        genreInfo['description'] = 'Rhythm and blues with soulful vocals';
        genreInfo['origin'] = '1940s-1950s, African American communities';
        genreInfo['subgenres'] = 'Contemporary R&B, Neo-soul, Funk';
        break;
      case 'country':
        genreInfo['description'] = 'Folk music from rural Southern United States';
        genreInfo['origin'] = '1920s, Southern United States';
        genreInfo['subgenres'] = 'Country Pop, Outlaw, Bluegrass, Alt-Country';
        break;
      default:
        genreInfo['description'] = 'Explore the unique sounds of $genre';
        genreInfo['origin'] = 'Various';
        genreInfo['subgenres'] = 'Multiple subgenres';
    }
    
    return genreInfo;
  }

  /// Get related genres
  static List<String> _getRelatedGenres(String genre) {
    switch (genre.toLowerCase()) {
      case 'rock':
        return ['Alternative', 'Punk', 'Metal', 'Indie', 'Grunge'];
      case 'pop':
        return ['Dance-pop', 'Synth-pop', 'Electropop', 'K-Pop', 'Latin Pop'];
      case 'hip hop':
      case 'rap':
        return ['Trap', 'Drill', 'Conscious', 'Alternative Hip Hop', 'R&B'];
      case 'electronic':
      case 'edm':
        return ['House', 'Techno', 'Trance', 'Dubstep', 'Ambient'];
      case 'jazz':
        return ['Blues', 'Funk', 'Soul', 'Fusion', 'Latin Jazz'];
      case 'classical':
        return ['Opera', 'Symphony', 'Chamber', 'Choral', 'Contemporary Classical'];
      case 'r&b':
      case 'soul':
        return ['Neo-soul', 'Contemporary R&B', 'Funk', 'Gospel', 'Hip Hop'];
      case 'country':
        return ['Bluegrass', 'Americana', 'Folk', 'Country Rock', 'Outlaw Country'];
      default:
        return [];
    }
  }

  /// Get genre characteristics
  static Map<String, dynamic> _getGenreCharacteristics(String genre) {
    // Return typical audio features for genre
    switch (genre.toLowerCase()) {
      case 'rock':
        return {'energy': 0.8, 'valence': 0.6, 'tempo': 120, 'loudness': -5};
      case 'pop':
        return {'energy': 0.7, 'valence': 0.7, 'tempo': 115, 'loudness': -4};
      case 'hip hop':
      case 'rap':
        return {'energy': 0.7, 'valence': 0.5, 'tempo': 90, 'loudness': -5};
      case 'electronic':
      case 'edm':
        return {'energy': 0.9, 'valence': 0.6, 'tempo': 128, 'loudness': -4};
      case 'jazz':
        return {'energy': 0.4, 'valence': 0.5, 'tempo': 100, 'loudness': -10};
      case 'classical':
        return {'energy': 0.3, 'valence': 0.4, 'tempo': 80, 'loudness': -15};
      case 'r&b':
      case 'soul':
        return {'energy': 0.5, 'valence': 0.6, 'tempo': 95, 'loudness': -7};
      case 'country':
        return {'energy': 0.6, 'valence': 0.6, 'tempo': 110, 'loudness': -6};
      default:
        return {'energy': 0.5, 'valence': 0.5, 'tempo': 100, 'loudness': -8};
    }
  }

  /// Get popular genres list
  static List<String> getPopularGenres() {
    return [
      'Pop',
      'Rock',
      'Hip Hop',
      'Electronic',
      'R&B',
      'Country',
      'Jazz',
      'Classical',
      'Latin',
      'Metal',
      'Indie',
      'K-Pop',
    ];
  }
}
