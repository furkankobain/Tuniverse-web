import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../core/constants/app_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EnhancedSpotifyService {
  static final Dio _dio = Dio();
  static String? _accessToken;
  static String? _refreshToken;
  static DateTime? _tokenExpiry;
  static bool _isConnected = false;
  static Map<String, dynamic>? _currentTrack;
  static Map<String, dynamic>? _userProfile;
  static bool _isPlaying = false;
  static int _currentPosition = 0;
  static int _trackDuration = 0;
  
  // Rate limiting
  static DateTime? _lastRequestTime;
  static int _requestCount = 0;
  static const int _maxRequestsPerSecond = 10;
  static final Map<String, DateTime> _retryAfter = {};
  
  // OAuth state for verification
  static String? _codeVerifier;
  static String? _state;

  // Spotify API Configuration
  static const String _clientId = AppConstants.spotifyClientId;
  static const String _clientSecret = AppConstants.spotifyClientSecret;
  static String get _redirectUri => kIsWeb ? AppConstants.spotifyRedirectUriWeb : AppConstants.spotifyRedirectUri;

  // Getters
  static bool get isConnected => _isConnected;
  static String? get accessToken => _accessToken;
  static Map<String, dynamic>? get currentTrack => _currentTrack;
  static Map<String, dynamic>? get userProfile => _userProfile;
  static bool get isPlaying => _isPlaying;
  static int get currentPosition => _currentPosition;
  static int get trackDuration => _trackDuration;
  static double get playbackProgress => _trackDuration > 0 ? _currentPosition / _trackDuration : 0.0;

  /// Initialize Spotify authentication with OAuth 2.0 PKCE flow
  static Future<bool> authenticate() async {
    try {
      // Use Authorization Code Flow with PKCE for mobile apps
      return await _authenticateViaWeb();
    } catch (e) {
      print('Authentication error: $e');
      return false;
    }
  }

  /// Enhanced web authentication with PKCE
  static Future<bool> _authenticateViaWeb() async {
    try {
      // Generate PKCE code verifier and challenge
      _codeVerifier = _generateCodeVerifier();
      final codeChallenge = _generateCodeChallenge(_codeVerifier!);
      _state = _generateRandomString(16);
      
      final authUrl = _buildAuthUrlWithPKCE(codeChallenge);
      final uri = Uri.parse(authUrl);

      // Try external browser first
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (launched) return true;
      }

      // Fallback: in-app WebView
      try {
        // Delay import-free approach: use navigation to a dedicated WebView page
        // Caller page (e.g., SpotifyConnectPage) should handle navigating to a WebView route if needed.
        // As a minimal fallback, attempt platform default launcher
        final launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
        return launched;
      } catch (_) {
        return false;
      }
    } catch (e) {
      print('Web auth error: $e');
      return false;
    }
  }

  /// Build authentication URL with PKCE
  static String _buildAuthUrlWithPKCE(String codeChallenge) {
    final scopes = AppConstants.spotifyScopes.join('%20');
    
    return '${AppConstants.authUrl}?'
        'response_type=code&'
        'client_id=$_clientId&'
        'scope=$scopes&'
        'redirect_uri=${Uri.encodeComponent(_redirectUri)}&'
        'state=$_state&'
        'code_challenge_method=S256&'
        'code_challenge=$codeChallenge';
  }

  /// Handle OAuth callback with authorization code
  static Future<bool> handleAuthCallback(String code, String state) async {
    try {
      // Verify state to prevent CSRF attacks
      if (state != _state) {
        print('State mismatch error');
        return false;
      }
      
      // Exchange authorization code for access token
      final response = await _dio.post(
        AppConstants.tokenUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
        data: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': _redirectUri,
          'client_id': _clientId,
          'code_verifier': _codeVerifier,
        },
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        _accessToken = data['access_token'];
        _refreshToken = data['refresh_token'];
        
        // Calculate token expiry time
        final expiresIn = data['expires_in'] as int;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
        
        _isConnected = true;
        
        // Save tokens
        await _saveTokens();
        await _saveConnectionState(true);
        
        // Fetch user profile
        await fetchUserProfile();
        
        return true;
      }
      
      return false;
    } catch (e) {
      print('Token exchange error: $e');
      return false;
    }
  }
  
  /// Generate PKCE code verifier
  static String _generateCodeVerifier() {
    const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(128, (_) => charset[random.nextInt(charset.length)]).join();
  }
  
  /// Generate PKCE code challenge
  static String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  /// Start monitoring playback state
  static Future<void> _startPlaybackMonitoring() async {
    // Monitor playback state every 2 seconds
    _monitorPlayback();
  }

  /// Monitor playback state
  static void _monitorPlayback() {
    Future.delayed(const Duration(seconds: 2), () async {
      if (_isConnected) {
        await _updatePlaybackState();
        _monitorPlayback(); // Continue monitoring
      }
    });
  }

  /// Update current playback state
  static Future<void> _updatePlaybackState() async {
    try {
      // final playerState = await SpotifySdk.getPlayerState(); // Temporarily disabled
      // Simulate player state for now
      // Mock values since PlayerState API is not fully available
      _isPlaying = true; // Mock value
      _currentPosition = 45000; // Mock value (45 seconds)
      _trackDuration = 180000; // Mock value (3 minutes)
      
      // Update current track info
      _currentTrack = await _getCurrentTrackInfo();
    } catch (e) {
      // Handle error silently
    }
  }

  /// Get detailed current track information
  static Future<Map<String, dynamic>?> _getCurrentTrackInfo() async {
    try {
      // For now, return enhanced mock data
      // In a real implementation, you'd fetch from Spotify Web API
      return {
        'id': 'mock_track_id_${DateTime.now().millisecondsSinceEpoch}',
        'name': 'Enhanced Spotify Track',
        'artist': 'Smart Artist',
        'album': 'Intelligent Album',
        'image_url': 'https://i.scdn.co/image/ab67616d0000b273bb54dde68cd23e2a268ae0f5',
        'duration_ms': _trackDuration,
        'is_playing': _isPlaying,
        'popularity': 85,
        'explicit': false,
        'preview_url': 'https://p.scdn.co/mp3-preview/sample.mp3',
        'external_urls': {
          'spotify': 'https://open.spotify.com/track/sample'
        },
        'features': {
          'danceability': 0.8,
          'energy': 0.7,
          'valence': 0.6,
          'acousticness': 0.3,
          'tempo': 120.0,
        }
      };
    } catch (e) {
      return null;
    }
  }

  /// Enhanced play/pause control
  static Future<void> togglePlayPause() async {
    try {
      if (!_isConnected) return;
      
      if (_isPlaying) {
        // await SpotifySdk.pause(); // Temporarily disabled
      } else {
        // await SpotifySdk.resume(); // Temporarily disabled
      }
      
      _isPlaying = !_isPlaying;
      await _updatePlaybackState();
    } catch (e) {
      // Handle error
    }
  }

  /// Enhanced skip to next track
  static Future<void> skipToNext() async {
    try {
      if (!_isConnected) return;
      
      // await SpotifySdk.skipNext(); // Temporarily disabled
      await Future.delayed(const Duration(milliseconds: 500));
      await _updatePlaybackState();
    } catch (e) {
      // Handle error
    }
  }

  /// Enhanced skip to previous track
  static Future<void> skipToPrevious() async {
    try {
      if (!_isConnected) return;
      
      // await SpotifySdk.skipPrevious(); // Temporarily disabled
      await Future.delayed(const Duration(milliseconds: 500));
      await _updatePlaybackState();
    } catch (e) {
      // Handle error
    }
  }

  /// Seek to position in track
  static Future<void> seekTo(int positionMs) async {
    try {
      if (!_isConnected) return;
      
      // await SpotifySdk.seekTo(positionMs); // API not available
      _currentPosition = positionMs;
    } catch (e) {
      // Handle error
    }
  }

  /// Set playback volume
  static Future<void> setVolume(double volume) async {
    try {
      if (!_isConnected) return;
      
      // Volume control might not be available in all SDK versions
      // This is a placeholder for future implementation
    } catch (e) {
      // Handle error
    }
  }

  /// Fetch user profile from Spotify
  static Future<Map<String, dynamic>?> fetchUserProfile() async {
    try {
      await _checkAndRefreshToken();
      
      final response = await _dio.get(
        '${AppConstants.baseUrl}/me',
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );
      
      if (response.statusCode == 200) {
        _userProfile = response.data;
        await _saveUserProfile();
        
        // Save user's country to Firestore for content localization
        final country = _userProfile?['country'] as String?;
        if (country != null) {
          try {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .update({
                'spotifyCountry': country,
                'updatedAt': FieldValue.serverTimestamp(),
              });
              print('✅ User country saved: $country');
            }
          } catch (e) {
            print('Error saving user country: $e');
          }
        }
        
        return _userProfile;
      }
      
      return null;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }
  
  /// Get user's playlists
  static Future<List<Map<String, dynamic>>> getUserPlaylists({int limit = 50}) async {
    try {
      await _checkAndRefreshToken();
      
      final response = await _dio.get(
        '${AppConstants.baseUrl}/me/playlists',
        queryParameters: {'limit': limit},
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );
      
      if (response.statusCode == 200) {
        final items = response.data['items'] as List;
        return items.cast<Map<String, dynamic>>();
      }
      
      return [];
    } catch (e) {
      print('Error fetching playlists: $e');
      return [];
    }
  }
  
  /// Get playlist tracks
  static Future<List<Map<String, dynamic>>> getPlaylistTracks(String playlistId) async {
    try {
      await _checkAndRefreshToken();
      
      final response = await _dio.get(
        '${AppConstants.baseUrl}/playlists/$playlistId/tracks',
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );
      
      if (response.statusCode == 200) {
        final items = response.data['items'] as List;
        return items.map((item) => item['track'] as Map<String, dynamic>).toList();
      }
      
      return [];
    } catch (e) {
      print('Error fetching playlist tracks: $e');
      return [];
    }
  }
  
  /// Get full playlist details including tracks
  static Future<Map<String, dynamic>?> getPlaylistDetails(String playlistId) async {
    try {
      await _checkAndRefreshToken();
      
      final response = await _dio.get(
        '${AppConstants.baseUrl}/playlists/$playlistId',
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );
      
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      
      return null;
    } catch (e) {
      print('Error fetching playlist details: $e');
      return null;
    }
  }
  
  /// Create a new playlist on Spotify
  static Future<String?> createPlaylistOnSpotify({
    required String name,
    String? description,
    bool isPublic = true,
  }) async {
    try {
      await _checkAndRefreshToken();
      
      // Get user profile if not already loaded
      if (_userProfile == null) {
        await fetchUserProfile();
      }
      
      if (_userProfile == null || _userProfile!['id'] == null) {
        print('Cannot create playlist: User profile not available');
        return null;
      }
      
      final userId = _userProfile!['id'];
      
      final response = await _dio.post(
        '${AppConstants.baseUrl}/users/$userId/playlists',
        data: {
          'name': name,
          'description': description ?? '',
          'public': isPublic,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $_accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );
      
      if (response.statusCode == 201) {
        return response.data['id'] as String?;
      }
      
      return null;
    } catch (e) {
      print('Error creating playlist on Spotify: $e');
      return null;
    }
  }
  
  /// Add tracks to a Spotify playlist
  static Future<bool> addTracksToSpotifyPlaylist(
    String playlistId,
    List<String> trackUris,
  ) async {
    try {
      await _checkAndRefreshToken();
      
      // Convert track IDs to URIs if needed
      final uris = trackUris.map((uri) {
        if (uri.startsWith('spotify:track:')) {
          return uri;
        } else {
          return 'spotify:track:$uri';
        }
      }).toList();
      
      final response = await _dio.post(
        '${AppConstants.baseUrl}/playlists/$playlistId/tracks',
        data: {
          'uris': uris,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $_accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );
      
      return response.statusCode == 201;
    } catch (e) {
      print('Error adding tracks to Spotify playlist: $e');
      return false;
    }
  }
  
  /// Remove tracks from a Spotify playlist
  static Future<bool> removeTracksFromSpotifyPlaylist(
    String playlistId,
    List<String> trackUris,
  ) async {
    try {
      await _checkAndRefreshToken();
      
      // Convert track IDs to URIs if needed
      final uris = trackUris.map((uri) {
        if (uri.startsWith('spotify:track:')) {
          return uri;
        } else {
          return 'spotify:track:$uri';
        }
      }).toList();
      
      final response = await _dio.delete(
        '${AppConstants.baseUrl}/playlists/$playlistId/tracks',
        data: {
          'tracks': uris.map((uri) => {'uri': uri}).toList(),
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $_accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error removing tracks from Spotify playlist: $e');
      return false;
    }
  }
  
  /// Update Spotify playlist metadata
  static Future<bool> updateSpotifyPlaylist({
    required String playlistId,
    String? name,
    String? description,
    bool? isPublic,
  }) async {
    try {
      await _checkAndRefreshToken();
      
      final Map<String, dynamic> data = {};
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (isPublic != null) data['public'] = isPublic;
      
      if (data.isEmpty) return true; // Nothing to update
      
      final response = await _dio.put(
        '${AppConstants.baseUrl}/playlists/$playlistId',
        data: data,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating Spotify playlist: $e');
      return false;
    }
  }

  /// Get global new release tracks (tracks from new albums)
  static Future<List<Map<String, dynamic>>> getGlobalNewReleaseTracks({
    int limit = 50,
    String? market,
  }) async {
    try {
      String? token = _accessToken;
      
      if (!_isConnected || token == null) {
        token = await _getClientCredentialsToken();
      } else {
        await _checkAndRefreshToken();
      }
      
      if (token != null) {
        // Get new release albums from specified market (default: US for global)
        final targetMarket = market ?? 'US';
        final albums = await getNewReleases(limit: 20, market: targetMarket);
        
        if (albums.isEmpty) return [];
        
        List<Map<String, dynamic>> allTracks = [];
        
        // Get tracks from each new album
        for (var album in albums.take(10)) { // Limit to 10 albums to avoid too many API calls
          try {
            final albumId = album['id'] as String?;
            if (albumId == null) continue;
            
            final response = await _dio.get(
              '${AppConstants.baseUrl}/albums/$albumId/tracks',
              queryParameters: {
                'market': targetMarket,
                'limit': 5, // Get first 5 tracks from each album
              },
              options: Options(
                headers: {'Authorization': 'Bearer $token'},
              ),
            );
            
            if (response.statusCode == 200 && response.data['items'] != null) {
              final tracks = response.data['items'] as List;
              // Add full album info to each track
              for (var track in tracks) {
                // Tracks from album endpoint don't have full album info
                // Add it from the parent album
                if (track is Map<String, dynamic>) {
                  track['album'] = album; // Use full album object with images
                }
              }
              allTracks.addAll(tracks.cast<Map<String, dynamic>>());
            }
          } catch (e) {
            print('Failed to fetch tracks for album: $e');
          }
          
          if (allTracks.length >= limit) break;
        }
        
        return allTracks.take(limit).toList();
      }
      
      return [];
    } catch (e) {
      print('Error fetching global new release tracks: $e');
      return [];
    }
  }

  /// Get global popular tracks (not user-specific)
  static Future<List<Map<String, dynamic>>> getGlobalPopularTracks({
    int limit = 20,
  }) async {
    try {
      String? token = _accessToken;
      
      if (!_isConnected || token == null) {
        token = await _getClientCredentialsToken();
      } else {
        await _checkAndRefreshToken();
      }
      
      if (token != null) {
        // Search for popular global artists' latest tracks
        final popularArtists = [
          'Taylor Swift', 'Drake', 'The Weeknd', 'Ed Sheeran', 'Dua Lipa',
          'Ariana Grande', 'Post Malone', 'Billie Eilish', 'Travis Scott',
          'Bruno Mars', 'Doja Cat', 'Harry Styles', 'Olivia Rodrigo',
        ];
        
        List<Map<String, dynamic>> allTracks = [];
        
        for (var artist in popularArtists.take(5)) { // Limit to avoid too many API calls
          try {
            final response = await _dio.get(
              '${AppConstants.baseUrl}/search',
              queryParameters: {
                'q': 'artist:$artist',
                'type': 'track',
                'limit': 3,
                'market': 'US',
              },
              options: Options(
                headers: {'Authorization': 'Bearer $token'},
              ),
            );
            
            if (response.statusCode == 200 && response.data['tracks']?['items'] != null) {
              final tracks = response.data['tracks']['items'] as List;
              allTracks.addAll(tracks.cast<Map<String, dynamic>>());
            }
          } catch (e) {
            print('Failed to fetch tracks for $artist: $e');
          }
        }
        
        if (allTracks.isNotEmpty) {
          // Sort by popularity
          allTracks.sort((a, b) => (b['popularity'] ?? 0).compareTo(a['popularity'] ?? 0));
          return allTracks.take(limit).toList();
        }
      }
      
      return [];
    } catch (e) {
      print('Error fetching global popular tracks: $e');
      return [];
    }
  }

  /// Get user's top tracks
  static Future<List<Map<String, dynamic>>> getTopTracks({
    String timeRange = 'medium_term',
    int limit = 20,
  }) async {
    try {
      await _checkAndRefreshToken();
      
      final response = await _dio.get(
        '${AppConstants.baseUrl}/me/top/tracks',
        queryParameters: {
          'time_range': timeRange,
          'limit': limit,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );
      
      if (response.statusCode == 200) {
        final items = response.data['items'] as List;
        return items.cast<Map<String, dynamic>>();
      }
      
      return [];
    } catch (e) {
      print('Error fetching top tracks: $e');
      return [];
    }
  }
  
  /// Get user's top artists
  static Future<List<Map<String, dynamic>>> getTopArtists({
    String timeRange = 'medium_term',
    int limit = 20,
  }) async {
    try {
      await _checkAndRefreshToken();
      
      final response = await _dio.get(
        '${AppConstants.baseUrl}/me/top/artists',
        queryParameters: {
          'time_range': timeRange,
          'limit': limit,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );
      
      if (response.statusCode == 200) {
        final items = response.data['items'] as List;
        return items.cast<Map<String, dynamic>>();
      }
      
      return [];
    } catch (e) {
      print('Error fetching top artists: $e');
      return [];
    }
  }

  /// Get user's recently played tracks
  static Future<List<Map<String, dynamic>>> getRecentlyPlayed({
    int limit = 20,
  }) async {
    try {
      await _checkAndRefreshToken();
      
      final response = await _dio.get(
        '${AppConstants.baseUrl}/me/player/recently-played',
        queryParameters: {'limit': limit},
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );
      
      if (response.statusCode == 200) {
        final items = response.data['items'] as List;
        return items.cast<Map<String, dynamic>>();
      }
      
      return [];
    } catch (e) {
      print('Error fetching recently played: $e');
      return [];
    }
  }

  /// Get track audio features
  static Future<Map<String, dynamic>?> getTrackFeatures(String trackId) async {
    try {
      if (!_isConnected || _accessToken == null) return null;

      // Mock audio features - replace with real API call
      return {
        'danceability': 0.8,
        'energy': 0.7,
        'valence': 0.6,
        'acousticness': 0.3,
        'instrumentalness': 0.1,
        'liveness': 0.2,
        'loudness': -5.0,
        'speechiness': 0.1,
        'tempo': 120.0,
        'key': 5,
        'mode': 1,
        'time_signature': 4,
      };
    } catch (e) {
      return null;
    }
  }

  /// Get track recommendations based on current track
  static Future<List<Map<String, dynamic>>> getTrackRecommendations({
    String? seedTrackId,
    String? seedArtistId,
    String? seedGenre,
    int limit = 20,
  }) async {
    try {
      await _checkAndRefreshToken();

      final Map<String, dynamic> queryParams = {'limit': limit};
      
      if (seedTrackId != null) queryParams['seed_tracks'] = seedTrackId;
      if (seedArtistId != null) queryParams['seed_artists'] = seedArtistId;
      if (seedGenre != null) queryParams['seed_genres'] = seedGenre;

      final response = await _dio.get(
        '${AppConstants.baseUrl}/recommendations',
        queryParameters: queryParams,
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );

      if (response.statusCode == 200) {
        final tracks = response.data['tracks'] as List;
        return tracks.cast<Map<String, dynamic>>();
      }

      return [];
    } catch (e) {
      print('Error fetching recommendations: $e');
      return [];
    }
  }

  /// Save track to user's library
  static Future<bool> saveTrack(String trackId) async {
    try {
      await _checkAndRefreshToken();
      
      final response = await _dio.put(
        '${AppConstants.baseUrl}/me/tracks',
        queryParameters: {'ids': trackId},
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error saving track: $e');
      return false;
    }
  }

  /// Remove track from user's library
  static Future<bool> removeTrack(String trackId) async {
    try {
      await _checkAndRefreshToken();
      
      final response = await _dio.delete(
        '${AppConstants.baseUrl}/me/tracks',
        queryParameters: {'ids': trackId},
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error removing track: $e');
      return false;
    }
  }
  
  /// Check if track is saved in user's library
  static Future<bool> checkSavedTrack(String trackId) async {
    try {
      await _checkAndRefreshToken();
      
      final response = await _dio.get(
        '${AppConstants.baseUrl}/me/tracks/contains',
        queryParameters: {'ids': trackId},
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );
      
      if (response.statusCode == 200 && response.data is List) {
        final results = response.data as List;
        return results.isNotEmpty && results[0] == true;
      }
      
      return false;
    } catch (e) {
      print('Error checking saved track: $e');
      return false;
    }
  }

  /// Get user's saved tracks
  static Future<List<Map<String, dynamic>>> getSavedTracks({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      await _checkAndRefreshToken();
      
      final response = await _dio.get(
        '${AppConstants.baseUrl}/me/tracks',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );
      
      if (response.statusCode == 200) {
        final items = response.data['items'] as List;
        return items.map((item) => item['track'] as Map<String, dynamic>).toList();
      }
      
      return [];
    } catch (e) {
      print('Error fetching saved tracks: $e');
      return [];
    }
  }
  
  /// Get user's saved albums
  static Future<List<Map<String, dynamic>>> getSavedAlbums({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      await _checkAndRefreshToken();
      
      final response = await _dio.get(
        '${AppConstants.baseUrl}/me/albums',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );
      
      if (response.statusCode == 200) {
        final items = response.data['items'] as List;
        return items.map((item) => item['album'] as Map<String, dynamic>).toList();
      }
      
      return [];
    } catch (e) {
      print('Error fetching saved albums: $e');
      return [];
    }
  }
  
  /// Search for tracks, albums, or artists
  static Future<Map<String, dynamic>> search({
    required String query,
    List<String> types = const ['track', 'album', 'artist'],
    int limit = 20,
  }) async {
    try {
      await _checkAndRefreshToken();
      
      final response = await _dio.get(
        '${AppConstants.baseUrl}/search',
        queryParameters: {
          'q': query,
          'type': types.join(','),
          'limit': limit,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );
      
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      
      return {};
    } catch (e) {
      print('Error searching: $e');
      return {};
    }
  }
  
  /// Search for tracks only
  static Future<List<Map<String, dynamic>>> searchTracks(String query, {int limit = 20}) async {
    try {
      // Try to use user token first, fallback to client credentials
      String? token = _accessToken;
      
      if (!_isConnected || token == null) {
        token = await _getClientCredentialsToken();
      } else {
        await _checkAndRefreshToken();
      }
      
      if (token != null) {
        final response = await _dio.get(
          '${AppConstants.baseUrl}/search',
          queryParameters: {
            'q': query,
            'type': 'track',
            'limit': limit,
          },
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
          ),
        );
        
        if (response.statusCode == 200 && response.data['tracks']?['items'] != null) {
          final items = response.data['tracks']['items'] as List;
          return items.cast<Map<String, dynamic>>();
        }
      }
      
      return [];
    } catch (e) {
      print('Error searching tracks: $e');
      return [];
    }
  }
  
  /// Search for artists only
  static Future<List<Map<String, dynamic>>> searchArtists(String query, {int limit = 20}) async {
    try {
      // Try to use user token first, fallback to client credentials
      String? token = _accessToken;
      
      if (!_isConnected || token == null) {
        token = await _getClientCredentialsToken();
      } else {
        await _checkAndRefreshToken();
      }
      
      if (token != null) {
        final response = await _dio.get(
          '${AppConstants.baseUrl}/search',
          queryParameters: {
            'q': query,
            'type': 'artist',
            'limit': limit,
          },
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
          ),
        );
        
        if (response.statusCode == 200 && response.data['artists']?['items'] != null) {
          final items = response.data['artists']['items'] as List;
          return items.cast<Map<String, dynamic>>();
        }
      }
      
      return [];
    } catch (e) {
      print('Error searching artists: $e');
      return [];
    }
  }
  
  /// Search for albums only
  static Future<List<Map<String, dynamic>>> searchAlbums(String query, {int limit = 20}) async {
    try {
      // Try to use user token first, fallback to client credentials
      String? token = _accessToken;
      
      if (!_isConnected || token == null) {
        token = await _getClientCredentialsToken();
      } else {
        await _checkAndRefreshToken();
      }
      
      if (token != null) {
        final response = await _dio.get(
          '${AppConstants.baseUrl}/search',
          queryParameters: {
            'q': query,
            'type': 'album',
            'limit': limit,
          },
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
          ),
        );
        
        if (response.statusCode == 200 && response.data['albums']?['items'] != null) {
          final items = response.data['albums']['items'] as List;
          return items.cast<Map<String, dynamic>>();
        }
      }
      
      return [];
    } catch (e) {
      print('Error searching albums: $e');
      return [];
    }
  }
  
  /// Get album details
  static Future<Map<String, dynamic>?> getAlbum(String albumId) async {
    try {
      await _checkAndRefreshToken();
      
      final response = await _dio.get(
        '${AppConstants.baseUrl}/albums/$albumId',
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );
      
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      
      return null;
    } catch (e) {
      print('Error fetching album: $e');
      return null;
    }
  }
  
  /// Get new releases
  static Future<List<Map<String, dynamic>>> getNewReleases({
    int limit = 20,
    int offset = 0,
    String? market,
  }) async {
    try {
      String? token = _accessToken;
      
      if (!_isConnected || token == null) {
        token = await _getClientCredentialsToken();
      } else {
        await _checkAndRefreshToken();
      }
      
      if (token != null) {
        await _checkRateLimit('new-releases');
        
        // Use US market by default to get global content
        // Only use TR market if explicitly requested
        final queryParams = {
          'limit': limit,
          'offset': offset,
          'market': market ?? 'US',
        };
        
        final response = await _dio.get(
          '${AppConstants.baseUrl}/browse/new-releases',
          queryParameters: queryParams,
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
          ),
        );
        
        if (response.statusCode == 200 && response.data['albums']?['items'] != null) {
          final items = response.data['albums']['items'] as List;
          return items.cast<Map<String, dynamic>>();
        }
      }
      
      return [];
    } catch (e) {
      // Handle DioException for rate limiting and token expiry
      if (e is DioError) {
        if (e.response?.statusCode == 429) {
          // Rate limited - extract retry-after header
          final retryAfter = e.response?.headers['retry-after']?.firstOrNull;
          if (retryAfter != null) {
            _retryAfter['new-releases'] = DateTime.now().add(Duration(seconds: int.parse(retryAfter)));
          }
        } else if (e.response?.statusCode == 401) {
          // Token expired, try to refresh
          try {
            await _refreshAccessToken();
            return getNewReleases(limit: limit, offset: offset, market: market);
          } catch (_) {}
        }
      }
      print('Error fetching new releases: $e');
      return [];
    }
  }

  /// Get featured playlists (requires user authentication)
  static Future<List<Map<String, dynamic>>> getFeaturedPlaylists({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      // Featured playlists require user authentication
      if (!_isConnected || _accessToken == null) {
        print('Featured playlists require Spotify login');
        return [];
      }
      
      await _checkAndRefreshToken();
      await _checkRateLimit('featured-playlists');
      
      final response = await _dio.get(
        '${AppConstants.baseUrl}/browse/featured-playlists',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );
      
      if (response.statusCode == 200 && response.data['playlists']?['items'] != null) {
        final items = response.data['playlists']['items'] as List;
        return items.cast<Map<String, dynamic>>();
      }
      
      return [];
    } catch (e) {
      // Handle DioError for rate limiting and token expiry
      if (e is DioError) {
        if (e.response?.statusCode == 429) {
          final retryAfter = e.response?.headers['retry-after']?.firstOrNull;
          if (retryAfter != null) {
            _retryAfter['featured-playlists'] = DateTime.now().add(Duration(seconds: int.parse(retryAfter)));
          }
        } else if (e.response?.statusCode == 401) {
          try {
            await _refreshAccessToken();
            return getFeaturedPlaylists(limit: limit, offset: offset);
          } catch (_) {}
        }
      }
      print('Error fetching featured playlists: $e');
      return [];
    }
  }

  /// Get browse categories
  static Future<List<Map<String, dynamic>>> getCategories({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      String? token = _accessToken;
      
      if (!_isConnected || token == null) {
        token = await _getClientCredentialsToken();
      } else {
        await _checkAndRefreshToken();
      }
      
      if (token != null) {
        final response = await _dio.get(
          '${AppConstants.baseUrl}/browse/categories',
          queryParameters: {
            'limit': limit,
            'offset': offset,
          },
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
          ),
        );
        
        if (response.statusCode == 200 && response.data['categories']?['items'] != null) {
          final items = response.data['categories']['items'] as List;
          return items.cast<Map<String, dynamic>>();
        }
      }
      
      return [];
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  /// Save tokens to local storage
  static Future<void> _saveTokens() async {
    final prefs = await SharedPreferences.getInstance();
    if (_accessToken != null) {
      await prefs.setString(AppConstants.accessTokenKey, _accessToken!);
    }
    if (_refreshToken != null) {
      await prefs.setString(AppConstants.refreshTokenKey, _refreshToken!);
    }
    if (_tokenExpiry != null) {
      await prefs.setString(AppConstants.tokenExpiryKey, _tokenExpiry!.toIso8601String());
    }
  }
  
  /// Load tokens from local storage
  static Future<void> _loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(AppConstants.accessTokenKey);
    _refreshToken = prefs.getString(AppConstants.refreshTokenKey);
    
    final expiryStr = prefs.getString(AppConstants.tokenExpiryKey);
    if (expiryStr != null) {
      _tokenExpiry = DateTime.parse(expiryStr);
    }
  }
  
  /// Save user profile to local storage
  static Future<void> _saveUserProfile() async {
    if (_userProfile != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userDataKey, jsonEncode(_userProfile!));
    }
  }
  
  /// Load user profile from local storage
  static Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileStr = prefs.getString(AppConstants.userDataKey);
    if (profileStr != null) {
      _userProfile = jsonDecode(profileStr) as Map<String, dynamic>;
    }
  }
  
  /// Rate limiting check
  static Future<void> _checkRateLimit(String endpoint) async {
    // Check if we're in retry period for this endpoint
    if (_retryAfter.containsKey(endpoint)) {
      final retryTime = _retryAfter[endpoint]!;
      if (DateTime.now().isBefore(retryTime)) {
        final waitSeconds = retryTime.difference(DateTime.now()).inSeconds;
        print('Rate limited for $endpoint, waiting $waitSeconds seconds');
        await Future.delayed(retryTime.difference(DateTime.now()));
        _retryAfter.remove(endpoint);
      }
    }
    
    // Simple rate limiting: max requests per second
    final now = DateTime.now();
    if (_lastRequestTime != null) {
      final diff = now.difference(_lastRequestTime!);
      if (diff.inMilliseconds < 1000) {
        _requestCount++;
        if (_requestCount >= _maxRequestsPerSecond) {
          await Future.delayed(Duration(milliseconds: 1000 - diff.inMilliseconds));
          _requestCount = 0;
        }
      } else {
        _requestCount = 1;
      }
    }
    _lastRequestTime = now;
  }
  
  /// Check if token is expired and refresh if needed
  static Future<void> _checkAndRefreshToken() async {
    if (!_isConnected || _accessToken == null) {
      throw Exception('Not connected to Spotify');
    }
    
    // Check if token is expired or about to expire (within 5 minutes)
    if (_tokenExpiry != null && DateTime.now().isAfter(_tokenExpiry!.subtract(const Duration(minutes: 5)))) {
      await _refreshAccessToken();
    }
  }
  
  /// Refresh access token using refresh token
  static Future<void> _refreshAccessToken() async {
    try {
      if (_refreshToken == null) {
        throw Exception('No refresh token available');
      }
      
      final response = await _dio.post(
        AppConstants.tokenUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
        data: {
          'grant_type': 'refresh_token',
          'refresh_token': _refreshToken,
          'client_id': _clientId,
        },
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        _accessToken = data['access_token'];
        
        // Update refresh token if provided
        if (data.containsKey('refresh_token')) {
          _refreshToken = data['refresh_token'];
        }
        
        // Calculate token expiry time
        final expiresIn = data['expires_in'] as int;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
        
        await _saveTokens();
      }
    } catch (e) {
      print('Token refresh error: $e');
      // If refresh fails, disconnect user
      await disconnect();
      throw Exception('Failed to refresh token');
    }
  }
  
  /// Save connection state
  static Future<void> _saveConnectionState(bool connected) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('spotify_connected', connected);
    if (connected) {
      await prefs.setString('spotify_connected_at', DateTime.now().toIso8601String());
    }
  }

  /// Load connection state
  static Future<void> loadConnectionState() async {
    final prefs = await SharedPreferences.getInstance();
    _isConnected = prefs.getBool('spotify_connected') ?? false;
    if (_isConnected) {
      await _loadTokens();
      await _loadUserProfile();
      await _startPlaybackMonitoring();
    }
  }

  /// Disconnect from Spotify
  static Future<void> disconnect() async {
    try {
      _isConnected = false;
      _accessToken = null;
      _refreshToken = null;
      _tokenExpiry = null;
      _currentTrack = null;
      _userProfile = null;
      _isPlaying = false;
      _currentPosition = 0;
      _trackDuration = 0;
      
      // Clear from local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.accessTokenKey);
      await prefs.remove(AppConstants.refreshTokenKey);
      await prefs.remove(AppConstants.tokenExpiryKey);
      await prefs.remove(AppConstants.userDataKey);
      await _saveConnectionState(false);
    } catch (e) {
      print('Disconnect error: $e');
    }
  }

  /// Generate random string for state parameter
  static String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  /// Get current track with enhanced info
  static Future<Map<String, dynamic>?> getCurrentTrack() async {
    await _updatePlaybackState();
    return _currentTrack;
  }

  /// Check if track is saved in user's library
  static Future<bool> isTrackSaved(String trackId) async {
    try {
      if (!_isConnected || _accessToken == null) return false;

      // Mock check - replace with real API call
      return Random().nextBool();
    } catch (e) {
      return false;
    }
  }

  /// Get track popularity score
  static Future<int?> getTrackPopularity(String trackId) async {
    try {
      if (!_isConnected || _accessToken == null) return null;

      // Mock popularity - replace with real API call
      return Random().nextInt(100) + 1;
    } catch (e) {
      return null;
    }
  }

  /// Get artist information
  static Future<Map<String, dynamic>?> getArtistInfo(String artistId) async {
    try {
      String? token = _accessToken;
      
      if (!_isConnected || token == null) {
        token = await _getClientCredentialsToken();
      } else {
        await _checkAndRefreshToken();
      }
      
      if (token != null) {
        final response = await _dio.get(
          '${AppConstants.baseUrl}/artists/$artistId',
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
          ),
        );
        
        if (response.statusCode == 200) {
          return response.data as Map<String, dynamic>;
        }
      }
      
      return null;
    } catch (e) {
      print('Error fetching artist info: $e');
      return null;
    }
  }

  /// Get artist top tracks
  static Future<List<Map<String, dynamic>>> getArtistTopTracks(
    String artistId, {
    String market = 'TR',
  }) async {
    try {
      String? token = _accessToken;
      
      if (!_isConnected || token == null) {
        token = await _getClientCredentialsToken();
      } else {
        await _checkAndRefreshToken();
      }
      
      if (token != null) {
        final response = await _dio.get(
          '${AppConstants.baseUrl}/artists/$artistId/top-tracks',
          queryParameters: {'market': market},
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
          ),
        );
        
        if (response.statusCode == 200 && response.data['tracks'] != null) {
          final tracks = response.data['tracks'] as List;
          return tracks.cast<Map<String, dynamic>>();
        }
      }
      
      return [];
    } catch (e) {
      print('Error fetching artist top tracks: $e');
      return [];
    }
  }

  /// Get artist albums
  static Future<List<Map<String, dynamic>>> getArtistAlbums(
    String artistId, {
    String? includeGroups,
    String market = 'TR',
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      String? token = _accessToken;
      
      if (!_isConnected || token == null) {
        token = await _getClientCredentialsToken();
      } else {
        await _checkAndRefreshToken();
      }
      
      if (token != null) {
        final queryParams = {
          'market': market,
          'limit': limit,
          'offset': offset,
        };
        
        if (includeGroups != null) {
          queryParams['include_groups'] = includeGroups;
        }
        
        final response = await _dio.get(
          '${AppConstants.baseUrl}/artists/$artistId/albums',
          queryParameters: queryParams,
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
          ),
        );
        
        if (response.statusCode == 200 && response.data['items'] != null) {
          final albums = response.data['items'] as List;
          return albums.cast<Map<String, dynamic>>();
        }
      }
      
      return [];
    } catch (e) {
      print('Error fetching artist albums: $e');
      return [];
    }
  }

  /// Get track details
  static Future<Map<String, dynamic>?> getTrackDetails(String trackId) async {
    try {
      await _checkAndRefreshToken();
      
      final response = await _dio.get(
        '${AppConstants.baseUrl}/tracks/$trackId',
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );
      
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      
      return null;
    } catch (e) {
      print('Error fetching track details: $e');
      return null;
    }
  }
  
  /// Get album information
  static Future<Map<String, dynamic>?> getAlbumInfo(String albumId) async {
    try {
      await _checkAndRefreshToken();
      
      final response = await _dio.get(
        '${AppConstants.baseUrl}/albums/$albumId',
        options: Options(
          headers: {'Authorization': 'Bearer $_accessToken'},
        ),
      );
      
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      
      return null;
    } catch (e) {
      print('Error fetching album info: $e');
      return null;
    }
  }
  
  /// Get Client Credentials token (no user authentication required)
  static Future<String?> _getClientCredentialsToken() async {
    try {
      final credentials = base64Encode(utf8.encode('$_clientId:$_clientSecret'));
      
      final response = await _dio.post(
        AppConstants.tokenUrl,
        options: Options(
          headers: {
            'Authorization': 'Basic $credentials',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
        data: {'grant_type': 'client_credentials'},
      );
      
      if (response.statusCode == 200) {
        return response.data['access_token'] as String?;
      }
      
      return null;
    } catch (e) {
      print('Error getting client credentials token: $e');
      return null;
    }
  }

  /// Get Turkey's top tracks from Spotify charts
  static Future<List<Map<String, dynamic>>> getTurkeyTopTracks({
    int limit = 50,
  }) async {
    print('\n=== Getting Turkey Top Tracks ===');
    print('Limit: $limit');
    
    try {
      // Try to get client credentials token
      String? token = await _getClientCredentialsToken();
      
      if (token != null) {
        print('Token obtained successfully');
        
        // Use search API with popular Turkish artists to get trending tracks
        final popularArtists = [
          'Tarkan', 'Ezhel', 'Mabel Matiz', 'Semicenk', 'Murda',
          'Melek Mosso', 'Hadise', 'Mustafa Sandal', 'Aleyna Tilki'
        ];
        
        List<Map<String, dynamic>> allTracks = [];
        
        for (var artist in popularArtists) {
          try {
            final response = await _dio.get(
              '${AppConstants.baseUrl}/search',
              queryParameters: {
                'q': 'artist:$artist',
                'type': 'track',
                'market': 'TR',
                'limit': 5,
              },
              options: Options(
                headers: {'Authorization': 'Bearer $token'},
              ),
            );
            
            if (response.statusCode == 200 && response.data['tracks']?['items'] != null) {
              final tracks = response.data['tracks']['items'] as List;
              allTracks.addAll(tracks.cast<Map<String, dynamic>>());
            }
          } catch (e) {
            print('Failed to fetch tracks for $artist: $e');
          }
        }
        
        if (allTracks.isNotEmpty) {
          // Sort by popularity and take top tracks
          allTracks.sort((a, b) => (b['popularity'] ?? 0).compareTo(a['popularity'] ?? 0));
          final topTracks = allTracks.take(limit).toList();
          print('Successfully fetched ${topTracks.length} tracks from Spotify search');
          return topTracks;
        }
      } else {
        print('Failed to get token, using mock data');
      }
    } catch (e) {
      print('Error fetching Turkey top tracks: $e');
    }
    
    print('Falling back to mock data');
    return _getMockTurkeyTopTracks(limit);
    
    /* Uncomment when Spotify API is ready:
    try {
      String? token = _accessToken;
      
      if (!_isConnected || token == null) {
        token = await _getClientCredentialsToken();
      } else {
        await _checkAndRefreshToken();
      }
      
      if (token != null) {
        final response = await _dio.get(
          '${AppConstants.baseUrl}/playlists/37i9dQZEVXbMDoHDwVN2tF/tracks',
          queryParameters: {'limit': limit},
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
          ),
        );
        
        if (response.statusCode == 200) {
          final items = response.data['items'] as List;
          return items
              .where((item) => item['track'] != null)
              .map((item) => item['track'] as Map<String, dynamic>)
              .toList();
        }
      }
      
      return _getMockTurkeyTopTracks(limit);
    } catch (e) {
      print('Error fetching Turkey top tracks: $e');
      return _getMockTurkeyTopTracks(limit);
    }
    */
  }
  
  /// Get Turkey's top albums
  static Future<List<Map<String, dynamic>>> getTurkeyTopAlbums({
    int limit = 50,
  }) async {
    print('\n=== Getting Turkey Top Albums ===');
    print('Limit: $limit');
    
    try {
      // Try to get client credentials token
      String? token = await _getClientCredentialsToken();
      
      if (token != null) {
        print('Token obtained successfully');
        
        // Search for albums by popular Turkish artists
        final popularArtists = [
          'Tarkan', 'Ezhel', 'Mabel Matiz', 'Semicenk', 'Murda',
          'Melek Mosso', 'Hadise', 'Teoman', 'Sezen Aksu', 'Mustafa Sandal'
        ];
        
        List<Map<String, dynamic>> allAlbums = [];
        
        for (var artist in popularArtists) {
          try {
            final response = await _dio.get(
              '${AppConstants.baseUrl}/search',
              queryParameters: {
                'q': 'artist:$artist',
                'type': 'album',
                'market': 'TR',
                'limit': 5,
              },
              options: Options(
                headers: {'Authorization': 'Bearer $token'},
              ),
            );
            
            if (response.statusCode == 200 && response.data['albums']?['items'] != null) {
              final albums = response.data['albums']['items'] as List;
              allAlbums.addAll(albums.cast<Map<String, dynamic>>());
            }
          } catch (e) {
            print('Failed to fetch albums for $artist: $e');
          }
          
          if (allAlbums.length >= limit) break;
        }
        
        if (allAlbums.isNotEmpty) {
          // Remove duplicates and sort by release date
          final uniqueAlbums = <String, Map<String, dynamic>>{};
          for (var album in allAlbums) {
            final id = album['id'] as String?;
            if (id != null && !uniqueAlbums.containsKey(id)) {
              uniqueAlbums[id] = album;
            }
          }
          
          final result = uniqueAlbums.values.toList();
          result.sort((a, b) {
            final dateA = a['release_date'] as String? ?? '2000-01-01';
            final dateB = b['release_date'] as String? ?? '2000-01-01';
            return dateB.compareTo(dateA); // Newest first
          });
          
          print('Successfully fetched ${result.length} Turkish albums from Spotify search');
          return result.take(limit).toList();
        }
      } else {
        print('Failed to get token, using mock data');
      }
    } catch (e) {
      print('Error fetching Turkey top albums: $e');
    }
    
    print('Falling back to mock data');
    return _getMockTurkeyTopAlbums(limit);
  }
  
  /// Get Global top albums
  static Future<List<Map<String, dynamic>>> getGlobalTopAlbums({
    int limit = 50,
  }) async {
    print('\n=== Getting Global Top Albums ===');
    print('Limit: $limit');
    
    try {
      // Try to get client credentials token
      String? token = await _getClientCredentialsToken();
      
      if (token != null) {
        print('Token obtained successfully');
        
        // Get new releases globally - use US market for better variety
        final response = await _dio.get(
          '${AppConstants.baseUrl}/browse/new-releases',
          queryParameters: {
            'country': 'US',  // Use US market for global content
            'limit': limit,
          },
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
          ),
        );
        
        if (response.statusCode == 200) {
          print('Successfully fetched ${response.data['albums']['items'].length} global albums from Spotify');
          final items = response.data['albums']['items'] as List;
          return items.cast<Map<String, dynamic>>();
        }
      } else {
        print('Failed to get token, using mock data');
      }
    } catch (e) {
      print('Error fetching global top albums: $e');
    }
    
    print('Falling back to mock data');
    return _getMockGlobalTopAlbums(limit);
  }
  
  /// Mock Turkey top tracks
  static List<Map<String, dynamic>> _getMockTurkeyTopTracks(int limit) {
    final mockTracks = [
      {'name': 'Şımarık', 'artist': 'Tarkan', 'album': 'Tarkan', 'duration': 241000, 'cover': 'https://i.scdn.co/image/ab67616d0000b273e5c6b33c1f7c8b97f5a75e43'},
      {'name': 'Gel Ey Seher', 'artist': 'Mabel Matiz', 'album': 'Gel Ey Seher', 'duration': 234000, 'cover': 'https://i.scdn.co/image/ab67616d0000b273a4c8e6b2f7a9b0d5e8c4a2f1'},
      {'name': 'Paramparça', 'artist': 'Teoman', 'album': 'Ruhçu Bir Kadın', 'duration': 256000, 'cover': 'https://i.scdn.co/image/ab67616d0000b2736c8e3b5f1d8a7e9c4b2a5f3e'},
      {'name': 'Aşk', 'artist': 'Sertab Erener', 'album': 'Aşk', 'duration': 245000, 'cover': 'https://i.scdn.co/image/ab67616d0000b2738d7e5c4a3b9f2e1d6c5a8f4b'},
      {'name': 'Nerdesin', 'artist': 'Ezhel', 'album': 'Müzmin', 'duration': 189000, 'cover': 'https://i.scdn.co/image/ab67616d0000b2739e6d4b2a5f8c3e1d7a6b5c4f'},
      {'name': 'Islak Islak', 'artist': 'Barış Manço', 'album': 'Sakla Samanı', 'duration': 267000, 'cover': 'https://i.scdn.co/image/ab67616d0000b273b5c7d3e2a9f4b1e8c6d5a7f2'},
      {'name': 'Sütün Eksi', 'artist': 'Hadise', 'album': 'Aşk Kaç Beden Giyer', 'duration': 223000, 'cover': 'https://i.scdn.co/image/ab67616d0000b273c6e8d5a4b2f9e1d7c5a8b4f3'},
      {'name': 'Yaşamak Bu Değil', 'artist': 'Sezen Aksu', 'album': 'Üstüme Yıkılsa Dünya', 'duration': 298000, 'cover': 'https://i.scdn.co/image/ab67616d0000b273d7f5c8e3a4b2f1e9d6c5a8b7'},
      {'name': 'Gidin Pulu Pulu', 'artist': 'Mustafa Sandal', 'album': 'Akışına Bırak', 'duration': 211000, 'cover': 'https://i.scdn.co/image/ab67616d0000b273e8c5d7a4b3f2e1d8c6a9b5f4'},
      {'name': 'Çok Çok', 'artist': 'Kenan Doğulu', 'album': 'Çok Çok', 'duration': 234000, 'cover': 'https://i.scdn.co/image/ab67616d0000b273f9d6c8a5b4e3f2d9c7a8b6e5'},
      {'name': 'Papatya', 'artist': 'Kıraç', 'album': 'Toprak', 'duration': 276000, 'cover': 'https://i.scdn.co/image/ab67616d0000b273a7e9d5c6b3f4e2d8c5a9b7f6'},
      {'name': 'Hop De', 'artist': 'Edis', 'album': 'Hop De', 'duration': 198000, 'cover': 'https://i.scdn.co/image/ab67616d0000b273b8f7e6d5a4c3f1e9d6c8a5b4'},
      {'name': 'Yürekten', 'artist': 'Aleyna Tilki', 'album': 'Yürekten', 'duration': 187000, 'cover': 'https://i.scdn.co/image/ab67616d0000b273c9e8f7d6a5b4e3f2d7c9a6b5'},
      {'name': 'Bela', 'artist': 'Melek Mosso', 'album': 'Düşler', 'duration': 245000, 'cover': 'https://i.scdn.co/image/ab67616d0000b273daf9e8c7b6a5f4e3d8c7a9b6'},
      {'name': 'Deliler', 'artist': 'Semicenk', 'album': 'Deliler', 'duration': 234000, 'cover': 'https://i.scdn.co/image/ab67616d0000b273ebf8d9c6a7b5e4f2d9c8a7b5'},
    ];
    
    return List.generate(limit.clamp(0, 50), (index) {
      final trackData = mockTracks[index % mockTracks.length];
      return {
        'id': 'mock_tr_track_$index',
        'name': trackData['name'],
        'artists': [{'name': trackData['artist']}],
        'album': {
          'name': trackData['album'],
          'images': [{'url': trackData['cover']}],
        },
        'duration_ms': trackData['duration'],
        'popularity': 100 - index,
      };
    });
  }
  
  /// Mock Turkey top albums
  static List<Map<String, dynamic>> _getMockTurkeyTopAlbums(int limit) {
    final mockAlbums = [
      {'name': 'Müzmin', 'artist': 'Ezhel', 'tracks': 12, 'year': '2024-01-15', 'cover': 'https://i.scdn.co/image/ab67616d0000b2739e6d4b2a5f8c3e1d7a6b5c4f'},
      {'name': 'Gel Ey Seher', 'artist': 'Mabel Matiz', 'tracks': 10, 'year': '2024-02-20', 'cover': 'https://i.scdn.co/image/ab67616d0000b273a4c8e6b2f7a9b0d5e8c4a2f1'},
      {'name': 'Toprak', 'artist': 'Kıraç', 'tracks': 14, 'year': '2023-12-08', 'cover': 'https://i.scdn.co/image/ab67616d0000b273a7e9d5c6b3f4e2d8c5a9b7f6'},
      {'name': 'Aşk Kaç Beden Giyer', 'artist': 'Hadise', 'tracks': 11, 'year': '2023-11-17', 'cover': 'https://i.scdn.co/image/ab67616d0000b273c6e8d5a4b2f9e1d7c5a8b4f3'},
      {'name': 'Düşler', 'artist': 'Melek Mosso', 'tracks': 13, 'year': '2024-03-22', 'cover': 'https://i.scdn.co/image/ab67616d0000b273daf9e8c7b6a5f4e3d8c7a9b6'},
      {'name': 'Akışına Bırak', 'artist': 'Mustafa Sandal', 'tracks': 10, 'year': '2023-10-05', 'cover': 'https://i.scdn.co/image/ab67616d0000b273e8c5d7a4b3f2e1d8c6a9b5f4'},
      {'name': 'Üstüme Yıkılsa Dünya', 'artist': 'Sezen Aksu', 'tracks': 12, 'year': '2024-01-30', 'cover': 'https://i.scdn.co/image/ab67616d0000b273d7f5c8e3a4b2f1e9d6c5a8b7'},
      {'name': 'Ruhçu Bir Kadın', 'artist': 'Teoman', 'tracks': 11, 'year': '2023-09-14', 'cover': 'https://i.scdn.co/image/ab67616d0000b2736c8e3b5f1d8a7e9c4b2a5f3e'},
      {'name': 'Aşk', 'artist': 'Sertab Erener', 'tracks': 10, 'year': '2024-02-08', 'cover': 'https://i.scdn.co/image/ab67616d0000b2738d7e5c4a3b9f2e1d6c5a8f4b'},
      {'name': 'Tarkan', 'artist': 'Tarkan', 'tracks': 13, 'year': '2023-08-25', 'cover': 'https://i.scdn.co/image/ab67616d0000b273e5c6b33c1f7c8b97f5a75e43'},
      {'name': 'Deliler', 'artist': 'Semicenk', 'tracks': 9, 'year': '2024-04-11', 'cover': 'https://i.scdn.co/image/ab67616d0000b273ebf8d9c6a7b5e4f2d9c8a7b5'},
      {'name': 'Yürekten', 'artist': 'Aleyna Tilki', 'tracks': 8, 'year': '2023-12-20', 'cover': 'https://i.scdn.co/image/ab67616d0000b273c9e8f7d6a5b4e3f2d7c9a6b5'},
      {'name': 'Çok Çok', 'artist': 'Kenan Doğulu', 'tracks': 12, 'year': '2024-01-05', 'cover': 'https://i.scdn.co/image/ab67616d0000b273f9d6c8a5b4e3f2d9c7a8b6e5'},
      {'name': 'Hop De', 'artist': 'Edis', 'tracks': 10, 'year': '2023-11-30', 'cover': 'https://i.scdn.co/image/ab67616d0000b273b8f7e6d5a4c3f1e9d6c8a5b4'},
      {'name': 'Sakla Samanı', 'artist': 'Barış Manço', 'tracks': 14, 'year': '2023-10-18', 'cover': 'https://i.scdn.co/image/ab67616d0000b273b5c7d3e2a9f4b1e8c6d5a7f2'},
    ];
    
    return List.generate(limit.clamp(0, 50), (index) {
      final albumData = mockAlbums[index % mockAlbums.length];
      return {
        'id': 'mock_tr_album_$index',
        'name': albumData['name'],
        'artists': [{'name': albumData['artist']}],
        'images': [{'url': albumData['cover']}],
        'total_tracks': albumData['tracks'],
        'release_date': albumData['year'],
      };
    });
  }
  
  /// Mock Global top albums
  static List<Map<String, dynamic>> _getMockGlobalTopAlbums(int limit) {
    final mockAlbums = [
      {'name': 'Midnights', 'artist': 'Taylor Swift', 'tracks': 13, 'year': '2023-10-21', 'cover': 'https://i.scdn.co/image/ab67616d0000b2730b0c634f7e7e7e7e7e7e7e7e'},
      {'name': 'SOS', 'artist': 'SZA', 'tracks': 23, 'year': '2022-12-09', 'cover': 'https://i.scdn.co/image/ab67616d0000b2730b0c634f7e7e7e7e7e7e7e7e'},
      {'name': 'Un Verano Sin Ti', 'artist': 'Bad Bunny', 'tracks': 23, 'year': '2022-05-06', 'cover': 'https://i.scdn.co/image/ab67616d0000b2730b0c634f7e7e7e7e7e7e7e7e'},
      {'name': 'The Car', 'artist': 'Arctic Monkeys', 'tracks': 10, 'year': '2022-10-21', 'cover': 'https://i.scdn.co/image/ab67616d0000b2730b0c634f7e7e7e7e7e7e7e7e'},
      {'name': 'Renaissance', 'artist': 'Beyoncé', 'tracks': 16, 'year': '2022-07-29', 'cover': 'https://i.scdn.co/image/ab67616d0000b2730b0c634f7e7e7e7e7e7e7e7e'},
      {'name': 'Harry\'s House', 'artist': 'Harry Styles', 'tracks': 13, 'year': '2022-05-20', 'cover': 'https://i.scdn.co/image/ab67616d0000b2730b0c634f7e7e7e7e7e7e7e7e'},
      {'name': 'Starboy', 'artist': 'The Weeknd', 'tracks': 18, 'year': '2016-11-25', 'cover': 'https://i.scdn.co/image/ab67616d0000b2730b0c634f7e7e7e7e7e7e7e7e'},
      {'name': 'DAMN.', 'artist': 'Kendrick Lamar', 'tracks': 14, 'year': '2017-04-14', 'cover': 'https://i.scdn.co/image/ab67616d0000b2730b0c634f7e7e7e7e7e7e7e7e'},
      {'name': 'After Hours', 'artist': 'The Weeknd', 'tracks': 14, 'year': '2020-03-20', 'cover': 'https://i.scdn.co/image/ab67616d0000b2730b0c634f7e7e7e7e7e7e7e7e'},
      {'name': 'Divide', 'artist': 'Ed Sheeran', 'tracks': 16, 'year': '2017-03-03', 'cover': 'https://i.scdn.co/image/ab67616d0000b2730b0c634f7e7e7e7e7e7e7e7e'},
      {'name': '30', 'artist': 'Adele', 'tracks': 12, 'year': '2021-11-19', 'cover': 'https://i.scdn.co/image/ab67616d0000b2730b0c634f7e7e7e7e7e7e7e7e'},
      {'name': 'Sour', 'artist': 'Olivia Rodrigo', 'tracks': 11, 'year': '2021-05-21', 'cover': 'https://i.scdn.co/image/ab67616d0000b2730b0c634f7e7e7e7e7e7e7e7e'},
      {'name': 'Positions', 'artist': 'Ariana Grande', 'tracks': 14, 'year': '2020-10-30', 'cover': 'https://i.scdn.co/image/ab67616d0000b2730b0c634f7e7e7e7e7e7e7e7e'},
      {'name': 'Planet Her', 'artist': 'Doja Cat', 'tracks': 14, 'year': '2021-06-25', 'cover': 'https://i.scdn.co/image/ab67616d0000b2730b0c634f7e7e7e7e7e7e7e7e'},
      {'name': 'folklore', 'artist': 'Taylor Swift', 'tracks': 16, 'year': '2020-07-24', 'cover': 'https://i.scdn.co/image/ab67616d0000b2730b0c634f7e7e7e7e7e7e7e7e'},
    ];
    
    return List.generate(limit.clamp(0, 50), (index) {
      final albumData = mockAlbums[index % mockAlbums.length];
      return {
        'id': 'mock_global_album_$index',
        'name': albumData['name'],
        'artists': [{'name': albumData['artist']}],
        'images': [{'url': albumData['cover']}],
        'total_tracks': albumData['tracks'],
        'release_date': albumData['year'],
      };
    });
  }
}
