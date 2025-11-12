import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'enhanced_spotify_service.dart';
import 'rating_cache_service.dart';

class PopularTracksSeedService {
  static const String _seedKey = 'popular_tracks_seeded';
  static const String _lastSeedTimeKey = 'last_seed_time';
  static const Duration _reseedInterval = Duration(days: 7);

  // Popüler şarkıları Spotify'dan çek ve Firestore'a kaydet
  static Future<void> seedPopularTracks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Son seed zamanını kontrol et
      final lastSeedTime = prefs.getInt(_lastSeedTimeKey);
      if (lastSeedTime != null) {
        final lastSeed = DateTime.fromMillisecondsSinceEpoch(lastSeedTime);
        if (DateTime.now().difference(lastSeed) < _reseedInterval) {
          print('Popüler şarkılar yakın zamanda güncellendi, tekrar gerek yok.');
          return;
        }
      }

      print('Popüler şarkılar çekiliyor...');

      // Spotify'dan popüler playlistler al
      final popularPlaylists = await _getPopularPlaylists();
      
      final List<Map<String, dynamic>> allTracks = [];
      
      // Her playlist'ten şarkıları topla
      for (final playlistId in popularPlaylists) {
        final tracks = await _getPlaylistTracks(playlistId);
        allTracks.addAll(tracks);
      }

      // Duplicate'leri temizle (track ID'ye göre)
      final uniqueTracks = <String, Map<String, dynamic>>{};
      for (final track in allTracks) {
        final trackId = track['id'] as String?;
        if (trackId != null && !uniqueTracks.containsKey(trackId)) {
          uniqueTracks[trackId] = track;
        }
      }

      print('${uniqueTracks.length} unique popüler şarkı bulundu');

      // Firestore'a kaydet
      final firestore = FirebaseFirestore.instance;
      var batch = firestore.batch();
      int batchCount = 0;

      for (final entry in uniqueTracks.entries) {
        final trackId = entry.key;
        final track = entry.value;

        final trackRef = firestore.collection('popular_tracks').doc(trackId);
        
        batch.set(trackRef, {
          'trackId': trackId,
          'name': track['name'],
          'artists': (track['artists'] as List?)
              ?.map((a) => a['name'])
              .toList() ?? [],
          'album': track['album']?['name'],
          'albumCover': (track['album']?['images'] as List?)?.isNotEmpty == true
              ? track['album']['images'][0]['url']
              : null,
          'popularity': track['popularity'] ?? 0,
          'previewUrl': track['preview_url'],
          'spotifyUrl': track['external_urls']?['spotify'],
          'addedAt': FieldValue.serverTimestamp(),
        });

        batchCount++;

        // Firestore batch limiti 500, her 400'de commit et
        if (batchCount >= 400) {
          await batch.commit();
          batch = firestore.batch();
          batchCount = 0;
          print('400 şarkı kaydedildi...');
        }
      }

      // Kalan şarkıları commit et
      if (batchCount > 0) {
        await batch.commit();
      }

      // Seed başarılı olarak işaretle
      await prefs.setBool(_seedKey, true);
      await prefs.setInt(_lastSeedTimeKey, DateTime.now().millisecondsSinceEpoch);

      print('Popüler şarkılar başarıyla kaydedildi!');

      // Cache'i temizle, yeni veriler için
      await RatingCacheService.cleanExpiredCache();

    } catch (e) {
      print('Popüler şarkılar seed hatası: $e');
    }
  }

  // Spotify'dan popüler playlist ID'leri al
  static Future<List<String>> _getPopularPlaylists() async {
    // Türkiye ve global popüler playlist'ler
    return [
      '37i9dQZEVXbMDoHDwVN2tF', // Global Top 50
      '37i9dQZEVXbJiyhoAPEfMK', // Turkey Top 50
      '37i9dQZF1DXcBWIGoYBM5M', // Today's Top Hits
      '37i9dQZF1DX0XUsuxWHRQd', // RapCaviar
      '37i9dQZF1DX4dyzvuaRJ0n', // Mint
      '37i9dQZF1DXcF6B6QPhFDv', // Rock Classics
      '37i9dQZF1DX4SBhb3fqCJd', // Are & Be
    ];
  }

  // Playlist'ten şarkıları al
  static Future<List<Map<String, dynamic>>> _getPlaylistTracks(
    String playlistId,
  ) async {
    try {
      // Bu fonksiyon şimdilik çalışmayacak çünkü SpotifyAPI erişimi yok
      // Gerçek implementasyon için EnhancedSpotifyService'e method eklemeli
      print('Playlist çekme devre dışı: $playlistId');
      return [];
      
      /* Disabled for now
      // final response = await EnhancedSpotifyService().spotifyApi.playlists
      //     .getTracksByPlaylistId(playlistId)
      //     .getPage(50, 0);

      final tracks = <Map<String, dynamic>>[];
      
      for (final item in response.items ?? []) {
        final track = item.track;
        if (track != null) {
          tracks.add({
            'id': track.id,
            'name': track.name,
            'artists': track.artists?.map((a) => {'name': a.name}).toList() ?? [],
            'album': {
              'name': track.album?.name,
              'images': track.album?.images?.map((img) => {
                'url': img.url,
                'height': img.height,
                'width': img.width,
              }).toList() ?? [],
            },
            'popularity': track.popularity,
            'preview_url': track.previewUrl,
            'external_urls': {'spotify': track.externalUrls?['spotify']},
          });
        }
      }

      return tracks;
      */
    } catch (e) {
      print('Playlist tracks çekme hatası ($playlistId): $e');
      return [];
    }
  }

  // Seed yapılmış mı kontrol et
  static Future<bool> isSeeded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seedKey) ?? false;
  }

  // Seed'i sıfırla (test için)
  static Future<void> resetSeed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_seedKey);
    await prefs.remove(_lastSeedTimeKey);
  }

  // Firestore'dan popüler şarkıları çek
  static Future<List<Map<String, dynamic>>> getPopularTracksFromFirestore({
    int limit = 50,
  }) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('popular_tracks')
          .orderBy('popularity', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': data['trackId'],
          'name': data['name'],
          'artists': (data['artists'] as List?)?.map((name) => {'name': name}).toList() ?? [],
          'album': {
            'name': data['album'],
            'images': data['albumCover'] != null ? [{'url': data['albumCover']}] : [],
          },
          'popularity': data['popularity'],
          'preview_url': data['previewUrl'],
          'external_urls': {'spotify': data['spotifyUrl']},
        };
      }).toList();
    } catch (e) {
      print('Firestore popüler şarkılar çekme hatası: $e');
      return [];
    }
  }

  // İlk açılışta seed yap
  static Future<void> initializeSeed() async {
    if (!EnhancedSpotifyService.isConnected) {
      print('Spotify bağlantısı yok, seed yapılamıyor');
      return;
    }

    final seeded = await isSeeded();
    if (!seeded) {
      await seedPopularTracks();
    } else {
      // Eski seed ise yenile
      final prefs = await SharedPreferences.getInstance();
      final lastSeedTime = prefs.getInt(_lastSeedTimeKey);
      if (lastSeedTime != null) {
        final lastSeed = DateTime.fromMillisecondsSinceEpoch(lastSeedTime);
        if (DateTime.now().difference(lastSeed) >= _reseedInterval) {
          await seedPopularTracks();
        }
      }
    }
  }
}
