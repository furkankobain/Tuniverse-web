// import 'dart:convert'; // Unused import
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:spotify_sdk/spotify_sdk.dart';  // Temporarily disabled

import '../../core/constants/app_constants.dart';

class SpotifyService {
  static final Dio _dio = Dio();
  static String? _accessToken;
  static String? _refreshToken;
  static DateTime? _tokenExpiry;
  static bool _isConnected = false;

  // Spotify API Models
  static const String _clientId = AppConstants.spotifyClientId;
  static const String _clientSecret = AppConstants.spotifyClientSecret;
  static const String _redirectUri = AppConstants.spotifyRedirectUri;

  // Getters
  static bool get isConnected => _isConnected;
  static String? get accessToken => _accessToken;

  /// Initialize Spotify authentication using Spotify SDK
  static Future<bool> authenticate() async {
    try {
      // Try to connect to Spotify
      // final result = await SpotifySdk.connectToSpotifyRemote( // Temporarily disabled
      //   clientId: _clientId,
      //   redirectUrl: _redirectUri,
      //   scope: AppConstants.spotifyScopes.join(','),
      // );
      
      // Simulate connection for now
      _isConnected = false; // Set to false since SDK is disabled
      await _saveConnectionState(false);
      return false; // Return false since SDK is disabled
    } catch (e) {
      // Fallback to web authentication
      return await _authenticateViaWeb();
    }
  }

