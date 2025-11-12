class AppConstants {
  static const String appName = 'Tuniverse';
  static const String appDescription = 'Müzik evreniniz';
  static const double defaultBorderRadius = 12.0;
  
  // Spotify API Constants
  static const String spotifyClientId = 'fa707acb3b8942009549def708444b94';
  static const String spotifyClientSecret = 'efecce9e795d4b3a85e413a3749df9d0';
  static const String spotifyRedirectUri = 'tuniverse://callback';
  static const List<String> spotifyScopes = [
    'user-read-recently-played',
    'user-top-read',
    'user-library-read',
    'user-follow-read',
    'user-read-currently-playing',
    'user-read-playback-state',
    'user-read-email',
    'user-read-private',
    'playlist-read-private',
    'playlist-read-collaborative',
    'playlist-modify-public',
    'playlist-modify-private',
  ];
  
  // API Endpoints
  static const String baseUrl = 'https://api.spotify.com/v1';
  static const String authUrl = 'https://accounts.spotify.com/authorize';
  static const String tokenUrl = 'https://accounts.spotify.com/api/token';
  
  // Local Storage Keys
  static const String accessTokenKey = 'spotify_access_token';
  static const String refreshTokenKey = 'spotify_refresh_token';
  static const String tokenExpiryKey = 'token_expiry';
  static const String userDataKey = 'user_data';
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  
  // Rating Constants
  static const int maxRating = 5;
  static const int minRating = 0;
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;
}