  /// Fallback web authentication
  static Future<bool> _authenticateViaWeb() async {
    try {
      // Generate random state for security
      final state = _generateRandomString(16);
      
      // Build authorization URL
      final authUrl = Uri.parse(AppConstants.authUrl).replace(
        queryParameters: {
          'client_id': _clientId,
          'response_type': 'code',
          'redirect_uri': _redirectUri,
          'scope': AppConstants.spotifyScopes.join(' '),
          'state': state,
        },
      );

      // Launch browser for authentication
      if (await canLaunchUrl(authUrl)) {
        await launchUrl(authUrl, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Handle authorization callback
  static Future<bool> handleCallback(String callbackUrl) async {
    try {
      final uri = Uri.parse(callbackUrl);
      final code = uri.queryParameters['code'];
      // final state = uri.queryParameters['state']; // Unused variable
      final error = uri.queryParameters['error'];

      if (error != null) {
        // print( // Debug log removed'Spotify auth error: $error');
        return false;
      }

      if (code != null) {
        return await _exchangeCodeForToken(code);
      }
      return false;
    } catch (e) {
      // print( // Debug log removed'Callback handling error: $e');
      return false;
    }
  }

  /// Exchange authorization code for access token
  static Future<bool> _exchangeCodeForToken(String code) async {
    try {
      final response = await _dio.post(
        AppConstants.tokenUrl,
        data: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': _redirectUri,
          'client_id': _clientId,
          'client_secret': _clientSecret,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        _accessToken = data['access_token'];
        _refreshToken = data['refresh_token'];
        _tokenExpiry = DateTime.now().add(
          Duration(seconds: data['expires_in'] ?? 3600),
        );

        // Save tokens to local storage
        await _saveTokens();
        return true;
      }
      return false;
    } catch (e) {
      // print( // Debug log removed'Token exchange error: $e');
      return false;
    }
  }

  /// Get user's recently played tracks
  static Future<List<Map<String, dynamic>>> getRecentlyPlayed({int limit = 20}) async {
    try {
      await _ensureValidToken();
      
      final response = await _dio.get(
        '${AppConstants.baseUrl}/me/player/recently-played',
        queryParameters: {
          'limit': limit,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $_accessToken',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> items = response.data['items'] ?? [];
        return items.map((item) => {
          'id': item['track']['id'],
          'name': item['track']['name'],
          'artists': (item['track']['artists'] as List)
              .map((artist) => artist['name'])
              .join(', '),
          'album': item['track']['album']['name'],
          'album_image': item['track']['album']['images'].isNotEmpty
              ? item['track']['album']['images'][0]['url']
              : null,
          'played_at': item['played_at'],
          'duration_ms': item['track']['duration_ms'],
          'popularity': item['track']['popularity'],
        }).toList();
      }
      return [];
    } catch (e) {
      // print( // Debug log removed'Get recently played error: $e');
      return [];
    }
  }

  /// Get user's top tracks
  static Future<List<Map<String, dynamic>>> getTopTracks({
    String timeRange = 'medium_term',
    int limit = 20,
  }) async {
    try {
      await _ensureValidToken();
      
      final response = await _dio.get(
        '${AppConstants.baseUrl}/me/top/tracks',
        queryParameters: {
          'time_range': timeRange,
          'limit': limit,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $_accessToken',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> items = response.data['items'] ?? [];
        return items.map((track) => {
          'id': track['id'],
          'name': track['name'],
          'artists': (track['artists'] as List)
              .map((artist) => artist['name'])
              .join(', '),
          'album': track['album']['name'],
          'album_image': track['album']['images'].isNotEmpty
              ? track['album']['images'][0]['url']
              : null,
          'duration_ms': track['duration_ms'],
          'popularity': track['popularity'],
        }).toList();
      }
      return [];
    } catch (e) {
      // print( // Debug log removed'Get top tracks error: $e');
      return [];
    }
  }

  /// Get user's saved albums
  static Future<List<Map<String, dynamic>>> getSavedAlbums({int limit = 20}) async {
    try {
      await _ensureValidToken();
      
      final response = await _dio.get(
        '${AppConstants.baseUrl}/me/albums',
        queryParameters: {
          'limit': limit,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $_accessToken',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> items = response.data['items'] ?? [];
        return items.map((item) {
          final album = item['album'];
          return {
            'id': album['id'],
            'name': album['name'],
            'artists': (album['artists'] as List)
                .map((artist) => artist['name'])
                .join(', '),
            'album_image': album['images'].isNotEmpty
                ? album['images'][0]['url']
                : null,
            'release_date': album['release_date'],
            'total_tracks': album['total_tracks'],
            'popularity': album['popularity'],
          };
        }).toList();
      }
      return [];
    } catch (e) {
      // print( // Debug log removed'Get saved albums error: $e');
      return [];
    }
  }

  /// Get track details by ID
  static Future<Map<String, dynamic>?> getTrackDetails(String trackId) async {
    try {
      await _ensureValidToken();
      
      final response = await _dio.get(
        '${AppConstants.baseUrl}/tracks/$trackId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_accessToken',
          },
        ),
      );

      if (response.statusCode == 200) {
        final track = response.data;
        return {
          'id': track['id'],
          'name': track['name'],
          'artists': (track['artists'] as List)
              .map((artist) => artist['name'])
              .join(', '),
          'album': track['album']['name'],
          'album_image': track['album']['images'].isNotEmpty
              ? track['album']['images'][0]['url']
              : null,
          'duration_ms': track['duration_ms'],
          'popularity': track['popularity'],
          'preview_url': track['preview_url'],
        };
      }
      return null;
    } catch (e) {
      // print( // Debug log removed'Get track details error: $e');
      return null;
    }
  }

  /// Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    await _loadTokens();
    return _accessToken != null && _tokenExpiry != null && 
           DateTime.now().isBefore(_tokenExpiry!);
  }

  /// Logout from Spotify
  static Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _tokenExpiry = null;
    await _clearTokens();
  }

  /// Ensure access token is valid
  static Future<void> _ensureValidToken() async {
    await _loadTokens();
    
    if (_accessToken == null || 
        _tokenExpiry == null || 
        DateTime.now().isAfter(_tokenExpiry!)) {
      await _refreshAccessToken();
    }
  }

  /// Refresh access token using refresh token
  static Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null) return false;
    
    try {
      final response = await _dio.post(
        AppConstants.tokenUrl,
        data: {
          'grant_type': 'refresh_token',
          'refresh_token': _refreshToken,
          'client_id': _clientId,
          'client_secret': _clientSecret,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        _accessToken = data['access_token'];
        _tokenExpiry = DateTime.now().add(
          Duration(seconds: data['expires_in'] ?? 3600),
        );

        if (data['refresh_token'] != null) {
          _refreshToken = data['refresh_token'];
        }

        await _saveTokens();
        return true;
      }
      return false;
    } catch (e) {
      // print( // Debug log removed'Token refresh error: $e');
      return false;
    }
  }

  /// Save tokens to local storage
  static Future<void> _saveTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('spotify_access_token', _accessToken ?? '');
    await prefs.setString('spotify_refresh_token', _refreshToken ?? '');
    await prefs.setString('spotify_token_expiry', _tokenExpiry?.toIso8601String() ?? '');
  }

  /// Load tokens from local storage
  static Future<void> _loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('spotify_access_token');
    _refreshToken = prefs.getString('spotify_refresh_token');
    final expiryString = prefs.getString('spotify_token_expiry');
    _tokenExpiry = expiryString != null ? DateTime.parse(expiryString) : null;
  }

  /// Clear tokens from local storage
  static Future<void> _clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('spotify_access_token');
    await prefs.remove('spotify_refresh_token');
    await prefs.remove('spotify_token_expiry');
  }

  /// Save connection state to local storage
  static Future<void> _saveConnectionState(bool connected) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('spotify_connected', connected);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Load connection state from local storage
  static Future<void> loadConnectionState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isConnected = prefs.getBool('spotify_connected') ?? false;
    } catch (e) {
      _isConnected = false;
    }
  }

  /// Disconnect from Spotify
  static Future<void> disconnect() async {
    try {
      // await SpotifySdk.disconnect(); // Temporarily disabled
      _isConnected = false;
      _accessToken = null;
      _refreshToken = null;
      _tokenExpiry = null;
      await _saveConnectionState(false);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Get current playing track using Spotify SDK
  static Future<Map<String, dynamic>?> getCurrentTrack() async {
    try {
      if (!_isConnected) return null;
      
      // For now, return a mock track until we get the correct API
      return {
        'id': 'mock_track_id',
        'name': 'Spotify Bağlı',
        'artist': 'Müzik dinleniyor',
        'album': 'Canlı',
        'image_url': null,
        'duration_ms': 0,
        'is_playing': true,
      };
    } catch (e) {
      return null;
    }
  }

  /// Skip to next track
  static Future<bool> skipToNext() async {
    try {
      if (!_isConnected) return false;
      // await SpotifySdk.skipNext(); // Temporarily disabled
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Skip to previous track
  static Future<bool> skipToPrevious() async {
    try {
      if (!_isConnected) return false;
      // await SpotifySdk.skipPrevious(); // Temporarily disabled
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Toggle play/pause
  static Future<bool> togglePlayPause() async {
    try {
      if (!_isConnected) return false;
      // final state = await SpotifySdk.getPlayerState(); // Temporarily disabled
      // if (state != null) {
      //   if (state.isPaused) {
      //     await SpotifySdk.resume();
      //   } else {
      //     await SpotifySdk.pause();
      //   }
      //   return true;
      // }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Generate random string for state parameter
  static String _generateRandomString(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  // ========== PLAYLIST METHODS ==========

  /// Get user's playlists from Spotify
  static Future<List<Map<String, dynamic>>> getUserPlaylists({int limit = 50}) async {
    try {
      await _ensureValidToken();
      
      final response = await _dio.get(
        '${AppConstants.baseUrl}/me/playlists',
        queryParameters: {
          'limit': limit,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $_accessToken',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> items = response.data['items'] ?? [];
        return items.map((playlist) => {
          'id': playlist['id'],
          'name': playlist['name'],
          'description': playlist['description'] ?? '',
          'owner': playlist['owner']['display_name'] ?? '',
          'public': playlist['public'] ?? true,
          'collaborative': playlist['collaborative'] ?? false,
          'tracks_count': playlist['tracks']['total'] ?? 0,
          'images': playlist['images'] ?? [],
          'cover_image': (playlist['images'] as List).isNotEmpty
              ? playlist['images'][0]['url']
              : null,
        }).toList();
      }
      return [];
    } catch (e) {
      print('Get user playlists error: $e');
      return [];
    }
  }

  /// Get tracks from a Spotify playlist
  static Future<List<Map<String, dynamic>>> getPlaylistTracks(String playlistId) async {
    try {
      await _ensureValidToken();
      
      final response = await _dio.get(
        '${AppConstants.baseUrl}/playlists/$playlistId/tracks',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_accessToken',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> items = response.data['items'] ?? [];
        return items.map((item) {
          final track = item['track'];
          return {
            'id': track['id'],
            'name': track['name'],
            'artists': (track['artists'] as List)
                .map((artist) => artist['name'])
                .join(', '),
            'album': track['album']['name'],
            'album_image': track['album']['images'].isNotEmpty
                ? track['album']['images'][0]['url']
                : null,
            'duration_ms': track['duration_ms'],
            'popularity': track['popularity'],
            'added_at': item['added_at'],
          };
        }).toList();
      }
      return [];
    } catch (e) {
      print('Get playlist tracks error: $e');
      return [];
    }
  }

  /// Create a new playlist on Spotify
  static Future<String?> createPlaylistOnSpotify({
    required String name,
    String? description,
    bool isPublic = true,
  }) async {
    try {
      await _ensureValidToken();
      
      // First, get user ID
      final userResponse = await _dio.get(
        '${AppConstants.baseUrl}/me',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_accessToken',
          },
        ),
      );

      if (userResponse.statusCode != 200) return null;
      
      final userId = userResponse.data['id'];
      
      // Create playlist
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
        return response.data['id'];
      }
      return null;
    } catch (e) {
      print('Create playlist on Spotify error: $e');
      return null;
    }
  }

  /// Add tracks to a Spotify playlist
  static Future<bool> addTracksToSpotifyPlaylist(
    String playlistId,
    List<String> trackUris,
  ) async {
    try {
      await _ensureValidToken();
      
      final response = await _dio.post(
        '${AppConstants.baseUrl}/playlists/$playlistId/tracks',
        data: {
          'uris': trackUris,
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
      print('Add tracks to Spotify playlist error: $e');
      return false;
    }
  }

  /// Remove tracks from a Spotify playlist
  static Future<bool> removeTracksFromSpotifyPlaylist(
    String playlistId,
    List<String> trackUris,
  ) async {
    try {
      await _ensureValidToken();
      
      final response = await _dio.delete(
        '${AppConstants.baseUrl}/playlists/$playlistId/tracks',
        data: {
          'tracks': trackUris.map((uri) => {'uri': uri}).toList(),
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
      print('Remove tracks from Spotify playlist error: $e');
      return false;
    }
  }

  /// Update playlist details on Spotify
  static Future<bool> updateSpotifyPlaylist({
    required String playlistId,
    String? name,
    String? description,
    bool? isPublic,
  }) async {
    try {
      await _ensureValidToken();
      
      final Map<String, dynamic> data = {};
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (isPublic != null) data['public'] = isPublic;

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
      print('Update Spotify playlist error: $e');
      return false;
    }
  }
}
